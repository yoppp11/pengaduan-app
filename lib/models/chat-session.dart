import 'package:cloud_firestore/cloud_firestore.dart';

class ChatSession {
  final String chatId;
  final String userId;
  final String adminId;
  final String lastMessage;
  final Timestamp lastMessageTimestamp;

  ChatSession({
    required this.chatId,
    required this.userId,
    required this.adminId,
    required this.lastMessage,
    required this.lastMessageTimestamp,
  });

  factory ChatSession.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ChatSession(
      chatId: doc.id,
      userId: data['participants']['userId'],
      adminId: data['participants']['adminId'],
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTimestamp: data['lastMessageTimestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': {
        'userId': userId,
        'adminId': adminId,
      },
      'lastMessage': lastMessage,
      'lastMessageTimestamp': lastMessageTimestamp,
    };
  }
}