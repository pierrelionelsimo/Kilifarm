import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../widgets/initials_avatar.dart';
import '../../widgets/post_card.dart';
import '../profile/profile_screen.dart';
import '../post/create_post_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Charge le fil dès l'arrivée sur l'écran.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().userModel?.uid;
      context.read<FeedProvider>().loadInitial(currentUserId: uid);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Charge la page suivante quand on approche du bas de la liste.
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final uid = context.read<AuthProvider>().userModel?.uid;
      context.read<FeedProvider>().loadMore(currentUserId: uid);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final feedProvider = context.watch<FeedProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('KILIFARM'),
        actions: [
          IconButton(
            icon: authProvider.userModel != null
                ? InitialsAvatar(
                    fullName: authProvider.userModel!.fullName,
                    radius: 14,
                  )
                : const Icon(Icons.person_outline),
            tooltip: 'Mon profil',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: _buildBody(feedProvider),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(FeedProvider feedProvider) {
    if (feedProvider.isLoading && feedProvider.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (feedProvider.errorMessage != null && feedProvider.posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: AppTheme.textLight),
              const SizedBox(height: 12),
              Text(feedProvider.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textLight)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => feedProvider.loadInitial(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (feedProvider.posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/icon/icon_k.png', width: 72, height: 72),
              const SizedBox(height: 16),
              const Text(
                'Aucune publication pour le moment',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Soyez le premier à partager une astuce ou une question.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textLight),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () {
        final uid = context.read<AuthProvider>().userModel?.uid;
        return feedProvider.loadInitial(currentUserId: uid);
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: feedProvider.posts.length + (feedProvider.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= feedProvider.posts.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final uid = context.read<AuthProvider>().userModel?.uid ?? '';
          return PostCard(
            post: feedProvider.posts[index],
            currentUserId: uid,
            onLikeToggle: (postId) =>
                feedProvider.toggleLike(postId: postId, userId: uid),
          );
        },
      ),
    );
  }
}
