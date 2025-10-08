/// Model class for chat messages in the Kidic AI chatbot
class ChatMessage {
  final String id;
  final String message;
  final String response;
  final DateTime timestamp;
  final bool isFromUser;
  final bool isLoading;
  final double confidence;
  final List<String> suggestions;
  final Map<String, dynamic>? contextUsed;
  final String? error;

  ChatMessage({
    required this.id,
    required this.message,
    this.response = '',
    required this.timestamp,
    required this.isFromUser,
    this.isLoading = false,
    this.confidence = 1.0,
    this.suggestions = const [],
    this.contextUsed,
    this.error,
  });

  /// Create a user message
  factory ChatMessage.user({
    required String id,
    required String message,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id,
      message: message,
      timestamp: timestamp ?? DateTime.now(),
      isFromUser: true,
      isLoading: false,
    );
  }

  /// Create a loading message (while waiting for AI response)
  factory ChatMessage.loading({
    required String id,
    required String userMessage,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id,
      message: userMessage,
      timestamp: timestamp ?? DateTime.now(),
      isFromUser: false,
      isLoading: true,
    );
  }

  /// Create an AI response message
  factory ChatMessage.aiResponse({
    required String id,
    required String userMessage,
    required String response,
    DateTime? timestamp,
    double confidence = 1.0,
    List<String> suggestions = const [],
    Map<String, dynamic>? contextUsed,
  }) {
    return ChatMessage(
      id: id,
      message: userMessage,
      response: response,
      timestamp: timestamp ?? DateTime.now(),
      isFromUser: false,
      isLoading: false,
      confidence: confidence,
      suggestions: suggestions,
      contextUsed: contextUsed,
    );
  }

  /// Create an error message
  factory ChatMessage.error({
    required String id,
    required String userMessage,
    required String error,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id,
      message: userMessage,
      response: '',
      timestamp: timestamp ?? DateTime.now(),
      isFromUser: false,
      isLoading: false,
      error: error,
    );
  }

  /// Copy message with updated properties
  ChatMessage copyWith({
    String? id,
    String? message,
    String? response,
    DateTime? timestamp,
    bool? isFromUser,
    bool? isLoading,
    double? confidence,
    List<String>? suggestions,
    Map<String, dynamic>? contextUsed,
    String? error,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      message: message ?? this.message,
      response: response ?? this.response,
      timestamp: timestamp ?? this.timestamp,
      isFromUser: isFromUser ?? this.isFromUser,
      isLoading: isLoading ?? this.isLoading,
      confidence: confidence ?? this.confidence,
      suggestions: suggestions ?? this.suggestions,
      contextUsed: contextUsed ?? this.contextUsed,
      error: error ?? this.error,
    );
  }

  /// Convert to JSON (for potential storage or API calls)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'response': response,
      'timestamp': timestamp.toIso8601String(),
      'isFromUser': isFromUser,
      'isLoading': isLoading,
      'confidence': confidence,
      'suggestions': suggestions,
      'contextUsed': contextUsed,
      'error': error,
    };
  }

  /// Create from JSON (for potential storage or API calls)
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      message: json['message'] as String,
      response: json['response'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      isFromUser: json['isFromUser'] as bool,
      isLoading: json['isLoading'] as bool? ?? false,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      suggestions: List<String>.from(json['suggestions'] as List? ?? []),
      contextUsed: json['contextUsed'] as Map<String, dynamic>?,
      error: json['error'] as String?,
    );
  }

  /// Check if message has an error
  bool get hasError => error != null && error!.isNotEmpty;

  /// Check if message is complete (has response and not loading)
  bool get isComplete => !isLoading && response.isNotEmpty && !hasError;

  /// Get formatted timestamp for display
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Get confidence percentage as string
  String get confidencePercentage {
    return '${(confidence * 100).round()}%';
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, isFromUser: $isFromUser, isLoading: $isLoading, hasError: $hasError, message: ${message.length > 50 ? '${message.substring(0, 50)}...' : message})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Model for child selection in chatbot context
class ChildSelection {
  final int id;
  final String name;
  final String age;
  final String genderDisplay;
  final bool isSelected;

  ChildSelection({
    required this.id,
    required this.name,
    required this.age,
    required this.genderDisplay,
    this.isSelected = false,
  });

  ChildSelection copyWith({bool? isSelected}) {
    return ChildSelection(
      id: id,
      name: name,
      age: age,
      genderDisplay: genderDisplay,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'genderDisplay': genderDisplay,
      'isSelected': isSelected,
    };
  }

  factory ChildSelection.fromJson(Map<String, dynamic> json) {
    return ChildSelection(
      id: json['id'] as int,
      name: json['name'] as String,
      age: json['age'] as String,
      genderDisplay: json['genderDisplay'] as String,
      isSelected: json['isSelected'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'ChildSelection(id: $id, name: $name, age: $age, isSelected: $isSelected)';
  }
}
