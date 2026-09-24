import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../config/constants.dart';
import 'cloudinary_service.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinary = CloudinaryService();

  /// Crée une publication. Les images sont uploadées vers Cloudinary
  /// AVANT l'écriture Firestore : si l'upload échoue, on ne crée pas
  /// un post avec des URLs manquantes.
  Future<void> createPost({
    required String userId,
    required String userName,
    String? userProfileImage,
    required String content,
    required List<File> images,
  }) async {
    final docRef = _firestore.collection(AppConstants.postsCollection).doc();

    final imageUrls =
        images.isEmpty ? <String>[] : await _cloudinary.uploadImages(images);

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

  /// Récupère une page de publications, triées des plus récentes aux
  /// plus anciennes. Passe `startAfter` (dernier document de la page
  /// précédente) pour paginer. Si `currentUserId` est fourni, vérifie
  /// pour chaque post si cet utilisateur l'a déjà aimé (isLikedByMe).
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

  /// Ajoute ou retire le like d'un utilisateur sur une publication.
  /// Utilise une transaction Firestore pour garder `likesCount`
  /// toujours exact, même avec plusieurs utilisateurs simultanés.
  /// Le like lui-même est stocké comme document dans la sous-collection
  /// `posts/{postId}/likes/{userId}` — son existence = "a aimé".
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

      final currentLikes =
          (postSnap.data()?['likesCount'] as int?) ?? 0;

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

  /// Supprime une publication. Note technique : Firestore ne supprime
  /// PAS automatiquement les sous-collections (ex: /likes) d'un document
  /// supprimé — elles restent orphelines. Négligeable à l'échelle V1
  /// (quelques documents vides, aucun coût réel), mais à garder en tête
  /// si le volume grossit un jour. Même chose pour les images restées
  /// sur Cloudinary : leur suppression nécessite un appel signé (clé
  /// secrète), qu'on ne peut pas faire depuis l'app cliente sans risquer
  /// de l'exposer — accepté comme dette technique V1, largement dans les
  /// limites du plan gratuit (25 Go).
  Future<void> deletePost(String postId) async {
    await _firestore.collection(AppConstants.postsCollection).doc(postId).delete();
  }
}
