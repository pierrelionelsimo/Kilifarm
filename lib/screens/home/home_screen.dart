import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../widgets/initials_avatar.dart';
import '../../widgets/post_card.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';
import '../messages/conversations_screen.dart';
import '../../models/conversation_model.dart';
import '../../repositories/message_repository.dart';
import '../../repositories/firestore_message_repository.dart';
import '../post/create_post_screen.dart';
import '../../widgets/stories_bar.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().userModel?.uid;
      context.read<FeedProvider>().loadInitial(currentUserId: uid);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
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
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon/icon_k.png', width: 28, height: 28),
            const SizedBox(width: 8),
            const Text(
              'KiliFarm',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
          ],
        ),
        // La recherche n'est plus une icône ici : elle vit dans la
        // bande détachée en dessous (bloc `bottom:`), schéma Facebook.
        actions: [
          _MessagesIconButton(currentUserId: authProvider.userModel?.uid),
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
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Paramètres',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            // Pastille grise tapable (pas un vrai TextField — la saisie
            // se fait sur SearchScreen). De la place est laissée pour
            // ajouter plus tard des notifications ou des filtres à côté.
            child: Material(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  );
                },
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: AppTheme.textLight, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Rechercher sur KiliFarm...',
                        style: TextStyle(color: AppTheme.textLight, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const StoriesBar(),
          const Divider(height: 1),
          Expanded(child: _buildBody(feedProvider)),
        ],
      ),
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
            onDelete: (postId) => feedProvider.deletePost(postId),
            onCommentAdded: (postId) =>
                feedProvider.incrementCommentCount(postId),
            onCommentDeleted: (postId) =>
                feedProvider.decrementCommentCount(postId),
          );
        },
      ),
    );
  }
}

/// Icône Messages avec pastille orange si au moins une conversation
/// contient un message non lu. `Icons.send_outlined` (avion en papier,
/// façon Instagram) — volontairement différent de
/// `Icons.chat_bubble_outline`, déjà utilisé pour les commentaires.
class _MessagesIconButton extends StatelessWidget {
  final String? currentUserId;

  const _MessagesIconButton({required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final uid = currentUserId;

    if (uid == null) {
      return IconButton(
        icon: const Icon(Icons.send_outlined),
        tooltip: 'Messages',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ConversationsScreen()),
        ),
      );
    }

    final MessageRepository messageRepository = FirestoreMessageRepository();

    return StreamBuilder<List<ConversationModel>>(
      stream: messageRepository.watchConversations(uid),
      builder: (context, snapshot) {
        final hasUnread =
            (snapshot.data ?? []).any((conv) => conv.isUnread(uid));

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.send_outlined),
              tooltip: 'Messages',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ConversationsScreen()),
              ),
            ),
            if (hasUnread)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.cardWhite, width: 1.5),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
