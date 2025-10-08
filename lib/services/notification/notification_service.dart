import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/notification_model.dart';
import '../auth/auth_service.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Base API URL matching backend structure
  static const String _baseUrl = 'http://10.0.2.2:8080/api/notifications';

  // Notification storage
  final List<NotificationModel> _notifications = [];
  final StreamController<NotificationModel> _notificationStreamController =
      StreamController<NotificationModel>.broadcast();

  // Polling timer for periodic refresh
  Timer? _pollingTimer;
  bool _isInitialized = false;

  // Getters
  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  Stream<NotificationModel> get notificationStream =>
      _notificationStreamController.stream;
  bool get isConnected => _isInitialized;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Initialize the service - automatically gets auth info
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('🔔 NotificationService already initialized');
      return;
    }

    debugPrint('🔔 Initializing NotificationService...');

    // Load notifications from backend API
    await _loadNotifications();

    // Start periodic refresh every 30 seconds
    _startPolling();

    _isInitialized = true;
    debugPrint('✅ NotificationService initialized successfully');
    notifyListeners();
  }

  /// Refresh notifications manually - can be called even if already initialized
  Future<void> refresh() async {
    debugPrint('🔄 Manually refreshing notifications...');
    await _loadNotifications();
    debugPrint('✅ Manual refresh completed');
  }

  /// Start periodic polling for new notifications
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      debugPrint('🔄 Polling for notifications...');
      _loadNotifications();
    });
  }

  /// Get authentication headers for API calls
  Future<Map<String, String>?> _getAuthHeaders() async {
    try {
      final authService = AuthService();
      final token = await authService.getToken();

      if (token == null) {
        debugPrint('❌ No auth token available');
        return null;
      }

      return {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
    } catch (e) {
      debugPrint('❌ Error getting auth headers: $e');
      return null;
    }
  }

  /// Get parent ID from auth service
  Future<String?> _getParentId() async {
    try {
      final authService = AuthService();
      final profile = await authService.getCompleteUserProfile();
      return profile?['id']?.toString();
    } catch (e) {
      debugPrint('❌ Error getting parent ID: $e');
      return null;
    }
  }

  /// Load notifications from backend API - matches backend endpoint exactly
  Future<void> _loadNotifications() async {
    try {
      final headers = await _getAuthHeaders();
      final parentId = await _getParentId();

      if (headers == null || parentId == null) {
        debugPrint('❌ Cannot load notifications: missing auth info');
        return;
      }

      debugPrint('🔍 Loading notifications for parent ID: $parentId');

      // Use the exact backend endpoint: GET /api/notifications/{parentId}
      final url = '$_baseUrl/$parentId';
      debugPrint('🔍 API endpoint: $url');

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('📡 Response Status: ${response.statusCode}');
      debugPrint('📡 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);

        _notifications.clear();

        for (var jsonItem in jsonList) {
          try {
            final notification = NotificationModel.fromJson(jsonItem);
            _notifications.add(notification);
          } catch (e) {
            debugPrint('❌ Error parsing notification: $jsonItem, Error: $e');
          }
        }

        // Sort by creation time (newest first)
        _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        debugPrint('✅ Loaded ${_notifications.length} notifications');
        notifyListeners();
      } else {
        debugPrint(
          '❌ Failed to load notifications: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading notifications: $e');
    }
  }

  /// Get notifications filtered by type
  List<NotificationModel> getNotificationsByType(NotificationTypeApi? type) {
    if (type == null) return notifications;
    return notifications.where((n) => n.type == type).toList();
  }

  /// Get unread notifications
  List<NotificationModel> getUnreadNotifications() {
    return notifications.where((n) => !n.isRead).toList();
  }

  /// Mark notification as read - matches backend endpoint exactly
  Future<void> markAsRead(String notificationId) async {
    try {
      final headers = await _getAuthHeaders();
      if (headers == null) {
        debugPrint('❌ Cannot mark as read: missing auth info');
        return;
      }

      // Update locally first for immediate UI feedback
      final notification = _notifications.firstWhere(
        (n) => n.id == notificationId,
        orElse: () => throw Exception('Notification not found'),
      );

      notification.isRead = true;
      notifyListeners();

      // Use the exact backend endpoint: PUT /api/notifications/{id}/read
      final url = '$_baseUrl/$notificationId/read';
      debugPrint('🔍 Mark as read endpoint: $url');

      final response = await http
          .put(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('📡 Mark as read response: ${response.statusCode}');

      if (response.statusCode != 200) {
        // Revert local change if server update fails
        notification.isRead = false;
        notifyListeners();
        debugPrint(
          '❌ Failed to mark notification as read on server: ${response.statusCode}',
        );
      } else {
        debugPrint('✅ Notification marked as read successfully');
      }
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
    }
  }

  /// Send a notification (for testing) - matches backend endpoint
  Future<void> sendNotification(
    String message,
    NotificationTypeApi type,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      if (headers == null) {
        debugPrint('❌ Cannot send notification: missing auth info');
        return;
      }

      // Use the exact backend endpoint: POST /api/notifications/send
      const url = '$_baseUrl/send';
      debugPrint('🔍 Send notification endpoint: $url');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Authorization': headers['Authorization']!,
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {'message': message, 'type': type.name.toUpperCase()},
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('📡 Send notification response: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ Notification sent successfully');
        // Refresh notifications to get the new one
        await _loadNotifications();
      } else {
        debugPrint(
          '❌ Failed to send notification: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
    }
  }

  /// Refresh notifications from server
  Future<void> refreshNotifications() async {
    await _loadNotifications();
  }

  /// Get priority level based on notification type
  static NotificationPriority getPriorityForType(NotificationTypeApi type) {
    switch (type) {
      case NotificationTypeApi.urgent:
      case NotificationTypeApi.medical:
        return NotificationPriority.high;
      case NotificationTypeApi.growth:
      case NotificationTypeApi.educational:
        return NotificationPriority.medium;
      case NotificationTypeApi.meal:
      case NotificationTypeApi.general:
        return NotificationPriority.low;
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    _pollingTimer?.cancel();
    _notificationStreamController.close();
    super.dispose();
  }
}
