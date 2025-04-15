import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zhet/models/chat.dart';
import 'package:zhet/services/chat_service.dart';
import 'package:zhet/screens/chat/chat_detail_screen.dart';

class Orders extends StatefulWidget {
  const Orders({super.key});

  @override
  State<Orders> createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  final ChatService _chatService = ChatService();
  List<ChatRoom> _chatRooms = [];
  bool _isLoading = true;
  RealtimeChannel? _chatRoomsChannel;

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
    _subscribeToChatRoomUpdates();
  }

  @override
  void dispose() {
    _unsubscribeFromChatRoomUpdates();
    super.dispose();
  }

  void _subscribeToChatRoomUpdates() {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    _chatRoomsChannel = supabase.channel('public:chat_rooms_and_messages');

    // Listen for chat room updates
    _chatRoomsChannel?.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'chat_rooms',
      callback: (payload) {
        debugPrint('Chat room updated: ${payload.newRecord}');
        _loadChatRooms();
      },
    );

    // Listen for new chat rooms where user is user1
    _chatRoomsChannel?.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'chat_rooms',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user1_id',
        value: user.id,
      ),
      callback: (payload) {
        debugPrint('New chat room where user is user1');
        _loadChatRooms();
      },
    );

    // Listen for new chat rooms where user is user2
    _chatRoomsChannel?.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'chat_rooms',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user2_id',
        value: user.id,
      ),
      callback: (payload) {
        debugPrint('New chat room where user is user2');
        _loadChatRooms();
      },
    );

    // Also listen for new messages as they might affect the last_message of a chat room
    _chatRoomsChannel?.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        debugPrint('New message received, refreshing chat list');
        _loadChatRooms();
      },
    );

    _chatRoomsChannel?.subscribe();
    debugPrint('Subscribed to chat rooms and messages channel');
  }

  void _unsubscribeFromChatRoomUpdates() {
    _chatRoomsChannel?.unsubscribe();
  }

  Future<void> _loadChatRooms() async {
    if (!mounted) return;

    setState(() {
      _isLoading = _chatRooms.isEmpty; // Only show loading on initial load
    });

    try {
      final chatRooms = await _chatService.getChatRooms();
      if (mounted) {
        setState(() {
          _chatRooms = chatRooms;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading chat rooms: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: Text(
            'Orders',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadChatRooms,
            ),
          ],
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _chatRooms.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No conversations yet',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start a chat from the exchange page',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadChatRooms,
                      child: ListView.builder(
                        itemCount: _chatRooms.length,
                        itemBuilder: (context, index) {
                          final chatRoom = _chatRooms[index];
                          final profile = chatRoom.otherUserProfile;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: profile?.avatarUrl != null
                                  ? NetworkImage(profile!.avatarUrl!)
                                  : null,
                              child: profile?.avatarUrl == null
                                  ? Text(
                                      profile?.fullName?.substring(0, 1) ?? '?',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  : null,
                            ),
                            title: Text(
                              profile?.fullName ?? 'Unknown User',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              chatRoom.lastMessage ?? 'Start a conversation',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  chatRoom.getLastMessageTime(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (chatRoom.hasUnreadMessages)
                                  Container(
                                    width: chatRoom.unreadCount > 9 ? 24 : 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.rectangle,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        chatRoom.unreadCount.toString(),
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () async {
                              // Mark all messages as read when entering chat
                              await _chatService
                                  .markMessagesAsRead(chatRoom.id);

                              // Update UI immediately to hide the red dot
                              if (mounted && chatRoom.hasUnreadMessages) {
                                setState(() {
                                  chatRoom.hasUnreadMessages = false;
                                  chatRoom.unreadCount = 0;
                                });
                              }

                              // Navigate to chat detail screen
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatDetailScreen(
                                    chatRoom: chatRoom,
                                  ),
                                ),
                              );

                              // Explicitly reload chat rooms when returning
                              if (mounted) {
                                _loadChatRooms();
                              }
                            },
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
