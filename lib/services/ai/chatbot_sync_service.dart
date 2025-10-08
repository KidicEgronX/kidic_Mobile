import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kidicapp_flutter/services/auth/auth_service.dart';
import 'package:kidicapp_flutter/services/child/child_service.dart';
import 'package:kidicapp_flutter/services/child/growth_service.dart';

/// Service to sync parent and children data with the chatbot backend
/// This ensures the chatbot has the latest user context before answering questions
class ChatbotSyncService {
  final AuthService _authService = AuthService();
  final ChildService _childService = ChildService();
  final GrowthService _growthService = GrowthService();

  // Chatbot API endpoint
  // For Android Emulator: use 10.0.2.2 (special alias for host machine's localhost)
  // For iOS Simulator: use 127.0.0.1
  // For Physical Device: use your computer's IP address (e.g., 192.168.1.x)
  static const String _baseUrl = 'http://10.0.2.2:8000/api';

  /// Sync user data (parent and children) with the chatbot backend
  /// This should be called before sending chat messages
  Future<bool> syncUserDataWithChatbot() async {
    try {
      debugPrint('📤 === SYNCING USER DATA WITH CHATBOT ===');

      // Get user ID
      final parentProfile = await _authService.getCompleteUserProfile();
      if (parentProfile == null) {
        debugPrint('❌ No parent profile found');
        return false;
      }

      final userId = parentProfile['id'] as int?;
      if (userId == null) {
        debugPrint('❌ User ID not found');
        return false;
      }

      // Build parent context
      final parentContext = await _buildParentContext();
      if (parentContext == null) {
        debugPrint('❌ Could not build parent context');
        return false;
      }

      // Build children context
      final childrenContext = await _buildChildrenContext(null);

      // Prepare user data according to the chatbot API User schema
      final userData = {
        'id': userId,
        'name': parentContext['name'] ?? 'Parent',
        'phone': parentContext['phone']?.toString() ?? '',
        'email': parentContext['email']?.toString() ?? '',
        'male': parentContext['gender'] ?? true,
        'familyId': parentContext['familyId']?.toString() ?? '',
        'children': childrenContext.map((child) {
          return {
            'id': child['id'] ?? 0,
            'name': child['name']?.toString() ?? 'Unknown',
            'male': child['gender'] ?? true,
            'dateOfBirth': child['dateOfBirth']?.toString() ?? '',
            'medicalNotes': child['medicalNotes']?.toString() ?? '',
            'medicalRecords': <Map<String, dynamic>>[],
            'growthRecords': _buildGrowthRecordsArray(child),
            'diseasesAndAllergies': <String>[],
            'meals': <Map<String, dynamic>>[],
          };
        }).toList(),
      };

      debugPrint('📤 User Data: ${json.encode(userData)}');

      // Send to chatbot /api/users endpoint
      final response = await http
          .post(
            Uri.parse('$_baseUrl/users'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(userData),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('📥 Sync User Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('❌ Sync User Error Response: ${response.body}');
        return false;
      }

      debugPrint('✅ User data synced successfully with chatbot');
      return true;
    } catch (e) {
      debugPrint('❌ Error syncing user data with chatbot: $e');
      return false;
    }
  }

  /// Build growth records array from child context
  List<Map<String, dynamic>> _buildGrowthRecordsArray(
    Map<String, dynamic> child,
  ) {
    final records = <Map<String, dynamic>>[];
    if (child['latestHeight'] != null || child['latestWeight'] != null) {
      // Ensure all values are non-null for the API
      records.add({
        'height': child['latestHeight'] ?? 0,
        'weight': child['latestWeight'] ?? 0,
        'dateOfRecord': child['latestGrowthDate']?.toString() ?? '',
        'additionalInfo': child['latestGrowthNotes']?.toString() ?? '',
      });
    }
    return records;
  }

  /// Build parent context information for the chatbot
  Future<Map<String, dynamic>?> _buildParentContext() async {
    try {
      final parentProfile = await _authService.getCompleteUserProfile();
      if (parentProfile == null) return null;

      return {
        'name': parentProfile['name'] ?? 'Parent',
        'gender': parentProfile['gender'],
        'genderDisplay': parentProfile['gender_display'] ?? 'Not specified',
        'email': parentProfile['email'],
        'phone': parentProfile['phone'],
        'familyId': parentProfile['family_id'],
      };
    } catch (e) {
      debugPrint('❌ Error building parent context: $e');
      return null;
    }
  }

  /// Build children context information for the chatbot
  Future<List<Map<String, dynamic>>> _buildChildrenContext([
    List<int>? selectedChildrenIds,
  ]) async {
    try {
      final allChildren = await _childService.getAllChildren();
      List<Map<String, dynamic>> filteredChildren;

      if (selectedChildrenIds != null && selectedChildrenIds.isNotEmpty) {
        // Filter children based on selected IDs
        filteredChildren = allChildren.where((child) {
          final childId = child['id'] as int?;
          return childId != null && selectedChildrenIds.contains(childId);
        }).toList();
      } else {
        // Include all children if none specifically selected
        filteredChildren = allChildren;
      }

      final childrenContext = <Map<String, dynamic>>[];

      for (final child in filteredChildren) {
        final childId = child['id'] as int?;
        Map<String, dynamic>? latestGrowthRecord;

        if (childId != null) {
          try {
            latestGrowthRecord = await _growthService.getLatestGrowthRecord(
              childId,
            );
          } catch (e) {
            debugPrint('❌ Error getting growth for child $childId: $e');
          }
        }

        childrenContext.add({
          'id': child['id'],
          'name': child['name'] ?? 'Unknown Child',
          'age': child['age'] ?? 'Age unknown',
          'gender': child['gender'],
          'genderDisplay': child['genderDisplay'] ?? 'Not specified',
          'dateOfBirth': child['dateOfBirth'],
          'medicalNotes': child['medicalNotes'] ?? 'No medical notes',
          'latestHeight': latestGrowthRecord?['height'],
          'latestWeight': latestGrowthRecord?['weight'],
          'latestGrowthDate': latestGrowthRecord?['dateOfRecord'],
          'latestGrowthNotes': latestGrowthRecord?['additionalInfo'],
        });
      }

      return childrenContext;
    } catch (e) {
      debugPrint('❌ Error building children context: $e');
      return [];
    }
  }
}
