import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/post_model.dart';
import 'comments_sheet.dart';
import 'initials_avatar.dart';

/// Carte de publication façon Instagram : images plein cadre défilables
/// avec pastilles, double-tap pour aimer (cœur animé), boutons like
/// fonctionnels. Le commentaire reste affiché mais non cliquable —
/// c'est la prochaine étape du scope V1, pas mélangée ici.
class PostCard extends StatefulWidget {
  final PostModel post;
  final String currentUserId;
  final void Function(String postId) onLikeToggle;
  final void Function(String postId) onDelete;
  final void Function(String postId) onCommentAdded;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onLikeToggle,
    required this.onDelete,
    required this.onCommentAdded,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heartController;
  late final Animation<double> _heartScale;
  bool _showHeartOverlay = false;

  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.15).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_heartController);
  }

  @override
  void dispose() {
    _heartController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    // Comme Instagram : le double-tap AIME toujours, il ne retire
    // jamais le like — même si le post est déjà aimé, on rejoue juste
    // l'animation du cœur sans re-toggle.
    if (!widget.post.isLikedByMe) {
      widget.onLikeToggle(widget.post.id);
    }
    setState(() => _showHeartOverlay = true);
    _heartController.forward(from: 0).then((_) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) setState(() => _showHeartOverlay = false);
      });
    });
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "à l'instant";
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    return 'il y a ${diff.inDays} j';
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la publication ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.onDelete(widget.post.id);
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature bientôt disponible')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppTheme.cardWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
            child: Row(
              children: [
                InitialsAvatar(fullName: post.userName, radius: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.userName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(
                        _timeAgo(post.createdAt),
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textLight),
                      ),
                    ],
                  ),
                ),
                if (post.userId == widget.currentUserId)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert,
                        size: 20, color: AppTheme.textLight),
                    onSelected: (value) {
                      if (value == 'delete') _confirmDelete();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Supprimer'),
                      ),
                    ],
                  )
                else
                  const SizedBox(width: 20),
              ],
            ),
          ),
          if (post.imageUrls.isNotEmpty)
            GestureDetector(
              onDoubleTap: _handleDoubleTap,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: post.imageUrls.length,
                      onPageChanged: (i) =>
                          setState(() => _currentImageIndex = i),
                      itemBuilder: (context, i) => Image.network(
                        post.imageUrls[i],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(color: Colors.grey.shade200);
                        },
                        errorBuilder: (context, error, stack) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image_outlined,
                              color: AppTheme.textLight),
                        ),
                      ),
                    ),
                  ),
                  if (post.imageUrls.length > 1)
                    Positioned(
                      bottom: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(post.imageUrls.length, (i) {
                          return Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == _currentImageIndex
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                            ),
                          );
                        }),
                      ),
                    ),
                  if (_showHeartOverlay)
                    ScaleTransition(
                      scale: _heartScale,
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 90,
                        shadows: [Shadow(color: Colors.black38, blurRadius: 14)],
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    post.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                    color: post.isLikedByMe ? Colors.red : AppTheme.textDark,
                  ),
                  onPressed: () => widget.onLikeToggle(post.id),
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline,
                      color: AppTheme.textDark),
                  onPressed: () {
                    CommentsSheet.show(
                      context,
                      postId: post.id,
                      onCommentAdded: () => widget.onCommentAdded(post.id),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined,
                      color: AppTheme.textDark),
                  onPressed: () => _showComingSoon('Le partage'),
                ),
              ],
            ),
          ),
          if (post.likesCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                '${post.likesCount} j\'aime',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: AppTheme.textDark, fontSize: 14),
                  children: [
                    TextSpan(
                      text: '${post.userName} ',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: post.content),
                  ],
                ),
              ),
            )
          else
            const SizedBox(height: 10),
        ],
      ),
    );
  }
}
