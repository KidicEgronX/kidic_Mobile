import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kidicapp_flutter/services/auth/auth_service.dart';
import 'package:kidicapp_flutter/services/child/child_service.dart';
import 'package:kidicapp_flutter/services/ai/chatbot_sync_service.dart';

class ChatbotService {
  final AuthService _authService = AuthService();
  final ChildService _childService = ChildService();
  final ChatbotSyncService _syncService = ChatbotSyncService();

  // Chatbot API endpoint
  // For Android Emulator: use 10.0.2.2 (special alias for host machine's localhost)
  // For iOS Simulator: use 127.0.0.1
  // For Physical Device: use your computer's IP address (e.g., 192.168.1.x)
  static const String _baseUrl = 'http://10.0.2.2:8000/api';

  Future<Map<String, dynamic>> sendMessage({
    required String userMessage,
    List<int>? selectedChildrenIds,
  }) async {
    try {
      debugPrint('🤖 === PREPARING CHATBOT MESSAGE ===');
      debugPrint('👤 User Message: $userMessage');

      final parentProfile = await _authService.getCompleteUserProfile();
      if (parentProfile == null) {
        return {
          'success': false,
          'error': 'Unable to load parent information. Please log in.',
          'response': '',
        };
      }

      final userId = parentProfile['id'] as int?;
      if (userId == null) {
        return {
          'success': false,
          'error': 'User ID not found.',
          'response': '',
        };
      }

      // Sync user data with chatbot backend before sending message
      final syncSuccess = await _syncService.syncUserDataWithChatbot();
      if (!syncSuccess) {
        debugPrint('⚠️ Warning: Could not sync user data with chatbot');
      }

      final chatRequest = {'user_id': userId, 'message': userMessage.trim()};

      debugPrint('📤 Sending to: $_baseUrl/chat');

      final response = await http
          .post(
            Uri.parse('$_baseUrl/chat'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(chatRequest),
          )
          .timeout(const Duration(seconds: 60));

      debugPrint('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'response': responseData['answer'] ?? 'No response from chatbot',
          'confidence': 0.9,
          'suggestions': _generateSuggestions(userMessage.toLowerCase()),
        };
      } else {
        return {
          'success': false,
          'error': 'Chatbot unavailable (${response.statusCode})',
          'response': '',
        };
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      String errorMessage = 'Failed to send message: $e';
      if (e.toString().contains('SocketException')) {
        errorMessage =
            'Cannot connect to chatbot server. Make sure it\'s running on http://127.0.0.1:8000';
      }
      return {'success': false, 'error': errorMessage, 'response': ''};
    }
  }

  List<String> _generateSuggestions(String message) {
    if (message.contains('fever')) {
      return [
        "When should I be concerned about fever?",
        "How to comfort a child with fever?",
        "What temperature is too high?",
      ];
    } else if (message.contains('feeding')) {
      return [
        "Age-appropriate portion sizes",
        "Introducing new foods safely",
        "Dealing with picky eating",
      ];
    } else if (message.contains('sleep')) {
      return [
        "Creating a bedtime routine",
        "Handling sleep regressions",
        "Safe sleep practices",
      ];
    } else {
      return [
        "Child development milestones",
        "Vaccination schedules",
        "Nutrition guidelines",
        "Safety tips",
      ];
    }
  }

  Future<List<Map<String, dynamic>>> getChatHistory() async {
    debugPrint('📚 Getting chat history (not implemented yet)');
    return [];
  }

  Future<bool> clearChatHistory() async {
    debugPrint('🗑️ Clearing chat history (not implemented yet)');
    return true;
  }

  Future<List<Map<String, dynamic>>> getAvailableChildren() async {
    try {
      final children = await _childService.getAllChildren();
      return children
          .map(
            (child) => {
              'id': child['id'],
              'name': child['name'],
              'age': child['age'],
              'genderDisplay': child['genderDisplay'],
            },
          )
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting available children: $e');
      return [];
    }
  }

  Map<String, String> validateMessage(String message) {
    final errors = <String, String>{};
    if (message.trim().isEmpty) {
      errors['message'] = 'Message cannot be empty';
    } else if (message.trim().length < 3) {
      errors['message'] = 'Message must be at least 3 characters';
    } else if (message.trim().length > 1000) {
      errors['message'] = 'Message must be less than 1000 characters';
    }
    return errors;
  }
}
