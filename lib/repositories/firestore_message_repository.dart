import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import 'message_repository.dart';

class FirestoreMessageRepository implements MessageRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  String conversationIdFor(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  @override
  Stream<List<ConversationModel>> watchConversations(String userId) {
    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final conversations = snapshot.docs
          .map((doc) => ConversationModel.fromMap(doc.id, doc.data()))
          .toList();

      // Tri côté client (pas orderBy() Firestore) : combiner where +
      // orderBy sur des champs différents exigerait un index composite.
      conversations.sort((a, b) {
        final aTime = a.lastMessageAt ?? DateTime(2000);
        final bTime = b.lastMessageAt ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });

      return conversations;
    });
  }

  @override
  Stream<List<MessageModel>> watchMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Future<void> sendMessage({
    required String currentUserId,
    required String currentUserName,
    required String otherUserId,
    required String otherUserName,
    required String content,
  }) async {
    final conversationId = conversationIdFor(currentUserId, otherUserId);
    final conversationRef =
        _firestore.collection('conversations').doc(conversationId);

    // set + merge : crée la conversation au premier message, met juste
    // à jour les champs "dernier message" ensuite — même doc, pas de
    // vérif explicite d'existence nécessaire côté client.
    await conversationRef.set({
      'participantIds': [currentUserId, otherUserId],
      'participantNames': {
        currentUserId: currentUserName,
        otherUserId: otherUserName,
      },
      'lastMessage': content,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderId': currentUserId,
    }, SetOptions(merge: true));

    final messageRef = conversationRef.collection('messages').doc();
    await messageRef.set(MessageModel(
      id: messageRef.id,
      senderId: currentUserId,
      senderName: currentUserName,
      content: content,
      createdAt: DateTime.now(),
    ).toMap()
      ..['createdAt'] = FieldValue.serverTimestamp());
  }

  @override
  Future<void> markAsRead({
    required String conversationId,
    required String userId,
  }) async {
    await _firestore.collection('conversations').doc(conversationId).update({
      'lastReadAt.$userId': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }
}
