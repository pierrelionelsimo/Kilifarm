import 'dart:io';
import '../models/story_model.dart';

abstract class StoryRepository {
  /// Stories actives (moins de 24h), tous utilisateurs confondus —
  /// même visibilité que le Fil (pas réservé aux abonnements). Un seul
  /// filtre d'inégalité sur `createdAt`, pas de orderBy combiné dessus :
  /// pas besoin d'index composite. Le regroupement par utilisateur se
  /// fait côté appelant (StoriesBar).
  Stream<List<StoryModel>> watchActiveStories();

  Future<void> createStory({
    required String userId,
    required String userName,
    required File image,
  });

  Future<void> deleteStory(String storyId);
}
