import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdAt,
  });

  factory MessageModel.fromMap(String id, Map<String, dynamic> map) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      content: map['content'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'createdAt': createdAt,
    };
  }
}
