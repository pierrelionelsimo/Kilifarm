import 'package:flutter/material.dart';
import '../../models/story_model.dart';
import '../../repositories/story_repository.dart';
import '../../widgets/initials_avatar.dart';

/// Plein écran, façon Instagram : barres de progression en haut,
/// avance automatique après 5s, tap gauche/droite pour naviguer,
/// appui long pour mettre en pause, swipe vers le bas pour fermer.
class StoryViewerScreen extends StatefulWidget {
  final List<StoryModel> stories;
  final bool isOwn;
  final StoryRepository storyRepository;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    required this.isOwn,
    required this.storyRepository,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  static const _storyDuration = Duration(seconds: 5);
  late final AnimationController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _storyDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _next();
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < widget.stories.length - 1) {
      setState(() => _index++);
      _controller
        ..reset()
        ..forward();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previous() {
    setState(() => _index = _index > 0 ? _index - 1 : 0);
    _controller
      ..reset()
      ..forward();
  }

  Future<void> _confirmDelete() async {
    _controller.stop();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette story ?'),
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
      await widget.storyRepository.deleteStory(widget.stories[_index].id);
      if (mounted) Navigator.of(context).pop();
    } else if (mounted) {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_index];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final width = MediaQuery.of(context).size.width;
          details.globalPosition.dx < width / 3 ? _previous() : _next();
        },
        onLongPressStart: (_) => _controller.stop(),
        onLongPressEnd: (_) => _controller.forward(),
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 200) Navigator.of(context).pop();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              story.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                color: Colors.grey.shade900,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined,
                    color: Colors.white54, size: 48),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Column(
                  children: [
                    Row(
                      children: List.generate(widget.stories.length, (i) {
                        return Expanded(
                          child: Container(
                            height: 2.5,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: Colors.white30,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: i < _index
                                ? _FullBar()
                                : i == _index
                                    ? AnimatedBuilder(
                                        animation: _controller,
                                        builder: (context, _) =>
                                            FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: _controller.value,
                                          child: _FullBar(),
                                        ),
                                      )
                                    : null,
                          ),
                        );
                      }),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          InitialsAvatar(fullName: story.userName, radius: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              story.userName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (widget.isOwn)
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.white),
                              onPressed: _confirmDelete,
                            ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
