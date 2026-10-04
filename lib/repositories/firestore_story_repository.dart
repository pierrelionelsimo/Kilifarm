import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/story_model.dart';
import 'media_repository.dart';
import 'story_repository.dart';

class FirestoreStoryRepository implements StoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MediaRepository _mediaRepository;

  FirestoreStoryRepository({required MediaRepository mediaRepository})
      : _mediaRepository = mediaRepository;

  @override
  Stream<List<StoryModel>> watchActiveStories() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    return _firestore
        .collection('stories')
        .where('createdAt', isGreaterThan: cutoff)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StoryModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Future<void> createStory({
    required String userId,
    required String userName,
    required File image,
  }) async {
    final imageUrl = await _mediaRepository.uploadImage(image);
    final ref = _firestore.collection('stories').doc();
    await ref.set({
      'userId': userId,
      'userName': userName,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteStory(String storyId) async {
    await _firestore.collection('stories').doc(storyId).delete();
  }
}
