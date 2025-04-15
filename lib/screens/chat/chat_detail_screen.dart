import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zhet/models/chat.dart';
import 'package:zhet/services/chat_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatDetailScreen({
    Key? key,
    required this.chatRoom,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  List<Message> _messages = [];
  bool _isLoading = true;
  RealtimeChannel? _channel;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mark messages as read when screen comes into view
    _markMessagesAsRead();
  }

  @override
  void didUpdateWidget(ChatDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Also mark as read when widget updates
    _markMessagesAsRead();
  }

  @override
  void activate() {
    super.activate();
    // Mark as read when screen becomes active again
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    if (_channel != null) {
      _chatService.unsubscribe(_channel!);
    }
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load existing messages
      final messages = await _chatService.getMessages(widget.chatRoom.id);

      // Subscribe to new messages
      _channel = _chatService.subscribeToMessages(
        widget.chatRoom.id,
        (message) {
          if (mounted) {
            setState(() {
              // Check if the message already exists to avoid duplicates
              if (!_messages.any((m) => m.id == message.id)) {
                _messages.add(message);
                // Sort messages by creation time (newest LAST in the list)
                _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
              }
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _messages = messages;
          // Sort messages by creation time (oldest to newest)
          _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          _isLoading = false;
        });

        // Scroll to bottom after initial load
        if (_messages.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    _messageController.clear();

    try {
      // Send the message
      final message = await _chatService.sendMessage(
        widget.chatRoom.id,
        messageText,
      );

      // Update the UI chat room object with the latest message
      if (mounted) {
        setState(() {
          widget.chatRoom.lastMessage = messageText;
          widget.chatRoom.updatedAt = DateTime.now();
        });
      }

      // Add message to the UI immediately instead of waiting for realtime subscription
      if (message != null && mounted) {
        setState(() {
          // Only add if not already in the list (avoid duplicates)
          if (!_messages.any((m) => m.id == message.id)) {
            _messages.add(message);
            // Sort messages to ensure correct order (oldest to newest)
            _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

            // Scroll to bottom after adding new message
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: ${e.toString()}')),
      );
    }
  }

  // ScrollController for the ListView
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0, // Because the list is reversed, 0 is the bottom
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Mark messages as read
  void _markMessagesAsRead() {
    try {
      _chatService.markMessagesAsRead(widget.chatRoom.id);

      // Clear the unread flag on the chat room object
      if (mounted && widget.chatRoom.hasUnreadMessages) {
        setState(() {
          widget.chatRoom.hasUnreadMessages = false;
        });
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.chatRoom.otherUserProfile?.avatarUrl !=
                      null
                  ? NetworkImage(widget.chatRoom.otherUserProfile!.avatarUrl!)
                  : null,
              child: widget.chatRoom.otherUserProfile?.avatarUrl == null
                  ? Text(
                      widget.chatRoom.otherUserProfile?.fullName
                              ?.substring(0, 1) ??
                          '?',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.chatRoom.otherUserProfile?.fullName ?? 'Unknown User',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet. Start a conversation!',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : ListView.builder(
                        reverse: true,
                        controller: _scrollController,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          // When reverse is true, we need to calculate the index
                          // from the end of the list to show newest at bottom
                          final message =
                              _messages[_messages.length - 1 - index];
                          return _buildMessageBubble(message);
                        },
                      ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    return Align(
      alignment:
          message.isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: message.isSentByMe ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: message.isSentByMe ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: message.isSentByMe ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: _sendMessage,
            mini: true,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      // Today, show time only
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      // Different day
      return '${time.day}/${time.month}/${time.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
