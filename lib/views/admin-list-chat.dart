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
  final TextEditingController _searchController = TextEditingController();

  final String adminUid = 'Qv99NkMCMwb0NbOHlYZJt4e2sN32';

  String _searchQuery = '';
  Map<String, Map<String, dynamic>> _userCache = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        _userCache[userId] = userData;
        return userData;
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
    return null;
  }

  String _formatTime(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

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
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari berdasarkan nama, email, atau nomor telepon...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE91E63)),
                ),
              ),
            ),
          ),
          // Chat List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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

                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _loadChatSessionsWithUserData(chatSessions),
                  builder: (context, futureSnapshot) {
                    if (futureSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (futureSnapshot.hasError) {
                      return Center(
                          child: Text('Error: ${futureSnapshot.error}'));
                    }

                    if (!futureSnapshot.hasData ||
                        futureSnapshot.data!.isEmpty) {
                      return const Center(
                          child: Text('Belum ada chat dari user.'));
                    }

                    List<Map<String, dynamic>> chatSessionsWithUserData =
                        futureSnapshot.data!;

                    List<Map<String, dynamic>> filteredSessions =
                        chatSessionsWithUserData;
                    if (_searchQuery.isNotEmpty) {
                      filteredSessions = chatSessionsWithUserData.where((item) {
                        final userData =
                            item['userData'] as Map<String, dynamic>?;
                        if (userData != null) {
                          final displayName = userData['displayName']
                                  ?.toString()
                                  .toLowerCase() ??
                              '';
                          final email =
                              userData['email']?.toString().toLowerCase() ?? '';
                          final phoneNumber = userData['phoneNumber']
                                  ?.toString()
                                  .toLowerCase() ??
                              '';

                          return displayName.contains(_searchQuery) ||
                              email.contains(_searchQuery) ||
                              phoneNumber.contains(_searchQuery);
                        }
                        return false;
                      }).toList();
                    }

                    if (filteredSessions.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Belum ada chat dari user.'
                                  : 'Tidak ada hasil untuk "$_searchQuery"',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredSessions.length,
                      itemBuilder: (context, index) {
                        final item = filteredSessions[index];
                        final chatSession = item['chatSession'] as ChatSession;
                        final userData =
                            item['userData'] as Map<String, dynamic>?;

                        final displayName =
                            userData?['displayName'] ?? 'Unknown User';
                        final email = userData?['email'] ?? '';
                        final photoUrl = userData?['photoUrl'];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFE91E63),
                              backgroundImage:
                                  photoUrl != null && photoUrl.isNotEmpty
                                      ? NetworkImage(photoUrl)
                                      : null,
                              child: photoUrl == null || photoUrl.isEmpty
                                  ? const Icon(Icons.person,
                                      color: Colors.white)
                                  : null,
                            ),
                            title: Text(
                              displayName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (email.isNotEmpty)
                                  Text(
                                    email,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  chatSession.lastMessage.isEmpty
                                      ? 'Mulai percakapan baru'
                                      : chatSession.lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            trailing: Text(
                              _formatTime(chatSession.lastMessageTimestamp),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadChatSessionsWithUserData(
      List<ChatSession> chatSessions) async {
    List<Map<String, dynamic>> result = [];

    for (ChatSession chatSession in chatSessions) {
      Map<String, dynamic>? userData = await _getUserData(chatSession.userId);

      if (userData != null && userData['role'] == 'user') {
        result.add({
          'chatSession': chatSession,
          'userData': userData,
        });
      }
    }

    return result;
  }
}
