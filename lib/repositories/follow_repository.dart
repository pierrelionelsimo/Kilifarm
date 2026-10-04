import '../models/user_model.dart';

/// Contrat pour le système d'abonnement (suivre/ne plus suivre un
/// utilisateur). Même principe que les autres repositories : les
/// écrans ne connaissent que ce contrat, jamais Firestore directement.
abstract class FollowRepository {
  /// Bascule l'abonnement de [currentUserId] envers [targetUserId].
  /// Retourne `true` si on suit maintenant cette personne, `false` sinon.
  Future<bool> toggleFollow({
    required String currentUserId,
    required String targetUserId,
  });

  /// Indique si [currentUserId] suit déjà [targetUserId].
  Future<bool> isFollowing({
    required String currentUserId,
    required String targetUserId,
  });

  /// Utilisateurs qui suivent [userId].
  Future<List<UserModel>> getFollowers(String userId);

  /// Utilisateurs que [userId] suit.
  Future<List<UserModel>> getFollowing(String userId);
}
