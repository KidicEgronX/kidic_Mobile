import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:kidicapp_flutter/models/chat_message.dart';
import 'package:kidicapp_flutter/services/ai/chatbot_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatbotPage extends StatefulWidget {
  final bool isEmbedded;

  const ChatbotPage({super.key, this.isEmbedded = false});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final ChatbotService _chatbotService = ChatbotService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  List<ChatMessage> _messages = [];
  // Removed: _availableChildren and _showChildSelection - no longer needed
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Removed: _loadAvailableChildren(); - no longer needed
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  /// Add welcome message to chat
  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage.aiResponse(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      userMessage: '',
      response:
          '👋 Hello! I\'m Kidic AI, your personal parenting assistant.\n\n'
          'I have access to your family information and can help with:\n'
          '• Child development questions\n'
          '• Health and wellness guidance\n'
          '• Feeding and nutrition advice\n'
          '• Sleep recommendations\n'
          '• Safety tips\n\n'
          'What would you like to know about your child\'s care today?',
      confidence: 1.0,
      suggestions: [
        'How to handle fever?',
        'Feeding guidelines for toddlers',
        'Sleep routine tips',
        'Development milestones',
      ],
    );

    setState(() {
      _messages.add(welcomeMessage);
    });
  }

  /// Generate unique message ID
  String _generateMessageId() {
    return 'msg_${DateTime.now().microsecondsSinceEpoch}';
  }

  /// Send message to chatbot
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Validate message
    final validationErrors = _chatbotService.validateMessage(message);
    if (validationErrors.isNotEmpty) {
      _showErrorSnackBar(validationErrors.values.first);
      return;
    }

    // Send message without child context (simplified)
    final selectedChildrenIds = <int>[]; // Removed child selection

    final messageId = _generateMessageId();

    // Add user message
    final userMessage = ChatMessage.user(id: messageId, message: message);

    // Add loading message
    final loadingMessage = ChatMessage.loading(
      id: '${messageId}_loading',
      userMessage: message,
    );

    setState(() {
      _messages.addAll([userMessage, loadingMessage]);
      _isLoading = true;
    });

    // Clear input and scroll to bottom
    _messageController.clear();
    _messageFocusNode.unfocus();
    _scrollToBottom();

    try {
      // Send message to chatbot service
      final response = await _chatbotService.sendMessage(
        userMessage: message,
        selectedChildrenIds: selectedChildrenIds.isEmpty
            ? null
            : selectedChildrenIds,
      );

      // Remove loading message
      setState(() {
        _messages.removeWhere((msg) => msg.id == '${messageId}_loading');
        _isLoading = false;
      });

      if (response['success'] == true) {
        // Add successful AI response
        final aiResponse = ChatMessage.aiResponse(
          id: '${messageId}_response',
          userMessage: message,
          response: response['response'] as String,
          confidence: (response['confidence'] as num?)?.toDouble() ?? 1.0,
          suggestions: List<String>.from(response['suggestions'] ?? []),
          contextUsed: response['contextUsed'] as Map<String, dynamic>?,
        );

        setState(() {
          _messages.add(aiResponse);
        });
      } else {
        // Add error message
        final errorMessage = ChatMessage.error(
          id: '${messageId}_error',
          userMessage: message,
          error: response['error'] as String? ?? 'Unknown error occurred',
        );

        setState(() {
          _messages.add(errorMessage);
        });
      }
    } catch (e) {
      // Remove loading message and add error
      setState(() {
        _messages.removeWhere((msg) => msg.id == '${messageId}_loading');
        _isLoading = false;
      });

      final errorMessage = ChatMessage.error(
        id: '${messageId}_error',
        userMessage: message,
        error: 'Failed to get response: $e',
      );

      setState(() {
        _messages.add(errorMessage);
      });
    }

    _scrollToBottom();
  }

  /// Scroll to bottom of chat
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Clear chat history
  Future<void> _clearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text(
          'Are you sure you want to clear all chat messages?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _messages.clear();
      });
      _addWelcomeMessage();
      _showSuccessSnackBar('Chat cleared successfully');
    }
  }

  /// Toggle child selection panel
  // REMOVED: Child selection functionality
  /*
  void _toggleChildSelection() {
    setState(() {
      _showChildSelection = !_showChildSelection;
    });
  }
  */

  /// Toggle individual child selection
  // REMOVED: Child selection methods - no longer needed
  /*
  void _toggleChildSelectionById(int childId) {
    setState(() {
      final index = _availableChildren.indexWhere(
        (child) => child.id == childId,
      );
      if (index != -1) {
        _availableChildren[index] = _availableChildren[index].copyWith(
          isSelected: !_availableChildren[index].isSelected,
        );
      }
    });
  }
  */

  /// Send a suggestion as message
  void _sendSuggestion(String suggestion) {
    _messageController.text = suggestion;
    _sendMessage();
  }

  /// Launch URL from Markdown links
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        _showErrorSnackBar('Could not launch URL: $url');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatContent = Column(
      children: [
        // Chat messages
        Expanded(child: _buildChatMessages()),

        // Message input
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: _buildMessageInput(),
        ),
      ],
    );

    // Return with or without Scaffold based on isEmbedded flag
    if (widget.isEmbedded) {
      return chatContent;
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Custom header matching other pages style
            _buildCustomHeader(),
            // Chat content
            Expanded(child: chatContent),
          ],
        ),
      ),
    );
  }

  /// Build custom header matching other pages style
  Widget _buildCustomHeader() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // AI Assistant icon and title
          Icon(Icons.smart_toy, color: Colors.blue.shade600, size: 28),
          const SizedBox(width: 12),
          const Text(
            'Kidic AI Assistant',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          // Clear chat button
          IconButton(
            onPressed: _clearChat,
            icon: Icon(Icons.delete_outline, color: Colors.blue.shade600),
            tooltip: 'Clear Chat',
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// Build chat messages list
  Widget _buildChatMessages() {
    if (_messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  /// Build individual message bubble
  Widget _buildMessageBubble(ChatMessage message) {
    if (message.isFromUser) {
      return _buildUserMessage(message);
    } else if (message.isLoading) {
      return _buildLoadingMessage();
    } else if (message.hasError) {
      return _buildErrorMessage(message);
    } else {
      return _buildAiMessage(message);
    }
  }

  /// Build user message bubble
  Widget _buildUserMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.message,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.formattedTime,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blue.shade600,
            radius: 16,
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  /// Build AI message bubble
  Widget _buildAiMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.green.shade600,
            radius: 16,
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Markdown content
                      MarkdownBody(
                        data: message.response,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                          h1: TextStyle(
                            color: Colors.black87,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          h2: TextStyle(
                            color: Colors.black87,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          h3: TextStyle(
                            color: Colors.black87,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          code: TextStyle(
                            backgroundColor: Colors.grey.shade200,
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          blockquote: TextStyle(
                            color: Colors.grey.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                          blockquotePadding: const EdgeInsets.all(8),
                          blockquoteDecoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            border: Border(
                              left: BorderSide(
                                color: Colors.blue.shade300,
                                width: 4,
                              ),
                            ),
                          ),
                          listBullet: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                          strong: const TextStyle(fontWeight: FontWeight.bold),
                          em: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                        onTapLink: (text, href, title) {
                          if (href != null) {
                            _launchUrl(href);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            message.formattedTime,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          if (message.confidence < 1.0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                message.confidencePercentage,
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Suggestions
                if (message.suggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Suggestions:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: message.suggestions
                        .map(
                          (suggestion) => GestureDetector(
                            onTap: () => _sendSuggestion(suggestion),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Text(
                                suggestion,
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build loading message
  Widget _buildLoadingMessage() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.orange.shade600,
            radius: 16,
            child: const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Kidic AI is thinking...',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build error message
  Widget _buildErrorMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.red.shade600,
            radius: 16,
            child: const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Error',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.error ?? 'Unknown error occurred',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      _messageController.text = message.message;
                      _sendMessage();
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build message input field
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _messageFocusNode,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Ask about your child\'s care...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.blue.shade600),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onSubmitted: (_) => _sendMessage(),
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _isLoading ? null : _sendMessage,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              tooltip: 'Send Message',
            ),
          ),
        ],
      ),
    );
  }
}
