import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/post_model.dart';
import '../repositories/post_repository.dart';
import '../repositories/firestore_post_repository.dart';
import '../repositories/cloudinary_media_repository.dart';
import 'post_card.dart';

/// Grille de publications façon Instagram, utilisée à la fois sur son
/// propre profil et sur le profil public d'un autre utilisateur.
///
/// Filtre `userId` seul côté serveur (pas de `orderBy` combiné dessus)
/// puis tri par date côté client — même logique que pour les
/// conversations et la recherche, pour ne jamais dépendre d'un index
/// composite. Chaque vignette ouvre une vue détail qui réutilise
/// `PostCard` tel quel : même composant que dans le Fil, donc
/// like/commentaire/suppression se comportent exactement pareil.
class ProfilePostGrid extends StatefulWidget {
  final String userId;
  final String currentUserId;

  const ProfilePostGrid({
    super.key,
    required this.userId,
    required this.currentUserId,
  });

  @override
  State<ProfilePostGrid> createState() => _ProfilePostGridState();
}

class _ProfilePostGridState extends State<ProfilePostGrid> {
  // Instanciation locale, comme FollowRepository/MessageRepository
  // ailleurs dans les écrans — pas d'injection par constructeur ici.
  final PostRepository _postRepository = FirestorePostRepository(
    mediaRepository: CloudinaryMediaRepository(),
  );

  List<PostModel>? _posts; // null = chargement en cours
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final posts = await _postRepository.fetchPostsByUser(
        userId: widget.userId,
        currentUserId: widget.currentUserId,
      );
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (mounted) setState(() => _posts = posts);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Impossible de charger les publications.');
      }
    }
  }

  void _openDetail(PostModel post) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Publication')),
          body: SingleChildScrollView(
            child: PostCard(
              post: post,
              currentUserId: widget.currentUserId,
              onLikeToggle: (postId) => _postRepository.toggleLike(
                postId: postId,
                userId: widget.currentUserId,
              ),
              onDelete: (postId) async {
                await _postRepository.deletePost(postId);
                if (mounted) {
                  Navigator.of(context).pop();
                  _load();
                }
              },
              onCommentAdded: (_) {},
              onCommentDeleted: (_) {},
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child:
              Text(_error!, style: const TextStyle(color: AppTheme.textLight)),
        ),
      );
    }

    if (_posts == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_posts!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'Aucune publication pour le moment.',
            style: TextStyle(color: AppTheme.textLight),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _posts!.length,
      itemBuilder: (context, index) {
        final post = _posts![index];
        final hasImage = post.imageUrls.isNotEmpty;

        return GestureDetector(
          onTap: () => _openDetail(post),
          child: hasImage
              ? Image.network(post.imageUrls.first, fit: BoxFit.cover)
              : Container(
                  // Les posts texte seul n'ont pas de vignette photo :
                  // on affiche un extrait du texte sur fond teinté
                  // plutôt qu'une case vide, pour rester identifiable
                  // dans la grille.
                  color: AppTheme.lightGreen,
                  padding: const EdgeInsets.all(6),
                  alignment: Alignment.center,
                  child: Text(
                    post.content,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
        );
      },
    );
  }
}
