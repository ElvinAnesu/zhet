import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zhet/config/supabase.dart';
import 'package:zhet/models/chat.dart';
import 'package:zhet/services/profile_service.dart';
import 'package:zhet/models/profile.dart';

class ChatService {
  final _supabase = SupabaseConfig.client;
  final _profileService = ProfileService();

  // Get or create a chat room between current user and another user
  Future<ChatRoom?> getOrCreateChatRoom(String otherUserId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (user.id == otherUserId) {
        throw Exception('Cannot chat with yourself');
      }

      // Sort user IDs to ensure consistent room creation and retrieval
      final List<String> userIds = [user.id, otherUserId]..sort();
      final user1Id = userIds[0];
      final user2Id = userIds[1];

      // Check if a chat between these users already exists
      final existingChats = await _supabase
          .from('chat_rooms')
          .select()
          .eq('user1_id', user1Id)
          .eq('user2_id', user2Id);

      if (existingChats.isNotEmpty) {
        debugPrint('Using existing chat room between users');
        final chatRoom = ChatRoom.fromJson(existingChats[0], user.id);
        await _loadProfileForChatRoom(chatRoom);
        return chatRoom;
      }

      // Create a new chat room with consistent user ordering
      debugPrint('Creating new chat room between users');
      final result = await _supabase.from('chat_rooms').insert({
        'user1_id': user1Id,
        'user2_id': user2Id,
      }).select();

      if (result.isEmpty) {
        throw Exception('Failed to create chat room');
      }

      final chatRoom = ChatRoom.fromJson(result[0], user.id);
      await _loadProfileForChatRoom(chatRoom);
      return chatRoom;
    } catch (e) {
      debugPrint('Error in getOrCreateChatRoom: $e');
      return null;
    }
  }

  // Get all chat rooms for the current user
  Future<List<ChatRoom>> getChatRooms() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final result = await _supabase
          .from('chat_rooms')
          .select()
          .or('user1_id.eq.${user.id},user2_id.eq.${user.id}')
          .order('updated_at', ascending: false);

      final chatRooms = result
          .map<ChatRoom>((json) => ChatRoom.fromJson(json, user.id))
          .toList();

      // Load profiles for the chat rooms
      for (final chatRoom in chatRooms) {
        await _loadProfileForChatRoom(chatRoom);

        // Check for unread messages
        await _checkForUnreadMessages(chatRoom, user.id);
      }

      return chatRooms;
    } catch (e) {
      debugPrint('Error in getChatRooms: $e');
      return [];
    }
  }

  // Helper method to load the other user's profile for a chat room
  Future<void> _loadProfileForChatRoom(ChatRoom chatRoom) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final otherUserId = chatRoom.getOtherUserId(user.id);

      // Get profile from Supabase
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', otherUserId)
          .single();

      chatRoom.otherUserProfile = Profile.fromJson(data);
    } catch (e) {
      debugPrint('Error loading profile for chat room: $e');
    }
  }

  // Helper method to check for unread messages
  Future<void> _checkForUnreadMessages(ChatRoom chatRoom, String userId) async {
    try {
      // Fetch all unread messages for the chat room
      final unreadMessages = await _supabase
          .from('messages')
          .select()
          .eq('chat_room_id', chatRoom.id)
          .neq('sender_id', userId) // Messages sent by others
          .not('status', 'eq', 'read'); // Not yet read

      // Set unread status and count
      chatRoom.hasUnreadMessages = unreadMessages.isNotEmpty;
      chatRoom.unreadCount = unreadMessages.length;

      if (chatRoom.hasUnreadMessages) {
        debugPrint(
            'Chat room ${chatRoom.id} has ${chatRoom.unreadCount} unread messages');
      }
    } catch (e) {
      debugPrint('Error checking for unread messages: $e');
    }
  }

  // Get messages for a specific chat room
  Future<List<Message>> getMessages(String chatRoomId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final result = await _supabase
          .from('messages')
          .select()
          .eq('chat_room_id', chatRoomId)
          .order('created_at');

      final messages = result
          .map<Message>((json) => Message.fromJson(json, user.id))
          .toList();

      // Mark messages as read
      _markMessagesAsRead(chatRoomId, user.id);

      return messages;
    } catch (e) {
      debugPrint('Error in getMessages: $e');
      return [];
    }
  }

  // Send a message
  Future<Message?> sendMessage(String chatRoomId, String content) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Update the chat room first to ensure UI is updated immediately
      await _supabase.from('chat_rooms').update({
        'last_message': content,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', chatRoomId);

      debugPrint('Updated chat room with latest message: $content');

      final result = await _supabase.from('messages').insert({
        'chat_room_id': chatRoomId,
        'sender_id': user.id,
        'content': content,
        'status': 'sent',
      }).select();

      if (result.isEmpty) {
        throw Exception('Failed to send message');
      }

      return Message.fromJson(result[0], user.id);
    } catch (e) {
      debugPrint('Error in sendMessage: $e');
      return null;
    }
  }

  // Mark messages as read
  Future<void> _markMessagesAsRead(String chatRoomId, String userId) async {
    try {
      // Update ALL unread messages (both sent and delivered)
      await _supabase
          .from('messages')
          .update({'status': 'read'})
          .eq('chat_room_id', chatRoomId)
          .neq('sender_id', userId)
          .not('status', 'eq', 'read');

      debugPrint('Marked messages as read in _markMessagesAsRead: $chatRoomId');
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  // Mark messages as delivered
  Future<void> markMessagesAsDelivered(String chatRoomId, String userId) async {
    try {
      await _supabase
          .from('messages')
          .update({'status': 'delivered'})
          .eq('chat_room_id', chatRoomId)
          .neq('sender_id', userId)
          .eq('status', 'sent');
    } catch (e) {
      debugPrint('Error marking messages as delivered: $e');
    }
  }

  // Subscribe to new messages in a chat room
  RealtimeChannel subscribeToMessages(
      String chatRoomId, Function(Message) onNewMessage) {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Create a unique channel name to avoid conflicts
    final channelName =
        'messages:$chatRoomId:${DateTime.now().millisecondsSinceEpoch}';
    final channel = _supabase.channel(channelName);

    // Subscribe to new messages
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'chat_room_id',
        value: chatRoomId,
      ),
      callback: (payload) {
        final message = Message.fromJson(payload.newRecord, user.id);
        onNewMessage(message);

        // Mark as delivered if not sent by the current user
        if (!message.isSentByMe) {
          markMessagesAsDelivered(chatRoomId, user.id);
        }

        // Update the chat room's last message
        _updateChatRoomLastMessage(chatRoomId, message.content);
      },
    );

    channel.subscribe();
    debugPrint('Subscribed to chat channel: $channelName');

    return channel;
  }

  // Update the chat room's last message
  Future<void> _updateChatRoomLastMessage(
      String chatRoomId, String lastMessage) async {
    try {
      await _supabase.from('chat_rooms').update({
        'last_message': lastMessage,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', chatRoomId);

      debugPrint('Chat room last message updated via callback: $lastMessage');
    } catch (e) {
      debugPrint('Error updating chat room last message: $e');
    }
  }

  // Unsubscribe from real-time updates
  void unsubscribe(RealtimeChannel channel) {
    channel.unsubscribe();
  }

  // Public method to mark messages as read
  Future<void> markMessagesAsRead(String chatRoomId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // First mark messages as read in the database (both sent and delivered)
      final updateResult = await _supabase
          .from('messages')
          .update({'status': 'read'})
          .eq('chat_room_id', chatRoomId)
          .neq('sender_id', user.id)
          .not('status', 'eq', 'read');

      debugPrint('Marked messages as read in public method: $chatRoomId');

      // Also update chat_rooms table to help with realtime sync
      await _supabase.from('chat_rooms').update({
        // This helps trigger a realtime update for other clients
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', chatRoomId);
    } catch (e) {
      debugPrint('Error in markMessagesAsRead: $e');
    }
  }
}
