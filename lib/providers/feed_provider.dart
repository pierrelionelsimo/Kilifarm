import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../config/constants.dart';

class FeedProvider extends ChangeNotifier {
  final PostService _postService = PostService();

  final List<PostModel> _posts = [];
  DocumentSnapshot? _lastDoc;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  Future<void> loadInitial({String? currentUserId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _postService.fetchPosts(currentUserId: currentUserId);
      _posts
        ..clear()
        ..addAll(result.posts);
      _lastDoc = result.lastDoc;
      _hasMore = result.posts.length == AppConstants.pageSize;
    } catch (e) {
      _errorMessage = "Impossible de charger le fil d'actualité.";
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore({String? currentUserId}) async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _postService.fetchPosts(
        startAfter: _lastDoc,
        currentUserId: currentUserId,
      );
      _posts.addAll(result.posts);
      _lastDoc = result.lastDoc;
      _hasMore = result.posts.length == AppConstants.pageSize;
    } catch (_) {
      // Erreur silencieuse sur le "load more" : on garde ce qui est
      // déjà affiché plutôt que de casser tout le fil.
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  /// Bascule le like d'un post. Met à jour l'affichage immédiatement
  /// (optimiste) avant même la réponse serveur — annule seulement si
  /// l'écriture Firestore échoue vraiment.
  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final original = _posts[index];
    final wasLiked = original.isLikedByMe;

    _posts[index] = PostModel(
      id: original.id,
      userId: original.userId,
      userName: original.userName,
      userProfileImage: original.userProfileImage,
      content: original.content,
      imageUrls: original.imageUrls,
      createdAt: original.createdAt,
      likesCount: wasLiked ? original.likesCount - 1 : original.likesCount + 1,
      commentsCount: original.commentsCount,
      isLikedByMe: !wasLiked,
    );
    notifyListeners();

    try {
      await _postService.toggleLike(postId: postId, userId: userId);
    } catch (_) {
      // Échec réseau : on annule la mise à jour optimiste.
      _posts[index] = original;
      notifyListeners();
    }
  }

  Future<bool> createPost({
    required String userId,
    required String userName,
    String? userProfileImage,
    required String content,
    required List<File> images,
  }) async {
    _errorMessage = null;
    try {
      await _postService.createPost(
        userId: userId,
        userName: userName,
        userProfileImage: userProfileImage,
        content: content,
        images: images,
      );
      await loadInitial(); // remonte le nouveau post en tête de fil
      return true;
    } catch (e) {
      _errorMessage = e is String ? e : 'Erreur lors de la publication.';
      notifyListeners();
      return false;
    }
  }
}
