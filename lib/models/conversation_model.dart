import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String? lastSenderId;
  final Map<String, dynamic> lastReadAt; // uid -> Timestamp

  ConversationModel({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.lastMessage,
    this.lastMessageAt,
    this.lastSenderId,
    this.lastReadAt = const {},
  });

  factory ConversationModel.fromMap(String id, Map<String, dynamic> map) {
    return ConversationModel(
      id: id,
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participantNames:
          Map<String, String>.from(map['participantNames'] ?? {}),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageAt: map['lastMessageAt'] is Timestamp
          ? (map['lastMessageAt'] as Timestamp).toDate()
          : null,
      lastSenderId: map['lastSenderId'],
      lastReadAt: Map<String, dynamic>.from(map['lastReadAt'] ?? {}),
    );
  }

  String otherParticipantId(String currentUserId) {
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  String otherParticipantName(String currentUserId) {
    return participantNames[otherParticipantId(currentUserId)] ?? 'Utilisateur';
  }

  /// Non lu = le dernier message n'est pas de moi, ET il est plus récent
  /// que la dernière fois où j'ai ouvert cette conversation.
  bool isUnread(String currentUserId) {
    if (lastSenderId == null || lastSenderId == currentUserId) return false;
    if (lastMessageAt == null) return false;

    final readValue = lastReadAt[currentUserId];
    if (readValue == null || readValue is! Timestamp) return true;

    return lastMessageAt!.isAfter(readValue.toDate());
  }
}
