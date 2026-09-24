import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';
import '../config/constants.dart';

/// Gère les commentaires en sous-collection posts/{postId}/comments,
/// même logique architecturale que les likes (posts/{postId}/likes) :
/// un seul pattern d'accès nécessaire (les commentaires D'UN post),
/// donc pas besoin d'une collection racine avec index composite.
class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Flux temps réel des commentaires d'un post, du plus ancien au
  /// plus récent. Se met à jour automatiquement tant que le panneau
  /// de commentaires reste ouvert (écoute Firestore native).
  Stream<List<CommentModel>> watchComments(String postId) {
    return _firestore
        .collection(AppConstants.postsCollection)
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommentModel.fromMap(doc.data()))
            .toList());
  }

  /// Ajoute un commentaire et incrémente commentsCount sur le post
  /// parent. `FieldValue.increment` est atomique côté serveur : pas
  /// besoin d'une transaction complète comme pour toggleLike, puisqu'on
  /// ne fait qu'incrémenter (pas de bascule like/unlike à gérer ici).
  Future<void> addComment({
    required String postId,
    required String userId,
    required String userName,
    String? userProfileImage,
    required String content,
  }) async {
    final postRef =
        _firestore.collection(AppConstants.postsCollection).doc(postId);
    final commentRef = postRef.collection('comments').doc();

    final comment = CommentModel(
      id: commentRef.id,
      postId: postId,
      userId: userId,
      userName: userName,
      userProfileImage: userProfileImage,
      content: content,
      createdAt: DateTime.now(),
    );

    await commentRef.set(comment.toMap());
    await postRef.update({'commentsCount': FieldValue.increment(1)});
  }
}
