import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pengaduan/models/chat-session.dart';

import '../models/chat-message.dart';

class ChatScreen extends StatefulWidget {
  final ChatSession? chatSession; // Nullable for new chats (user initiated)
  final String?
      peerId; // Required if starting a new chat (admin UID for user, user UID for admin)
  final bool isAdmin; // To differentiate between user and admin view

  const ChatScreen({
    Key? key,
    this.chatSession,
    this.peerId,
    this.isAdmin = false,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  late String _currentUserId;
  String? _chatId;
  String? _peerId; // The ID of the person you are chatting with (admin or user)

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser!.uid;

    if (widget.chatSession != null) {
      _chatId = widget.chatSession!.chatId;
      _peerId = widget.isAdmin
          ? widget.chatSession!.userId
          : widget.chatSession!.adminId;
    } else if (widget.peerId != null) {
      _peerId = widget.peerId;
      _findOrCreateChatSession();
    } else {
      // This case should ideally not happen if navigation is set up correctly
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(
            context); // Go back if no chat session or peer ID is provided
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not start chat. Invalid parameters.')),
        );
      });
    }
  }

  Future<void> _findOrCreateChatSession() async {
    // For a user initiating a chat, peerId will be the admin's UID.
    // For an admin clicking a user's chat, chatSession will be provided.
    // This logic is mostly for the user's first chat with admin.

    if (_peerId == null) return; // Should not happen

    String user1 = _currentUserId;
    String user2 = _peerId!;

    // Create a unique chat ID based on sorted UIDs
    List<String> participants = [user1, user2];
    participants.sort(); // Ensure consistent order
    String tempChatId = '${participants[0]}_${participants[1]}';

    final chatDoc = _firestore.collection('chats').doc(tempChatId);
    final docSnapshot = await chatDoc.get();

    if (docSnapshot.exists) {
      setState(() {
        _chatId = tempChatId;
      });
    } else {
      // Create new chat session
      await chatDoc.set({
        'participants': {
          'userId': widget.isAdmin ? _peerId : _currentUserId,
          'adminId': widget.isAdmin ? _currentUserId : _peerId,
        },
        'lastMessage': '',
        'lastMessageTimestamp': Timestamp.now(),
      });
      setState(() {
        _chatId = tempChatId;
      });
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty ||
        _chatId == null ||
        _peerId == null) {
      return;
    }

    final messageText = _messageController.text.trim();
    _messageController.clear();

    final messageDocRef = _firestore
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .doc(); // Let Firestore generate ID

    final chatMessage = ChatMessage(
      senderId: _currentUserId,
      receiverId: _peerId!,
      message: messageText,
      timestamp: Timestamp.now(),
      isRead: false,
    );

    await messageDocRef.set(chatMessage.toMap());

    // Update last message in chat session
    await _firestore.collection('chats').doc(_chatId).update({
      'lastMessage': messageText,
      'lastMessageTimestamp': Timestamp.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_chatId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Loading Chat...',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFFE91E63),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isAdmin
              ? 'Chat dengan Pengguna ID: $_peerId'
              : 'Chat dengan Admin',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFE91E63),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Kirim pesan pertama Anda!'));
                }

                final messages = snapshot.data!.docs
                    .map((doc) => ChatMessage.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isCurrentUser = message.senderId == _currentUserId;
                    return Align(
                      alignment: isCurrentUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          color: isCurrentUser
                              ? const Color(0xFFE91E63)
                              : Colors.grey[300],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: isCurrentUser
                                ? const Radius.circular(12)
                                : const Radius.circular(0),
                            bottomRight: isCurrentUser
                                ? const Radius.circular(0)
                                : const Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: isCurrentUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.message,
                              style: TextStyle(
                                color:
                                    isCurrentUser ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${message.timestamp.toDate().hour}:${message.timestamp.toDate().minute}',
                              style: TextStyle(
                                color: isCurrentUser
                                    ? Colors.white70
                                    : Colors.black54,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ketik pesan...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: const Color(0xFFE91E63),
                  mini: true,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
