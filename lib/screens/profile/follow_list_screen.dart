import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../../repositories/follow_repository.dart';
import '../../repositories/firestore_follow_repository.dart';
import '../../widgets/initials_avatar.dart';
import 'public_profile_screen.dart';

/// Liste des abonnés / abonnements d'un utilisateur, façon Instagram :
/// deux onglets dans le même écran, celui tapé depuis le profil
/// s'ouvre en premier. Fonctionne aussi bien depuis son propre profil
/// que depuis celui de quelqu'un d'autre.
class FollowListScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final int initialTab; // 0 = Abonnés, 1 = Abonnements

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.initialTab = 0,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  final FollowRepository _followRepository = FirestoreFollowRepository();

  // Calculées une seule fois dans initState, pas dans build : sinon
  // chaque rebuild relancerait les requêtes et réafficherait le loader.
  late final Future<List<UserModel>> _followersFuture;
  late final Future<List<UserModel>> _followingFuture;

  @override
  void initState() {
    super.initState();
    _followersFuture = _followRepository.getFollowers(widget.userId);
    _followingFuture = _followRepository.getFollowing(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.userName),
          bottom: const TabBar(
            tabs: [Tab(text: 'Abonnés'), Tab(text: 'Abonnements')],
          ),
        ),
        body: TabBarView(
          children: [
            _FollowList(
              future: _followersFuture,
              emptyText: "Pas encore d'abonnés.",
            ),
            _FollowList(
              future: _followingFuture,
              emptyText: 'Ne suit encore personne.',
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowList extends StatelessWidget {
  final Future<List<UserModel>> future;
  final String emptyText;

  const _FollowList({required this.future, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserModel>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Impossible de charger la liste.',
                style: TextStyle(color: AppTheme.textLight),
              ),
            ),
          );
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return Center(
            child: Text(emptyText,
                style: const TextStyle(color: AppTheme.textLight)),
          );
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              leading: InitialsAvatar(fullName: user.fullName, radius: 20),
              title: Text(user.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                [
                  if (user.activityType != null &&
                      user.activityType!.isNotEmpty)
                    user.activityType!,
                  if (user.region != null && user.region!.isNotEmpty)
                    user.region!,
                ].join(' · '),
                style: const TextStyle(color: AppTheme.textLight, fontSize: 13),
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => PublicProfileScreen(user: user)),
                );
              },
            );
          },
        );
      },
    );
  }
}
