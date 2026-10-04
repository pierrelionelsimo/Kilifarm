import '../models/conversation_model.dart';
import '../models/message_model.dart';

abstract class MessageRepository {
  /// ID déterministe pour une paire d'utilisateurs (toujours le même,
  /// peu importe qui initie la conversation) — évite de créer deux
  /// conversations différentes pour les mêmes deux personnes.
  String conversationIdFor(String uid1, String uid2);

  Stream<List<ConversationModel>> watchConversations(String userId);

  Stream<List<MessageModel>> watchMessages(String conversationId);

  Future<void> sendMessage({
    required String currentUserId,
    required String currentUserName,
    required String otherUserId,
    required String otherUserName,
    required String content,
  });

  Future<void> markAsRead({
    required String conversationId,
    required String userId,
  });

  /// Supprime un message. Ne met pas à jour l'aperçu `lastMessage` de
  /// la conversation si le message supprimé était le dernier — il
  /// resterait affiché jusqu'au prochain message envoyé, simplification
  /// assumée pour ne pas complexifier la suppression.
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  });
}
