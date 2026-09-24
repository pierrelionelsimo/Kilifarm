import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/comment_model.dart';
import '../providers/auth_provider.dart';
import '../services/comment_service.dart';
import 'initials_avatar.dart';

/// Panneau de commentaires en bottom sheet, façon Instagram/Facebook.
/// Liste temps réel (StreamBuilder) + champ de saisie fixé en bas.
///
/// Ouvert via [CommentsSheet.show] depuis PostCard. `onCommentAdded`
/// permet au parent de mettre à jour son compteur local sans attendre
/// un rechargement complet du fil.
class CommentsSheet extends StatefulWidget {
  final String postId;
  final VoidCallback onCommentAdded;

  const CommentsSheet({
    super.key,
    required this.postId,
    required this.onCommentAdded,
  });

  static void show(
    BuildContext context, {
    required String postId,
    required VoidCallback onCommentAdded,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => CommentsSheet(
        postId: postId,
        onCommentAdded: onCommentAdded,
      ),
    );
  }

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final CommentService _commentService = CommentService();
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    final user = context.read<AuthProvider>().userModel;
    if (user == null) return;

    setState(() => _isSending = true);

    try {
      await _commentService.addComment(
        postId: widget.postId,
        userId: user.uid,
        userName: user.fullName,
        userProfileImage: user.profileImageUrl,
        content: content,
      );
      _controller.clear();
      widget.onCommentAdded();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de l'envoi du commentaire")),
        );
      }
    }

    if (mounted) setState(() => _isSending = false);
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "à l'instant";
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    return 'il y a ${diff.inDays} j';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Commentaires',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const Divider(height: 20),
              Expanded(
                child: StreamBuilder<List<CommentModel>>(
                  stream: _commentService.watchComments(widget.postId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Impossible de charger les commentaires.',
                          style: TextStyle(color: AppTheme.textLight),
                        ),
                      );
                    }

                    final comments = snapshot.data ?? [];

                    if (comments.isEmpty) {
                      return const Center(
                        child: Text(
                          'Aucun commentaire pour le moment.\nSoyez le premier à réagir.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textLight),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InitialsAvatar(
                                  fullName: comment.userName, radius: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                            color: AppTheme.textDark,
                                            fontSize: 14),
                                        children: [
                                          TextSpan(
                                            text: '${comment.userName} ',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600),
                                          ),
                                          TextSpan(text: comment.content),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _timeAgo(comment.createdAt),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textLight),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Ajouter un commentaire...',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send, color: AppTheme.primaryGreen),
                        onPressed: _isSending ? null : _sendComment,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
