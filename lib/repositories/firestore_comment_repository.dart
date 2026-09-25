import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';
import '../config/constants.dart';
import 'comment_repository.dart';

class FirestoreCommentRepository implements CommentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
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

  @override
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
