import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kidicapp_flutter/services/auth/auth_service.dart';

/// Milestone Service - Connects to Java Spring Boot Milestone API
/// Endpoints: /api/milestones/*
class MilestoneService {
  final AuthService _authService = AuthService();

  // Base URL for milestone endpoints
  static const String _baseUrl = 'http://10.0.2.2:8080/api/milestones';

  /// Get all milestones for a specific child
  /// Calls: GET /api/milestones/child/{childId}
  /// Returns: List of milestones with auto-updated overdue status
  Future<List<Map<String, dynamic>>> getMilestonesByChildId(int childId) async {
    try {
      debugPrint('🎯 === CALLING GET /api/milestones/child/$childId ===');

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('❌ No authentication token found');
        return [];
      }

      final url = '$_baseUrl/child/$childId';
      debugPrint('🎯 URL: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> milestonesJson = json.decode(response.body);
        final List<Map<String, dynamic>> milestones = milestonesJson
            .cast<Map<String, dynamic>>();

        debugPrint('✅ Got ${milestones.length} milestones');
        return milestones;
      } else {
        debugPrint('❌ Failed to get milestones: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ MilestoneService.getMilestonesByChildId error: $e');
      return [];
    }
  }

  /// Generate 10 built-in milestones for a child
  /// Calls: POST /api/milestones/generate/{childId}
  /// Auto-completes past milestones based on child's age
  Future<Map<String, dynamic>> generateBuiltInMilestones(int childId) async {
    try {
      debugPrint('🎯 === CALLING POST /api/milestones/generate/$childId ===');

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final url = '$_baseUrl/generate/$childId';
      debugPrint('🎯 URL: $url');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Built-in milestones generated successfully',
        };
      } else {
        return {'success': false, 'message': 'Failed to generate milestones'};
      }
    } catch (e) {
      debugPrint('❌ MilestoneService.generateBuiltInMilestones error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Create a custom milestone
  /// Calls: POST /api/milestones
  Future<Map<String, dynamic>> createMilestone({
    required int childId,
    required String title,
    required String milestoneType,
    required int expectedAgeMonths,
    String? description,
    String? status,
    String? actualDate,
  }) async {
    try {
      debugPrint('🎯 === CALLING POST /api/milestones ===');

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final Map<String, dynamic> requestBody = {
        'childId': childId,
        'title': title,
        'milestoneType': milestoneType,
        'expectedAgeMonths': expectedAgeMonths,
      };

      if (description != null && description.isNotEmpty) {
        requestBody['description'] = description;
      }
      if (status != null && status.isNotEmpty) {
        requestBody['status'] = status;
      }
      if (actualDate != null && actualDate.isNotEmpty) {
        requestBody['actualDate'] = actualDate;
      }

      debugPrint('📤 Request Body: ${json.encode(requestBody)}');

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

      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final milestoneData = json.decode(response.body);
        return {
          'success': true,
          'message': 'Milestone created successfully',
          'data': milestoneData,
        };
      } else {
        return {'success': false, 'message': 'Failed to create milestone'};
      }
    } catch (e) {
      debugPrint('❌ MilestoneService.createMilestone error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Update an existing milestone (partial update)
  /// Calls: PUT /api/milestones/{id}
  Future<Map<String, dynamic>> updateMilestone({
    required int milestoneId,
    String? title,
    String? description,
    String? milestoneType,
    int? expectedAgeMonths,
    String? actualDate,
    String? status,
  }) async {
    try {
      debugPrint('🎯 === CALLING PUT /api/milestones/$milestoneId ===');

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final Map<String, dynamic> requestBody = {};

      if (title != null && title.isNotEmpty) {
        requestBody['title'] = title;
      }
      if (description != null) {
        requestBody['description'] = description;
      }
      if (milestoneType != null && milestoneType.isNotEmpty) {
        requestBody['milestoneType'] = milestoneType;
      }
      if (expectedAgeMonths != null) {
        requestBody['expectedAgeMonths'] = expectedAgeMonths;
      }
      if (actualDate != null) {
        requestBody['actualDate'] = actualDate;
      }
      if (status != null && status.isNotEmpty) {
        requestBody['status'] = status;
      }

      if (requestBody.isEmpty) {
        return {'success': false, 'message': 'No fields to update'};
      }

      debugPrint('📤 Request Body: ${json.encode(requestBody)}');

      final url = '$_baseUrl/$milestoneId';
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

      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final milestoneData = json.decode(response.body);
        return {
          'success': true,
          'message': 'Milestone updated successfully',
          'data': milestoneData,
        };
      } else {
        return {'success': false, 'message': 'Failed to update milestone'};
      }
    } catch (e) {
      debugPrint('❌ MilestoneService.updateMilestone error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Mark milestone as completed (quick action)
  /// Calls: PUT /api/milestones/{id}/complete
  Future<Map<String, dynamic>> markAsCompleted({
    required int milestoneId,
    String? completionDate,
  }) async {
    try {
      debugPrint(
        '🎯 === CALLING PUT /api/milestones/$milestoneId/complete ===',
      );

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      String url = '$_baseUrl/$milestoneId/complete';
      if (completionDate != null && completionDate.isNotEmpty) {
        url += '?completionDate=$completionDate';
      }

      debugPrint('🎯 URL: $url');

      final response = await http
          .put(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final milestoneData = json.decode(response.body);
        return {
          'success': true,
          'message': 'Milestone marked as completed',
          'data': milestoneData,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to mark milestone as completed',
        };
      }
    } catch (e) {
      debugPrint('❌ MilestoneService.markAsCompleted error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Delete a custom milestone (built-in milestones are protected)
  /// Calls: DELETE /api/milestones/{id}
  Future<Map<String, dynamic>> deleteMilestone(int milestoneId) async {
    try {
      debugPrint('🎯 === CALLING DELETE /api/milestones/$milestoneId ===');

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final url = '$_baseUrl/$milestoneId';
      debugPrint('🎯 URL: $url');

      final response = await http
          .delete(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Milestone deleted successfully'};
      } else if (response.statusCode == 400) {
        return {
          'success': false,
          'message': 'Built-in milestones cannot be deleted',
        };
      } else {
        return {'success': false, 'message': 'Failed to delete milestone'};
      }
    } catch (e) {
      debugPrint('❌ MilestoneService.deleteMilestone error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Helper: Convert milestone type string to API format
  String convertMilestoneTypeToApi(String category) {
    switch (category.toUpperCase()) {
      case 'PHYSICAL':
        return 'PHYSICAL';
      case 'COGNITIVE':
        return 'COGNITIVE';
      case 'SOCIAL':
        return 'SOCIAL';
      case 'EMOTIONAL':
        return 'EMOTIONAL';
      case 'LANGUAGE':
        return 'LANGUAGE';
      default:
        return 'PHYSICAL';
    }
  }

  /// Helper: Convert milestone status to API format
  String convertStatusToApi(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return 'COMPLETED';
      case 'PENDING':
        return 'PENDING';
      case 'OVERDUE':
        return 'OVERDUE';
      case 'UPCOMING':
        return 'PENDING';
      default:
        return 'PENDING';
    }
  }

  /// Helper: Get status color for UI
  Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return const Color(0xFF4CAF50); // Green
      case 'PENDING':
        return const Color(0xFFFFA726); // Orange
      case 'OVERDUE':
        return const Color(0xFFEF5350); // Red
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  /// Helper: Format age display from months
  String formatAgeDisplay(int months) {
    if (months < 12) {
      return '$months ${months == 1 ? 'month' : 'months'}';
    } else if (months % 12 == 0) {
      final years = months ~/ 12;
      return '$years ${years == 1 ? 'year' : 'years'}';
    } else {
      final years = months ~/ 12;
      final remainingMonths = months % 12;
      return '$years ${years == 1 ? 'year' : 'years'} $remainingMonths ${remainingMonths == 1 ? 'month' : 'months'}';
    }
  }
}
