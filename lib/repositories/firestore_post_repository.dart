import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../config/constants.dart';
import 'media_repository.dart';
import 'post_repository.dart';

class FirestorePostRepository implements PostRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Injecté par le constructeur : FirestorePostRepository ne sait pas
  // QUI héberge les images (Cloudinary aujourd'hui), seulement QUE
  // quelque chose implémentant MediaRepository peut le faire. C'est
  // exactement ce qui aurait rendu le swap Storage→Cloudinary invisible
  // à ce niveau si cette couche avait existé avant.
  final MediaRepository _mediaRepository;

  FirestorePostRepository({required MediaRepository mediaRepository})
      : _mediaRepository = mediaRepository;

  @override
  Future<void> createPost({
    required String userId,
    required String userName,
    String? userProfileImage,
    required String content,
    required List<File> images,
  }) async {
    final docRef = _firestore.collection(AppConstants.postsCollection).doc();

    final imageUrls = images.isEmpty
        ? <String>[]
        : await _mediaRepository.uploadImages(images);

    final post = PostModel(
      id: docRef.id,
      userId: userId,
      userName: userName,
      userProfileImage: userProfileImage,
      content: content,
      imageUrls: imageUrls,
      createdAt: DateTime.now(),
    );

    await docRef.set(post.toMap());
  }

  @override
  Future<({List<PostModel> posts, DocumentSnapshot? lastDoc})> fetchPosts({
    DocumentSnapshot? startAfter,
    String? currentUserId,
  }) async {
    Query query = _firestore
        .collection(AppConstants.postsCollection)
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.pageSize);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final posts = <PostModel>[];

    for (final doc in snapshot.docs) {
      final base = PostModel.fromMap(doc.data() as Map<String, dynamic>);

      bool likedByMe = false;
      if (currentUserId != null) {
        final likeDoc = await _firestore
            .collection(AppConstants.postsCollection)
            .doc(base.id)
            .collection('likes')
            .doc(currentUserId)
            .get();
        likedByMe = likeDoc.exists;
      }

      posts.add(PostModel(
        id: base.id,
        userId: base.userId,
        userName: base.userName,
        userProfileImage: base.userProfileImage,
        content: base.content,
        imageUrls: base.imageUrls,
        createdAt: base.createdAt,
        likesCount: base.likesCount,
        commentsCount: base.commentsCount,
        isLikedByMe: likedByMe,
      ));
    }

    return (
      posts: posts,
      lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    );
  }

  @override
  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    final postRef =
        _firestore.collection(AppConstants.postsCollection).doc(postId);
    final likeRef = postRef.collection('likes').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final likeSnap = await transaction.get(likeRef);
      final postSnap = await transaction.get(postRef);
      if (!postSnap.exists) return;

      final currentLikes = (postSnap.data()?['likesCount'] as int?) ?? 0;

      if (likeSnap.exists) {
        transaction.delete(likeRef);
        transaction.update(
            postRef, {'likesCount': currentLikes > 0 ? currentLikes - 1 : 0});
      } else {
        transaction.set(likeRef, {
          'userId': userId,
          'likedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(postRef, {'likesCount': currentLikes + 1});
      }
    });
  }

  @override
  Future<void> deletePost(String postId) async {
    await _firestore.collection(AppConstants.postsCollection).doc(postId).delete();
  }
}
