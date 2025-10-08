import 'package:flutter/material.dart';

// Notification types from the API (matching the Java enum)
enum NotificationTypeApi { medical, educational, meal, growth, general, urgent }

// Priority levels for notifications
enum NotificationPriority { high, medium, low }

class NotificationModel {
  final String id;
  final String title;
  final String content;
  final NotificationTypeApi type;
  final DateTime createdAt;
  final String? parentId;
  bool isRead;
  final NotificationPriority priority;

  NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.createdAt,
    this.parentId,
    required this.isRead,
    required this.priority,
  });

  // Create from JSON (API response)
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final typeString = json['type'] as String? ?? 'GENERAL';
    final notificationType = _parseNotificationType(typeString);

    // Generate title from content for better UX
    final content = json['content'] as String? ?? '';
    final title = _generateTitleFromContent(content, notificationType);

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: title,
      content: content,
      type: notificationType,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      parentId: json['parentId']?.toString(),
      isRead: json['isRead'] ?? false,
      priority: _getPriorityForType(notificationType),
    );
  }

  // Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.name.toUpperCase(),
      'createdAt': createdAt.toIso8601String(),
      'parentId': parentId,
      'isRead': isRead,
    };
  }

  // Parse notification type from string
  static NotificationTypeApi _parseNotificationType(String typeString) {
    switch (typeString.toUpperCase()) {
      case 'MEDICAL':
        return NotificationTypeApi.medical;
      case 'EDUCATIONAL':
        return NotificationTypeApi.educational;
      case 'MEAL':
        return NotificationTypeApi.meal;
      case 'GROWTH':
        return NotificationTypeApi.growth;
      case 'URGENT':
        return NotificationTypeApi.urgent;
      case 'GENERAL':
      default:
        return NotificationTypeApi.general;
    }
  }

  // Generate title from content based on type
  static String _generateTitleFromContent(
    String content,
    NotificationTypeApi type,
  ) {
    switch (type) {
      case NotificationTypeApi.medical:
        return 'Health Update';
      case NotificationTypeApi.educational:
        return 'Learning Tip';
      case NotificationTypeApi.meal:
        return 'Meal Reminder';
      case NotificationTypeApi.growth:
        return 'Growth Update';
      case NotificationTypeApi.urgent:
        return '🚨 Urgent Alert';
      case NotificationTypeApi.general:
        return 'Notification';
    }
  }

  // Get priority based on notification type
  static NotificationPriority _getPriorityForType(NotificationTypeApi type) {
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

  // Get icon for notification type
  IconData getIcon() {
    switch (type) {
      case NotificationTypeApi.medical:
        return Icons.medical_services;
      case NotificationTypeApi.educational:
        return Icons.school;
      case NotificationTypeApi.meal:
        return Icons.restaurant;
      case NotificationTypeApi.growth:
        return Icons.trending_up;
      case NotificationTypeApi.urgent:
        return Icons.warning;
      case NotificationTypeApi.general:
        return Icons.notifications;
    }
  }

  // Get color for notification type
  Color getColor() {
    switch (type) {
      case NotificationTypeApi.medical:
        return Colors.orange;
      case NotificationTypeApi.educational:
        return Colors.blue;
      case NotificationTypeApi.meal:
        return Colors.green;
      case NotificationTypeApi.growth:
        return Colors.purple;
      case NotificationTypeApi.urgent:
        return Colors.red;
      case NotificationTypeApi.general:
        return Colors.grey;
    }
  }

  // Get display name for notification type
  String getTypeDisplayName() {
    switch (type) {
      case NotificationTypeApi.medical:
        return 'Health';
      case NotificationTypeApi.educational:
        return 'Education';
      case NotificationTypeApi.meal:
        return 'Meal';
      case NotificationTypeApi.growth:
        return 'Growth';
      case NotificationTypeApi.urgent:
        return 'Urgent';
      case NotificationTypeApi.general:
        return 'General';
    }
  }

  // Get priority color
  Color getPriorityColor() {
    switch (priority) {
      case NotificationPriority.high:
        return Colors.red;
      case NotificationPriority.medium:
        return Colors.orange;
      case NotificationPriority.low:
        return Colors.green;
    }
  }

  // Copy with method for updates
  NotificationModel copyWith({
    String? id,
    String? title,
    String? content,
    NotificationTypeApi? type,
    DateTime? createdAt,
    String? parentId,
    bool? isRead,
    NotificationPriority? priority,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      parentId: parentId ?? this.parentId,
      isRead: isRead ?? this.isRead,
      priority: priority ?? this.priority,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, type: $type, isRead: $isRead, priority: $priority)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
