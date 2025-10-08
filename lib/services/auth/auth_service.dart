import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class AuthService {
  // Backend URL options (try each one based on your platform):
  // Android Emulator: http://10.0.2.2:8080/api/auth
  // iOS Simulator/Web: http://localhost:8080/api/auth
  // Physical Device/Network: http://192.168.1.4:8080/api/auth
  static const String _baseUrl =
      'http://10.0.2.2:8080/api/auth'; // Secure storage instance for JWT tokens
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Storage keys
  static const String _tokenKey = 'jwt_token';
  static const String _refreshTokenKey = 'refresh_token';

  // Headers for HTTP requests
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Register a new user/family (connects to POST /api/auth/signup/new-family)
  /// This method is used by the NewFamilyPage (signUpNewFamily controller)
  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? gender,
  }) async {
    try {
      // Validate input parameters
      if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
        return {
          'success': false,
          'messages': {
            'main': 'Registration Failed',
            'details': 'All required fields must be filled',
            'suggestion': 'Please check your input and try again',
            'action': 'Fill in all required fields',
          },
          'errors': _validateFields(name, email, phone, password, gender, null),
        };
      }

      // Convert gender string to boolean as expected by Java backend
      bool genderBoolean = _convertGenderToBoolean(gender);

      // Prepare request body matching SignUpNewFamilyRequestDTO
      final Map<String, dynamic> requestBody = {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'password': password,
        'gender': genderBoolean,
      };

      debugPrint('🚀 Making API call to: $_baseUrl/signup/new-family');
      debugPrint('📤 Request body: ${json.encode(requestBody)}');

      // Make HTTP POST request to Java Spring Boot backend
      final response = await http
          .post(
            Uri.parse('$_baseUrl/signup/new-family'),
            headers: _headers,
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Parse successful response
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        final token = responseData['token'] as String?;

        if (token != null && token.isNotEmpty) {
          // Store JWT token for future requests
          await _storeToken(token);

          return {
            'success': true,
            'messages': {
              'main': 'Family Created Successfully!',
              'title': 'Welcome!',
              'welcome': 'Welcome to Kidic, ${name.split(' ').first}!',
            },
            'data': {
              'token': token,
              'name': name,
              'email': email,
              'phone': phone,
              'gender': gender,
              'is_family_creator': true,
              'profile_complete': true,
            },
          };
        } else {
          return {
            'success': false,
            'messages': {
              'main': 'Registration Failed',
              'details': 'Invalid response from server',
              'action': 'Please try again',
            },
          };
        }
      } else if (response.statusCode == 400) {
        // Handle validation errors from backend
        return _handleErrorResponse(response);
      } else {
        // Handle other HTTP errors
        return {
          'success': false,
          'messages': {
            'main': 'Registration Failed',
            'details': 'Server error (${response.statusCode})',
            'suggestion': 'Please try again later',
            'action': 'Check your internet connection and retry',
          },
        };
      }
    } catch (e) {
      debugPrint('❌ AuthService.registerUser error: $e');

      if (e.toString().contains('TimeoutException')) {
        return {
          'success': false,
          'messages': {
            'main': 'Connection Timeout',
            'details': 'The server took too long to respond',
            'suggestion': 'Check your internet connection',
            'action': 'Try again with a stable connection',
          },
        };
      }

      return {
        'success': false,
        'messages': {
          'main': 'Registration Failed',
          'details': 'Network error occurred',
          'suggestion': 'Please check your internet connection and try again',
          'action': 'Retry registration',
        },
        'errors': {'general': 'Network or connection error'},
      };
    }
  }

  /// Join an existing family using family code (connects to POST /api/auth/signup/existing-family)
  /// This method will be used by the JoinFamilyPage
  Future<Map<String, dynamic>> joinFamily({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String familyCode,
    String? gender,
  }) async {
    try {
      // Validate input parameters
      if (name.isEmpty ||
          email.isEmpty ||
          phone.isEmpty ||
          password.isEmpty ||
          familyCode.isEmpty) {
        return {
          'success': false,
          'messages': {
            'main': 'Join Family Failed',
            'details':
                'All required fields must be filled including family code',
            'suggestion': 'Please check your input and try again',
            'action': 'Fill in all required fields',
          },
          'errors': _validateFields(
            name,
            email,
            phone,
            password,
            gender,
            familyCode,
          ),
        };
      }

      // Convert gender string to boolean
      bool genderBoolean = _convertGenderToBoolean(gender);

      // Prepare request body matching SignUpExistingFamilyRequestDTO
      final Map<String, dynamic> requestBody = {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'password': password,
        'gender': genderBoolean,
        'familyId': familyCode.trim(), // Assuming family code is the family ID
      };

      debugPrint('🚀 Making API call to: $_baseUrl/signup/existing-family');
      debugPrint('📤 Request body: ${json.encode(requestBody)}');

      // Make HTTP POST request to Java Spring Boot backend
      final response = await http
          .post(
            Uri.parse('$_baseUrl/signup/existing-family'),
            headers: _headers,
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Parse successful response
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        final token = responseData['token'] as String?;

        if (token != null && token.isNotEmpty) {
          // Store JWT token for future requests
          await _storeToken(token);

          return {
            'success': true,
            'messages': {
              'main': 'Successfully Joined Family!',
              'welcome': 'Welcome to the family, ${name.split(' ').first}!',
            },
            'data': {
              'token': token,
              'name': name,
              'email': email,
              'phone': phone,
              'gender': gender,
              'family_code': familyCode.toUpperCase(),
              'is_family_creator': false,
              'profile_complete': true,
            },
          };
        } else {
          return {
            'success': false,
            'messages': {
              'main': 'Join Family Failed',
              'details': 'Invalid response from server',
              'action': 'Please try again',
            },
          };
        }
      } else {
        // Handle errors from backend
        return _handleErrorResponse(response);
      }
    } catch (e) {
      debugPrint('❌ AuthService.joinFamily error: $e');
      return {
        'success': false,
        'messages': {
          'main': 'Join Family Failed',
          'details': 'An unexpected error occurred while joining the family',
          'suggestion': 'Please check your family code and try again',
          'action': 'Verify family code and retry',
        },
        'errors': {'general': 'Network or server error occurred'},
      };
    }
  }

  /// Login method (connects to POST /api/auth/login)
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'email': email.trim().toLowerCase(),
        'password': password,
      };

      debugPrint('🚀 Making API call to: $_baseUrl/login');

      final response = await http
          .post(
            Uri.parse('$_baseUrl/login'),
            headers: _headers,
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📥 Login response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        final token = responseData['token'] as String?;

        if (token != null && token.isNotEmpty) {
          await _storeToken(token);

          return {
            'success': true,
            'messages': {
              'main': 'Login Successful',
              'welcome': 'Welcome back!',
            },
            'data': {'token': token, 'email': email},
          };
        }
      }

      return _handleErrorResponse(response);
    } catch (e) {
      debugPrint('❌ AuthService.loginUser error: $e');
      return {
        'success': false,
        'messages': {
          'main': 'Login Failed',
          'details': 'Unable to connect to server',
          'action': 'Check your internet connection and try again',
        },
      };
    }
  }

  /// Convert gender string to boolean as expected by Java backend
  bool _convertGenderToBoolean(String? gender) {
    if (gender == null || gender.isEmpty) {
      return true; // Default to true (male) if not specified
    }

    switch (gender.toLowerCase()) {
      case 'male':
        return true;
      case 'female':
        return false;
      default:
        return true; // Default to male for any unexpected values
    }
  }

  /// Validate form fields and return specific error messages
  Map<String, String> _validateFields(
    String name,
    String email,
    String phone,
    String password,
    String? gender,
    String? familyCode,
  ) {
    final Map<String, String> errors = {};

    // Name validation
    if (name.isEmpty) {
      errors['name'] = 'Name is required';
    } else if (name.length < 2) {
      errors['name'] = 'Name must be at least 2 characters';
    }

    // Email validation
    if (email.isEmpty) {
      errors['email'] = 'Email is required';
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      errors['email'] = 'Please enter a valid email address';
    }

    // Phone validation
    if (phone.isEmpty) {
      errors['phone'] = 'Phone number is required';
    } else if (!RegExp(r'^[+]?[0-9]+$').hasMatch(phone)) {
      errors['phone'] = 'Phone number can only contain numbers and + character';
    } else if (phone.length < 10) {
      errors['phone'] = 'Phone number must be at least 10 characters';
    }

    // Password validation
    if (password.isEmpty) {
      errors['password'] = 'Password is required';
    } else if (password.length < 6) {
      errors['password'] = 'Password must be at least 6 characters';
    }

    // Gender validation (optional but if provided should be valid)
    if (gender != null && gender.isNotEmpty) {
      final validGenders = ['male', 'female'];
      if (!validGenders.contains(gender)) {
        errors['gender'] = 'Please select a valid gender option';
      }
    }

    // Family code validation (if provided)
    if (familyCode != null) {
      if (familyCode.isEmpty) {
        errors['family_code'] = 'Family code is required';
      }
    }

    return errors;
  }

  /// Handle error responses from the backend
  Map<String, dynamic> _handleErrorResponse(http.Response response) {
    try {
      if (response.body.isNotEmpty) {
        final errorData = json.decode(response.body) as Map<String, dynamic>;

        // Handle Java Spring Boot validation error format
        if (errorData.containsKey('message')) {
          final message = errorData['message'] as String;

          if (message.contains('Email is already in use')) {
            return {
              'success': false,
              'messages': {
                'main': 'Email Already Exists',
                'details': 'An account with this email already exists',
                'suggestion': 'Try logging in instead or use a different email',
                'action': 'Use different email or try login',
              },
              'errors': {'email': 'This email is already registered'},
            };
          } else if (message.contains(
            'Password must be at least 6 characters',
          )) {
            return {
              'success': false,
              'messages': {
                'main': 'Password Too Short',
                'details': 'Password must be at least 6 characters long',
                'action': 'Enter a longer password',
              },
              'errors': {'password': 'Password must be at least 6 characters'},
            };
          } else if (message.contains('Family not found')) {
            return {
              'success': false,
              'messages': {
                'main': 'Invalid Family Code',
                'details': 'The family code you entered is not valid',
                'suggestion':
                    'Please check the family code with the family creator',
                'action': 'Verify family code and try again',
              },
              'errors': {'family_code': 'Invalid family code'},
            };
          } else if (message.contains('Invalid credentials')) {
            return {
              'success': false,
              'messages': {
                'main': 'Login Failed',
                'details': 'Email or password is incorrect',
                'action': 'Check your credentials and try again',
              },
              'errors': {'general': 'Invalid email or password'},
            };
          }

          // Generic error message
          return {
            'success': false,
            'messages': {
              'main': 'Operation Failed',
              'details': message,
              'action': 'Please try again',
            },
          };
        }
      }

      // Default error response
      return {
        'success': false,
        'messages': {
          'main': 'Operation Failed',
          'details': 'Server returned an error (${response.statusCode})',
          'action': 'Please try again later',
        },
      };
    } catch (e) {
      debugPrint('❌ Error parsing error response: $e');
      return {
        'success': false,
        'messages': {
          'main': 'Operation Failed',
          'details': 'Unable to process server response',
          'action': 'Please try again',
        },
      };
    }
  }

  /// Store JWT token securely using Flutter Secure Storage
  Future<void> _storeToken(String token) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
      debugPrint('✅ JWT token stored securely');
    } catch (e) {
      debugPrint('❌ Error storing token securely: $e');
      // Fallback: try to clear any corrupted data
      try {
        await _secureStorage.delete(key: _tokenKey);
      } catch (clearError) {
        debugPrint('❌ Error clearing corrupted token: $clearError');
      }
    }
  }

  /// Get stored JWT token from secure storage
  Future<String?> getToken() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      return token;
    } catch (e) {
      debugPrint('❌ Error getting token from secure storage: $e');
      return null;
    }
  }

  /// Check if user is logged in (has valid token)
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Logout user (remove token from secure storage)
  Future<void> logoutUser() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      debugPrint('✅ User logged out and tokens cleared securely');
    } catch (e) {
      debugPrint('❌ Error during secure logout: $e');
      // Try to clear all stored data as fallback
      try {
        await _secureStorage.deleteAll();
        debugPrint('✅ All secure storage cleared as fallback');
      } catch (fallbackError) {
        debugPrint('❌ Error clearing all secure storage: $fallbackError');
      }
    }
  }

  /// Store refresh token securely (for future use)
  Future<void> _storeRefreshToken(String refreshToken) async {
    try {
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      debugPrint('✅ Refresh token stored securely');
    } catch (e) {
      debugPrint('❌ Error storing refresh token: $e');
    }
  }

  /// Get stored refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('❌ Error getting refresh token: $e');
      return null;
    }
  }

  /// Clear all stored authentication data
  Future<void> clearAllAuthData() async {
    try {
      await _secureStorage.deleteAll();
      debugPrint('✅ All authentication data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing authentication data: $e');
    }
  }

  /// Get headers with authorization token for authenticated requests
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    final headers = Map<String, String>.from(_headers);

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// Decode JWT token to extract user information
  /// Returns null if token is invalid or expired
  Map<String, dynamic>? decodeToken(String token) {
    try {
      // Decode JWT without verification (since we trust tokens from our backend)
      final jwt = JWT.decode(token);

      debugPrint('🔓 JWT decoded successfully');
      debugPrint('📋 JWT payload: ${jwt.payload}');

      return jwt.payload;
    } catch (e) {
      debugPrint('❌ Error decoding JWT token: $e');
      return null;
    }
  }

  /// Get current user information from stored JWT token
  Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        debugPrint('❌ No token found');
        return null;
      }

      final payload = decodeToken(token);
      if (payload == null) {
        debugPrint('❌ Invalid token payload');
        return null;
      }

      // Extract common JWT claims and custom user data
      // Based on Java backend: JWT contains 'sub' (email), 'family_id', 'iat', 'exp'
      return {
        'user_id': payload['sub'], // Subject (user email from backend)
        'email': payload['sub'], // In our backend, subject is the email
        'family_id': payload['family_id'], // Family ID from backend
        'issued_at': payload['iat'], // Issued at timestamp
        'expires_at': payload['exp'], // Expiration timestamp
        'raw_payload': payload, // Full payload for debugging
      };
    } catch (e) {
      debugPrint('❌ Error getting current user info: $e');
      return null;
    }
  }

  /// Debug method to print JWT token contents
  Future<void> debugToken() async {
    try {
      final token = await getToken();
      if (token != null) {
        debugPrint('🔍 Raw token: ${token.substring(0, 50)}...');
        final payload = decodeToken(token);
        debugPrint('🔍 Decoded payload: $payload');

        final userInfo = await getCurrentUserInfo();
        debugPrint('🔍 Processed user info: $userInfo');
      } else {
        debugPrint('❌ No token found for debugging');
      }
    } catch (e) {
      debugPrint('❌ Error debugging token: $e');
    }
  }

  /// Check if the stored JWT token is expired
  Future<bool> isTokenExpired() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        return true; // No token means "expired"
      }

      final payload = decodeToken(token);
      if (payload == null) {
        return true; // Invalid token means "expired"
      }

      final exp = payload['exp'];
      if (exp == null) {
        return false; // No expiration claim means token doesn't expire
      }

      // Convert expiration timestamp to DateTime and compare with current time
      final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final isExpired = DateTime.now().isAfter(expirationDate);

      if (isExpired) {
        debugPrint('⏰ JWT token is expired');
        debugPrint('📅 Expired at: $expirationDate');
      } else {
        debugPrint('✅ JWT token is still valid');
        debugPrint('📅 Expires at: $expirationDate');
      }

      return isExpired;
    } catch (e) {
      debugPrint('❌ Error checking token expiration: $e');
      return true; // Assume expired on error
    }
  }

  /// Get family ID from JWT token
  Future<String?> getFamilyId() async {
    try {
      final userInfo = await getCurrentUserInfo();
      return userInfo?['family_id'] as String?;
    } catch (e) {
      debugPrint('❌ Error getting family ID: $e');
      return null;
    }
  }

  /// Get user ID from JWT token
  Future<String?> getUserId() async {
    try {
      final userInfo = await getCurrentUserInfo();
      return userInfo?['user_id'] as String?;
    } catch (e) {
      debugPrint('❌ Error getting user ID: $e');
      return null;
    }
  }

  /// Check if current user is the family creator
  Future<bool> isFamilyCreator() async {
    try {
      final userInfo = await getCurrentUserInfo();
      return userInfo?['is_family_creator'] as bool? ?? false;
    } catch (e) {
      debugPrint('❌ Error checking family creator status: $e');
      return false;
    }
  }

  /// Get time until token expires (in minutes)
  Future<int?> getTokenTimeToExpiry() async {
    try {
      final userInfo = await getCurrentUserInfo();
      final exp = userInfo?['expires_at'];

      if (exp == null) return null;

      final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();

      if (now.isAfter(expirationDate)) {
        return 0; // Already expired
      }

      final difference = expirationDate.difference(now);
      return difference.inMinutes;
    } catch (e) {
      debugPrint('❌ Error getting token time to expiry: $e');
      return null;
    }
  }

  /// Get complete user profile using JWT token (sub = email)
  /// This method extracts email from JWT token and fetches all user data from backend
  Future<Map<String, dynamic>?> getCompleteUserProfile() async {
    try {
      // First, get JWT token and extract user info
      final token = await _secureStorage.read(key: _tokenKey);
      if (token == null || token.isEmpty) {
        debugPrint('❌ No token found for profile fetch');
        return null;
      }

      // Decode JWT token to get user email and family_id
      final tokenInfo = await getCurrentUserInfo();
      if (tokenInfo == null) {
        debugPrint('❌ Could not decode JWT token');
        return null;
      }

      final userEmail = tokenInfo['email'];
      final familyId = tokenInfo['family_id'];

      debugPrint('🔍 JWT decoded - Email: $userEmail, Family ID: $familyId');
      debugPrint('🔍 === CALLING GET /api/parent ENDPOINT ===');

      // Parent endpoint is at /api/parent (not /api/auth/parent)
      // So we need to remove /auth from the base URL for this endpoint
      final parentUrl = _baseUrl.replaceAll('/api/auth', '/api') + '/parent';
      debugPrint('🔍 URL: $parentUrl');
      debugPrint('🔍 Authorization: Bearer ${token.substring(0, 20)}...');

      // Use the JWT token to get complete parent profile from backend
      // This calls the ParentController.getParent() method from your Java backend
      final response = await http
          .get(
            Uri.parse(parentUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📥 === API RESPONSE FROM GET /api/parent ===');
      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Response Headers: ${response.headers}');
      debugPrint('📥 Raw Response Body: ${response.body}');
      debugPrint('📥 === END API RESPONSE ===');

      if (response.statusCode == 200) {
        final backendProfile =
            json.decode(response.body) as Map<String, dynamic>;

        debugPrint('🔍 === PARSED PARENT DATA FROM ParentResponseDTO ===');
        debugPrint('🔍 Parent ID: ${backendProfile['id']}');
        debugPrint('🔍 Parent Name: ${backendProfile['name']}');
        debugPrint('🔍 Parent Email: ${backendProfile['email']}');
        debugPrint('🔍 Parent Phone: ${backendProfile['phone']}');
        debugPrint(
          '🔍 Parent Gender: ${backendProfile['gender']} (${backendProfile['gender'].runtimeType})',
        );
        debugPrint(
          '🔍 Profile Picture Type: ${backendProfile['profilePictureType']}',
        );
        debugPrint(
          '🔍 Profile Picture Name: ${backendProfile['profilePictureName']}',
        );
        debugPrint(
          '🔍 Profile Picture Size: ${backendProfile['profilePictureSize']}',
        );
        debugPrint(
          '🔍 Profile Picture Content Type: ${backendProfile['profilePictureContentType']}',
        );
        debugPrint('🔍 === ALL FIELDS FROM BACKEND ===');
        backendProfile.forEach((key, value) {
          debugPrint('🔍   $key: $value (${value.runtimeType})');
        });
        debugPrint('🔍 === END PARENT DATA ===');

        // Return complete user profile with all data
        final completeProfile = {
          // Backend profile data (complete user info)
          'id': backendProfile['id'],
          'name': backendProfile['name'] ?? 'User',
          'email': backendProfile['email'] ?? userEmail,
          'phone': backendProfile['phone'] ?? '',
          'gender': backendProfile['gender'], // true = male, false = female
          'profile_picture_type': backendProfile['profilePictureType'],
          'profile_picture_name': backendProfile['profilePictureName'],
          'profile_picture_size': backendProfile['profilePictureSize'],
          'profile_picture_content_type':
              backendProfile['profilePictureContentType'],

          // JWT token data
          'family_id': familyId,
          'token_email': userEmail,
          'issued_at': tokenInfo['issued_at'],
          'expires_at': tokenInfo['expires_at'],

          // Processed data for UI
          'gender_display': backendProfile['gender'] == true
              ? 'Male'
              : (backendProfile['gender'] == false
                    ? 'Female'
                    : 'Not specified'),
          'family_code':
              familyId ?? 'No family', // Use family_id directly as family code
        };

        debugPrint('🔍 === FINAL COMBINED USER PROFILE ===');
        debugPrint('🔍 Combined Backend + JWT data:');
        completeProfile.forEach((key, value) {
          debugPrint('🔍   $key: $value');
        });
        debugPrint('🔍 === END COMBINED PROFILE ===');

        debugPrint(
          '✅ Complete user profile loaded: ${completeProfile['name']} (${completeProfile['email']})',
        );
        return completeProfile;
      } else if (response.statusCode == 401) {
        debugPrint('❌ Unauthorized - token may be expired');
        await logoutUser(); // Clear invalid token
        return null;
      } else {
        debugPrint(
          '❌ Failed to fetch user profile: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting complete user profile: $e');
      return null;
    }
  }

  /// Legacy method - use getCompleteUserProfile() instead
  /// Get complete family data using JWT token
  /// This calls GET /api/family endpoint and returns FamilyResponseDTO
  Future<Map<String, dynamic>?> getFamilyData() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      if (token == null || token.isEmpty) {
        debugPrint('❌ No token found for family data fetch');
        return null;
      }

      debugPrint('🔍 === CALLING GET /api/family ENDPOINT ===');

      // Family endpoint is at /api/family (not /api/auth/family)
      final familyUrl = _baseUrl.replaceAll('/api/auth', '/api') + '/family';
      debugPrint('🔍 URL: $familyUrl');
      debugPrint('🔍 Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http
          .get(
            Uri.parse(familyUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📥 === API RESPONSE FROM GET /api/family ===');
      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Response Headers: ${response.headers}');
      debugPrint('📥 Raw Response Body: ${response.body}');
      debugPrint('📥 === END API RESPONSE ===');

      if (response.statusCode == 200) {
        final familyData = json.decode(response.body) as Map<String, dynamic>;

        debugPrint('🔍 === PARSED FAMILY DATA FROM FamilyResponseDTO ===');
        debugPrint('🔍 Family Children: ${familyData['children']}');
        debugPrint('🔍 Family Parents: ${familyData['parents']}');
        debugPrint('🔍 === END FAMILY DATA ===');

        return familyData;
      } else {
        debugPrint('❌ Failed to get family data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ AuthService.getFamilyData error: $e');
      return null;
    }
  }

  /// Add child to family using JWT token
  /// This calls POST /api/child endpoint with ChildRequestDTO
  Future<Map<String, dynamic>> addChild({
    required String name,
    required bool gender, // true = male, false = female
    required DateTime dateOfBirth,
    String? medicalNotes,
  }) async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      // Prepare request body matching ChildRequestDTO
      final Map<String, dynamic> requestBody = {
        'name': name.trim(),
        'gender': gender,
        'dateOfBirth': dateOfBirth.toIso8601String().split(
          'T',
        )[0], // YYYY-MM-DD format
        'medicalNotes': medicalNotes?.trim(),
      };

      debugPrint('🔍 === CALLING POST /api/child ENDPOINT ===');

      // Child endpoint is at /api/child (not /api/auth/child)
      final childUrl = _baseUrl.replaceAll('/api/auth', '/api') + '/child';
      debugPrint('🔍 URL: $childUrl');
      debugPrint('📤 Request body: ${json.encode(requestBody)}');

      final response = await http
          .post(
            Uri.parse(childUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📥 === API RESPONSE FROM POST /api/child ===');
      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Raw Response Body: ${response.body}');
      debugPrint('📥 === END API RESPONSE ===');

      if (response.statusCode == 200) {
        final childData = json.decode(response.body) as Map<String, dynamic>;

        return {
          'success': true,
          'message': 'Child added successfully!',
          'data': childData,
        };
      } else {
        final errorData = json.decode(response.body) as Map<String, dynamic>?;
        return {
          'success': false,
          'message': errorData?['message'] ?? 'Failed to add child',
          'errors': errorData,
        };
      }
    } catch (e) {
      debugPrint('❌ AuthService.addChild error: $e');
      return {'success': false, 'message': 'Network error occurred: $e'};
    }
  }

  /// Update user profile information
  Future<Map<String, dynamic>> updateUserProfile({
    String? name,
    String? phone,
    bool? gender,
  }) async {
    try {
      debugPrint('🔍 === UPDATING USER PROFILE ===');

      final token = await _secureStorage.read(key: _tokenKey);
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      // Prepare request body with only the fields to update
      final Map<String, dynamic> requestBody = {};

      if (name != null && name.trim().isNotEmpty) {
        requestBody['name'] = name.trim();
      }
      if (phone != null && phone.trim().isNotEmpty) {
        requestBody['phone'] = phone.trim();
      }
      if (gender != null) {
        requestBody['gender'] = gender;
      }

      if (requestBody.isEmpty) {
        return {'success': false, 'message': 'No fields to update'};
      }

      debugPrint('🔍 Update request body: ${json.encode(requestBody)}');

      // Parent endpoint is at /api/parent (not /api/auth/parent)
      final parentUrl = _baseUrl.replaceAll('/api/auth', '/api') + '/parent';
      debugPrint('🔍 PUT URL: $parentUrl');

      final response = await http
          .put(
            Uri.parse(parentUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📥 Update Response Status: ${response.statusCode}');
      debugPrint('📥 Update Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final updatedData = json.decode(response.body) as Map<String, dynamic>;

        return {
          'success': true,
          'message': 'Profile updated successfully!',
          'data': updatedData,
        };
      } else {
        final errorData = json.decode(response.body) as Map<String, dynamic>?;
        return {
          'success': false,
          'message': errorData?['message'] ?? 'Failed to update profile',
          'errors': errorData,
        };
      }
    } catch (e) {
      debugPrint('❌ AuthService.updateUserProfile error: $e');
      return {'success': false, 'message': 'Network error occurred: $e'};
    }
  }

  @deprecated
  Future<Map<String, dynamic>?> getParentProfile() async {
    return await getCompleteUserProfile();
  }
}
