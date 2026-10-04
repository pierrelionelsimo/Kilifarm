import '../models/comment_model.dart';

abstract class CommentRepository {
  Stream<List<CommentModel>> watchComments(String postId);

  Future<void> addComment({
    required String postId,
    required String userId,
    required String userName,
    String? userProfileImage,
    required String content,
  });

  /// Supprime un commentaire et décrémente le compteur du post,
  /// symétrique à addComment.
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  });
}
