import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

abstract class PostRepository {
  Future<void> createPost({
    required String userId,
    required String userName,
    String? userProfileImage,
    required String content,
    required List<File> images,
  });

  /// NOTE assumée : le curseur de pagination reste typé DocumentSnapshot
  /// (type Firestore), pas un type générique abstrait — simplification
  /// volontaire tant qu'il n'existe qu'une seule implémentation.
  Future<({List<PostModel> posts, DocumentSnapshot? lastDoc})> fetchPosts({
    DocumentSnapshot? startAfter,
    String? currentUserId,
  });

  Future<void> toggleLike({required String postId, required String userId});

  Future<void> deletePost(String postId);
}
