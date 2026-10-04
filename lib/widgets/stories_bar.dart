import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/story_model.dart';
import '../providers/auth_provider.dart';
import '../repositories/story_repository.dart';
import '../repositories/firestore_story_repository.dart';
import '../repositories/cloudinary_media_repository.dart';
import '../screens/stories/create_story_screen.dart';
import '../screens/stories/story_viewer_screen.dart';
import 'initials_avatar.dart';

/// Rangée de stories façon Instagram/TikTok en haut du fil : "Votre
/// story" en premier (ajout si vide, visionnage sinon), puis un
/// cercle par utilisateur ayant au moins une story active.
class StoriesBar extends StatelessWidget {
  const StoriesBar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().userModel;
    if (currentUser == null) return const SizedBox.shrink();

    // Instanciation locale, comme les autres repositories dans les
    // écrans — pas d'injection par constructeur ici.
    final StoryRepository storyRepository = FirestoreStoryRepository(
      mediaRepository: CloudinaryMediaRepository(),
    );

    return SizedBox(
      height: 100,
      child: StreamBuilder<List<StoryModel>>(
        stream: storyRepository.watchActiveStories(),
        builder: (context, snapshot) {
          final stories = snapshot.data ?? [];

          // Regroupement par utilisateur côté client, triées par date
          // croissante — pas de tri Firestore combiné au filtre
          // d'inégalité sur createdAt.
          final Map<String, List<StoryModel>> byUser = {};
          for (final s in stories) {
            byUser.putIfAbsent(s.userId, () => []).add(s);
          }
          for (final list in byUser.values) {
            list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          }

          final myStories = byUser[currentUser.uid] ?? [];
          final otherUserIds =
              byUser.keys.where((id) => id != currentUser.uid).toList();

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            itemCount: 1 + otherUserIds.length,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _StoryCircle(
                  label: 'Votre story',
                  fullName: currentUser.fullName,
                  hasStory: myStories.isNotEmpty,
                  showAddBadge: myStories.isEmpty,
                  onTap: () {
                    if (myStories.isEmpty) {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            CreateStoryScreen(storyRepository: storyRepository),
                      ));
                    } else {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => StoryViewerScreen(
                          stories: myStories,
                          isOwn: true,
                          storyRepository: storyRepository,
                        ),
                      ));
                    }
                  },
                );
              }

              final uid = otherUserIds[index - 1];
              final userStories = byUser[uid]!;
              return _StoryCircle(
                label: userStories.first.userName,
                fullName: userStories.first.userName,
                hasStory: true,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => StoryViewerScreen(
                      stories: userStories,
                      isOwn: false,
                      storyRepository: storyRepository,
                    ),
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _StoryCircle extends StatelessWidget {
  final String label;
  final String fullName;
  final bool hasStory;
  final bool showAddBadge;
  final VoidCallback onTap;

  const _StoryCircle({
    required this.label,
    required this.fullName,
    required this.hasStory,
    required this.onTap,
    this.showAddBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasStory
                        ? const LinearGradient(
                            colors: [
                              AppTheme.accentOrange,
                              AppTheme.primaryGreen,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    border: hasStory
                        ? null
                        : Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.cardWhite,
                    ),
                    child: InitialsAvatar(fullName: fullName, radius: 28),
                  ),
                ),
                if (showAddBadge)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.cardWhite, width: 2),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 13),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppTheme.textDark),
            ),
          ],
        ),
      ),
    );
  }
}
