import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String senderId;
  final String receiverId;
  final String message;
  final Timestamp timestamp;
  final bool isRead;

  ChatMessage({
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      senderId: data['senderId'],
      receiverId: data['receiverId'],
      message: data['message'],
      timestamp: data['timestamp'],
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }
}