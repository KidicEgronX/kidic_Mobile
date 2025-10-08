import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kidicapp_flutter/services/auth/auth_service.dart';

class ChildService {
  final AuthService _authService = AuthService();

  // Backend URL - matches the auth service pattern
  // Android Emulator: http://10.0.2.2:8080/api/child
  // iOS Simulator/Web: http://localhost:8080/api/child
  // Physical Device/Network: http://192.168.1.4:8080/api/child
  static const String _baseUrl = 'http://10.0.2.2:8080/api/child';

  /// Get child data by ID using JWT token
  /// This calls GET /api/child/{id} endpoint from ChildController.getChild()
  Future<Map<String, dynamic>?> getChild(int childId) async {
    try {
      debugPrint('🔍 === CALLING GET /api/child/$childId ENDPOINT ===');

      // Get JWT token for authentication
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('❌ No authentication token found');
        return null;
      }

      // Prepare the request URL
      final url = '$_baseUrl/$childId';
      debugPrint('🔍 URL: $url');
      debugPrint('🔍 Authorization: Bearer ${token.substring(0, 20)}...');

      // Make HTTP GET request to Java Spring Boot backend
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📥 === API RESPONSE FROM GET /api/child/$childId ===');
      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Response Headers: ${response.headers}');
      debugPrint('📥 Raw Response Body: ${response.body}');
      debugPrint('📥 === END API RESPONSE ===');

      if (response.statusCode == 200) {
        final childData = json.decode(response.body) as Map<String, dynamic>;

        debugPrint('🔍 === PARSED CHILD DATA FROM ChildResponseDTO ===');
        debugPrint('🔍 Child ID: ${childData['id']}');
        debugPrint('🔍 Child Name: ${childData['name']}');
        debugPrint(
          '🔍 Child Gender: ${childData['gender']} (${childData['gender'].runtimeType})',
        );
        debugPrint('🔍 Child Date of Birth: ${childData['dateOfBirth']}');
        debugPrint('🔍 Child Medical Notes: ${childData['medicalNotes']}');
        debugPrint('🔍 === PROCESSING CHILD DATA ===');

        // Process the child data for easier use in the UI
        final processedChildData = {
          'id': childData['id'],
          'name': childData['name'] ?? 'Unknown Child',
          'gender': childData['gender'], // true = male, false = female
          'dateOfBirth': childData['dateOfBirth'],
          'medicalNotes': childData['medicalNotes'],

          // Add calculated fields for UI convenience
          'age': _calculateAge(childData['dateOfBirth']),
          'genderDisplay': childData['gender'] == true
              ? 'Male'
              : (childData['gender'] == false ? 'Female' : 'Not specified'),
          'initials': _getChildInitials(childData['name']),
        };

        debugPrint('🔍 === FINAL PROCESSED CHILD DATA ===');
        processedChildData.forEach((key, value) {
          debugPrint('🔍   $key: $value');
        });
        debugPrint('🔍 === END PROCESSED CHILD DATA ===');

        debugPrint(
          '✅ Child data loaded successfully: ${processedChildData['name']}',
        );
        return processedChildData;
      } else if (response.statusCode == 401) {
        debugPrint('❌ Unauthorized - token may be expired');
        await _authService.logoutUser(); // Clear invalid token
        return null;
      } else if (response.statusCode == 404) {
        debugPrint('❌ Child not found with ID: $childId');
        return null;
      } else if (response.statusCode == 403) {
        debugPrint('❌ Access forbidden - child may not belong to this parent');
        return null;
      } else {
        debugPrint(
          '❌ Failed to fetch child data: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ ChildService.getChild error: $e');
      return null;
    }
  }

  /// Get all children for the authenticated parent
  /// This method uses the existing family data from AuthService
  Future<List<Map<String, dynamic>>> getAllChildren() async {
    try {
      debugPrint('🔍 === GETTING ALL CHILDREN FOR PARENT ===');

      // Use the existing family data method from AuthService
      final familyData = await _authService.getFamilyData();
      if (familyData == null) {
        debugPrint('❌ No family data found');
        return [];
      }

      final childrenList = familyData['children'] as List<dynamic>? ?? [];
      debugPrint('🔍 Found ${childrenList.length} children in family data');

      // Process each child data
      final processedChildren = childrenList.map((child) {
        final childMap = child as Map<String, dynamic>;
        return {
          'id': childMap['id'],
          'name': childMap['name'] ?? 'Unknown Child',
          'gender': childMap['gender'],
          'dateOfBirth': childMap['dateOfBirth'],
          'medicalNotes': childMap['medicalNotes'],
          'age': _calculateAge(childMap['dateOfBirth']),
          'genderDisplay': childMap['gender'] == true
              ? 'Male'
              : (childMap['gender'] == false ? 'Female' : 'Not specified'),
          'initials': _getChildInitials(childMap['name']),
        };
      }).toList();

      debugPrint('✅ Processed ${processedChildren.length} children');
      return List<Map<String, dynamic>>.from(processedChildren);
    } catch (e) {
      debugPrint('❌ ChildService.getAllChildren error: $e');
      return [];
    }
  }

  /// Create a new child using JWT token
  /// This calls POST /api/child endpoint from ChildController.create()
  Future<Map<String, dynamic>> createChild({
    required String name,
    required bool gender,
    required String dateOfBirth,
    String? medicalNotes,
  }) async {
    try {
      debugPrint('🔍 === CALLING POST /api/child ENDPOINT ===');

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      // Prepare request body (ChildCreateRequestDTO)
      final Map<String, dynamic> requestBody = {
        'name': name.trim(),
        'gender': gender,
        'dateOfBirth': dateOfBirth.trim(),
      };

      if (medicalNotes != null && medicalNotes.trim().isNotEmpty) {
        requestBody['medicalNotes'] = medicalNotes.trim();
      }

      debugPrint('🔍 Create request body: ${json.encode(requestBody)}');

      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📥 Create Response Status: ${response.statusCode}');
      debugPrint('📥 Create Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final createdData = json.decode(response.body) as Map<String, dynamic>;

        return {
          'success': true,
          'message': 'Child created successfully!',
          'data': createdData,
        };
      } else {
        final errorData = json.decode(response.body) as Map<String, dynamic>?;
        return {
          'success': false,
          'message': errorData?['message'] ?? 'Failed to create child',
          'errors': errorData,
        };
      }
    } catch (e) {
      debugPrint('❌ ChildService.createChild error: $e');
      return {'success': false, 'message': 'Network error occurred: $e'};
    }
  }

  /// Update child data by ID using JWT token
  /// This calls PUT /api/child/{id} endpoint from ChildController.update()
  Future<Map<String, dynamic>> updateChild({
    required int childId,
    String? name,
    bool? gender,
    String? dateOfBirth,
    String? medicalNotes,
  }) async {
    try {
      debugPrint('🔍 === CALLING PUT /api/child/$childId ENDPOINT ===');

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      // Prepare request body with only the fields to update (ChildUpdateRequestDTO)
      final Map<String, dynamic> requestBody = {};

      if (name != null && name.trim().isNotEmpty) {
        requestBody['name'] = name.trim();
      }
      if (gender != null) {
        requestBody['gender'] = gender;
      }
      if (dateOfBirth != null && dateOfBirth.trim().isNotEmpty) {
        requestBody['dateOfBirth'] = dateOfBirth.trim();
      }
      if (medicalNotes != null) {
        requestBody['medicalNotes'] = medicalNotes.trim().isEmpty
            ? null
            : medicalNotes.trim();
      }

      if (requestBody.isEmpty) {
        return {'success': false, 'message': 'No fields to update'};
      }

      debugPrint('🔍 Update request body: ${json.encode(requestBody)}');

      final url = '$_baseUrl/$childId';
      final response = await http
          .put(
            Uri.parse(url),
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
          'message': 'Child updated successfully!',
          'data': updatedData,
        };
      } else {
        final errorData = json.decode(response.body) as Map<String, dynamic>?;
        return {
          'success': false,
          'message': errorData?['message'] ?? 'Failed to update child',
          'errors': errorData,
        };
      }
    } catch (e) {
      debugPrint('❌ ChildService.updateChild error: $e');
      return {'success': false, 'message': 'Network error occurred: $e'};
    }
  }

  /// Delete child by ID using JWT token
  /// This calls DELETE /api/child/{id} endpoint from ChildController.delete()
  Future<Map<String, dynamic>> deleteChild(int childId) async {
    try {
      debugPrint('🔍 === CALLING DELETE /api/child/$childId ENDPOINT ===');

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final url = '$_baseUrl/$childId';
      final response = await http
          .delete(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📥 Delete Response Status: ${response.statusCode}');
      debugPrint('📥 Delete Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.body.isNotEmpty
              ? response.body
              : 'Child deleted successfully!',
        };
      } else {
        final errorData = json.decode(response.body) as Map<String, dynamic>?;
        return {
          'success': false,
          'message': errorData?['message'] ?? 'Failed to delete child',
          'errors': errorData,
        };
      }
    } catch (e) {
      debugPrint('❌ ChildService.deleteChild error: $e');
      return {'success': false, 'message': 'Network error occurred: $e'};
    }
  }

  /// Calculate age from date of birth string
  String _calculateAge(String? dateOfBirthString) {
    if (dateOfBirthString == null || dateOfBirthString.isEmpty) {
      return 'Age unknown';
    }

    try {
      final dateOfBirth = DateTime.parse(dateOfBirthString);
      final now = DateTime.now();
      final difference = now.difference(dateOfBirth);

      final years = (difference.inDays / 365).floor();
      final months = ((difference.inDays % 365) / 30).floor();

      if (years > 0) {
        if (months > 0) {
          return '$years years $months months';
        } else {
          return '$years ${years == 1 ? 'year' : 'years'}';
        }
      } else if (months > 0) {
        return '$months ${months == 1 ? 'month' : 'months'}';
      } else {
        final days = difference.inDays;
        return '$days ${days == 1 ? 'day' : 'days'}';
      }
    } catch (e) {
      debugPrint('Error calculating age: $e');
      return 'Age unknown';
    }
  }

  /// Get initials from child name for avatar display
  String _getChildInitials(String? name) {
    if (name == null || name.isEmpty) return 'C';

    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      return name[0].toUpperCase();
    }
  }

  /// Validate child data before sending to backend
  Map<String, String> validateChildData({
    String? name,
    bool? gender,
    String? dateOfBirth,
    String? medicalNotes,
  }) {
    final Map<String, String> errors = {};

    // Name validation
    if (name != null) {
      if (name.trim().isEmpty) {
        errors['name'] = 'Name is required';
      } else if (name.trim().length < 2) {
        errors['name'] = 'Name must be at least 2 characters';
      }
    }

    // Date of birth validation
    if (dateOfBirth != null && dateOfBirth.trim().isNotEmpty) {
      try {
        final date = DateTime.parse(dateOfBirth);
        final now = DateTime.now();

        if (date.isAfter(now)) {
          errors['dateOfBirth'] = 'Date of birth cannot be in the future';
        }

        final age = now.difference(date).inDays / 365;
        if (age > 18) {
          errors['dateOfBirth'] = 'Child must be under 18 years old';
        }
      } catch (e) {
        errors['dateOfBirth'] = 'Invalid date format';
      }
    }

    // Medical notes validation (optional, but if provided should not be too long)
    if (medicalNotes != null && medicalNotes.trim().length > 1000) {
      errors['medicalNotes'] =
          'Medical notes must be less than 1000 characters';
    }

    return errors;
  }

  /// Check if child belongs to the authenticated parent
  /// This is a helper method to verify access before operations
  Future<bool> isChildAccessible(int childId) async {
    try {
      final childData = await getChild(childId);
      return childData != null;
    } catch (e) {
      debugPrint('❌ Error checking child accessibility: $e');
      return false;
    }
  }

  /// Get child profile picture URL (if implemented in backend)
  String? getChildProfilePictureUrl(int childId) {
    // This would be implemented when profile pictures are added to the backend
    // For now, return null to use initials-based avatars
    return null;
  }
}
