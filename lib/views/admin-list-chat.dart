import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pengaduan/models/chat-session.dart';
import 'package:pengaduan/views/chat-screen.dart';

class AdminChatListScreen extends StatefulWidget {
  const AdminChatListScreen({Key? key}) : super(key: key);

  @override
  State<AdminChatListScreen> createState() => _AdminChatListScreenState();
}

class _AdminChatListScreenState extends State<AdminChatListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final String adminUid =
      'Qv99NkMCMwb0NbOHlYZJt4e2sN32'; 

  @override
  Widget build(BuildContext context) {
    if (_auth.currentUser?.uid != adminUid) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chat Admin'),
          backgroundColor: const Color(0xFFE91E63),
        ),
        body: const Center(
          child: Text('You are not authorized to view this page.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daftar Chat Pengguna',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFE91E63),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('chats')
            .where('participants.adminId', isEqualTo: adminUid)
            .orderBy('lastMessageTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada chat.'));
          }

          final chatSessions = snapshot.data!.docs
              .map((doc) => ChatSession.fromFirestore(doc))
              .toList();

          return ListView.builder(
            itemCount: chatSessions.length,
            itemBuilder: (context, index) {
              final chatSession = chatSessions[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE91E63),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    'Chat dengan Pengguna ID: ${chatSession.userId}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    chatSession.lastMessage.isEmpty
                        ? 'Mulai percakapan baru'
                        : chatSession.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    '${chatSession.lastMessageTimestamp.toDate().hour}:${chatSession.lastMessageTimestamp.toDate().minute}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          chatSession: chatSession,
                          isAdmin: true,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
