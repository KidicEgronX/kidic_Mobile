import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kidicapp_flutter/services/auth/auth_service.dart';

/// Vaccine Service - Connects to Java Spring Boot Vaccine API
/// Endpoints: /api/vaccines/*
class VaccineService {
  final AuthService _authService = AuthService();

  // Base URL for vaccine endpoints
  static const String _baseUrl = 'http://10.0.2.2:8080/api/vaccines';

  /// Get all vaccines for a specific child
  /// Calls: GET /api/vaccines/children/{childId}
  /// Returns: List of vaccines
  Future<List<Map<String, dynamic>>> getVaccinesByChildId(int childId) async {
    try {
      debugPrint('🎯 === CALLING GET /api/vaccines/children/$childId ===');

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('❌ No authentication token found');
        return [];
      }

      final url = '$_baseUrl/children/$childId';
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
        final List<dynamic> vaccinesJson = json.decode(response.body);
        final List<Map<String, dynamic>> vaccines = vaccinesJson
            .cast<Map<String, dynamic>>();

        debugPrint('✅ Got ${vaccines.length} vaccines');
        return vaccines;
      } else {
        debugPrint('❌ Failed to get vaccines: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ VaccineService.getVaccinesByChildId error: $e');
      return [];
    }
  }

  /// Generate built-in vaccines for a child (6 default vaccines)
  /// Calls: POST /api/vaccines/children/{childId}/generate-default
  /// Auto-marks past vaccines as completed based on child's age
  Future<Map<String, dynamic>> generateDefaultVaccines(int childId) async {
    try {
      debugPrint(
        '🎯 === CALLING POST /api/vaccines/children/$childId/generate-default ===',
      );

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final url = '$_baseUrl/children/$childId/generate-default';
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

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Default vaccines generated successfully',
        };
      } else {
        return {'success': false, 'message': 'Failed to generate vaccines'};
      }
    } catch (e) {
      debugPrint('❌ VaccineService.generateDefaultVaccines error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Add a custom vaccine
  /// Calls: POST /api/vaccines/children/{childId}
  Future<Map<String, dynamic>> addVaccine({
    required int childId,
    required String name,
    required String status,
    String? date,
  }) async {
    try {
      debugPrint('🎯 === CALLING POST /api/vaccines/children/$childId ===');

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final Map<String, dynamic> requestBody = {'name': name, 'status': status};

      if (date != null && date.isNotEmpty) {
        requestBody['date'] = date;
      }

      debugPrint('📤 Request Body: ${json.encode(requestBody)}');

      final response = await http
          .post(
            Uri.parse('$_baseUrl/children/$childId'),
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
        final vaccineData = json.decode(response.body);
        return {
          'success': true,
          'message': 'Vaccine added successfully',
          'data': vaccineData,
        };
      } else {
        return {'success': false, 'message': 'Failed to add vaccine'};
      }
    } catch (e) {
      debugPrint('❌ VaccineService.addVaccine error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Update an existing vaccine
  /// Calls: PUT /api/vaccines/{vaccineId}
  Future<Map<String, dynamic>> updateVaccine({
    required int vaccineId,
    required String name,
    required String status,
    String? date,
    int? childId,
  }) async {
    try {
      debugPrint('🎯 === CALLING PUT /api/vaccines/$vaccineId ===');

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final Map<String, dynamic> requestBody = {'name': name, 'status': status};

      if (date != null && date.isNotEmpty) {
        requestBody['date'] = date;
      }

      if (childId != null) {
        requestBody['childId'] = childId;
      }

      debugPrint('📤 Request Body: ${json.encode(requestBody)}');

      final response = await http
          .put(
            Uri.parse('$_baseUrl/$vaccineId'),
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
        final vaccineData = json.decode(response.body);
        return {
          'success': true,
          'message': 'Vaccine updated successfully',
          'data': vaccineData,
        };
      } else {
        return {'success': false, 'message': 'Failed to update vaccine'};
      }
    } catch (e) {
      debugPrint('❌ VaccineService.updateVaccine error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Delete a vaccine
  /// Calls: DELETE /api/vaccines/{vaccineId}
  Future<Map<String, dynamic>> deleteVaccine(int vaccineId) async {
    try {
      debugPrint('🎯 === CALLING DELETE /api/vaccines/$vaccineId ===');

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final response = await http
          .delete(
            Uri.parse('$_baseUrl/$vaccineId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 204 || response.statusCode == 200) {
        return {'success': true, 'message': 'Vaccine deleted successfully'};
      } else {
        return {'success': false, 'message': 'Failed to delete vaccine'};
      }
    } catch (e) {
      debugPrint('❌ VaccineService.deleteVaccine error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Get status color based on vaccine status
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF4CAF50); // Green
      case 'due':
        return const Color(0xFFF57C00); // Orange
      case 'overdue':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }
}
