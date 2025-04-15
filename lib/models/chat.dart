import 'package:zhet/models/profile.dart';

enum MessageStatus {
  sent,
  delivered,
  read,
}

class Message {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final MessageStatus status;

  // For UI purposes
  final bool isSentByMe;

  Message({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.status,
    required this.isSentByMe,
  });

  factory Message.fromJson(Map<String, dynamic> json, String currentUserId) {
    return Message(
      id: json['id'],
      chatRoomId: json['chat_room_id'],
      senderId: json['sender_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      status: _statusFromString(json['status'] ?? 'sent'),
      isSentByMe: json['sender_id'] == currentUserId,
    );
  }

  static MessageStatus _statusFromString(String status) {
    switch (status) {
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'sent':
      default:
        return MessageStatus.sent;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_room_id': chatRoomId,
      'sender_id': senderId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'status': status.toString().split('.').last,
    };
  }
}

class ChatRoom {
  final String id;
  final String user1Id;
  final String user2Id;
  final DateTime createdAt;
  DateTime updatedAt;
  String? lastMessage;

  // Additional fields for UI
  Profile? otherUserProfile;
  bool hasUnreadMessages = false;
  int unreadCount = 0; // Track the count of unread messages

  ChatRoom({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.otherUserProfile,
    this.hasUnreadMessages = false,
    this.unreadCount = 0,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json, String currentUserId) {
    return ChatRoom(
      id: json['id'],
      user1Id: json['user1_id'],
      user2Id: json['user2_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      lastMessage: json['last_message'],
      hasUnreadMessages: false, // Will be set separately
    );
  }

  String getOtherUserId(String currentUserId) {
    return currentUserId == user1Id ? user2Id : user1Id;
  }

  // Helper to format relative time for UI display
  String getLastMessageTime() {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Just now';
    }
  }
}
