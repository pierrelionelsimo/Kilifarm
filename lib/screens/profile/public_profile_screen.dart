import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/follow_repository.dart';
import '../../repositories/firestore_follow_repository.dart';
import '../../widgets/initials_avatar.dart';
import '../../widgets/profile_stats_row.dart';

/// Vue en lecture seule du profil d'un autre utilisateur, ouverte
/// depuis la recherche. Volontairement PAS d'email ni de téléphone
/// affichés ici — un inconnu qui te trouve dans l'annuaire ne doit
/// pas accéder directement à tes coordonnées.
class PublicProfileScreen extends StatefulWidget {
  final UserModel user;

  const PublicProfileScreen({super.key, required this.user});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final FollowRepository _followRepository = FirestoreFollowRepository();

  bool? _isFollowing; // null = statut pas encore chargé
  late int _followersCount;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _followersCount = widget.user.followersCount;
    _loadFollowStatus();
  }

  Future<void> _loadFollowStatus() async {
    final currentUserId = context.read<AuthProvider>().userModel?.uid;
    if (currentUserId == null) return;

    final following = await _followRepository.isFollowing(
      currentUserId: currentUserId,
      targetUserId: widget.user.uid,
    );

    if (mounted) setState(() => _isFollowing = following);
  }

  Future<void> _toggleFollow() async {
    final currentUserId = context.read<AuthProvider>().userModel?.uid;
    if (currentUserId == null || _isToggling) return;

    setState(() => _isToggling = true);

    final nowFollowing = await _followRepository.toggleFollow(
      currentUserId: currentUserId,
      targetUserId: widget.user.uid,
    );

    if (mounted) {
      setState(() {
        _isFollowing = nowFollowing;
        _followersCount += nowFollowing ? 1 : -1;
        _isToggling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final currentUserId = context.watch<AuthProvider>().userModel?.uid;
    final isOwnProfile = currentUserId == user.uid;

    final hasRegion = user.region != null && user.region!.isNotEmpty;
    final hasActivity = user.activityType != null && user.activityType!.isNotEmpty;
    final hasBio = user.bio != null && user.bio!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(user.fullName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            InitialsAvatar(fullName: user.fullName, radius: 48),
            const SizedBox(height: 16),
            Text(
              user.fullName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (hasActivity) ...[
              const SizedBox(height: 4),
              Text(
                user.activityType!,
                style: const TextStyle(color: AppTheme.textLight, fontSize: 15),
              ),
            ],
            const SizedBox(height: 20),
            ProfileStatsRow(
              postsCount: user.postsCount,
              followersCount: _followersCount,
              followingCount: user.followingCount,
            ),
            const SizedBox(height: 16),
            if (!isOwnProfile)
              SizedBox(
                width: 160,
                height: 38,
                child: _isFollowing == null
                    ? const SizedBox.shrink() // en cours de chargement
                    : _isFollowing!
                        ? OutlinedButton(
                            onPressed: _isToggling ? null : _toggleFollow,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade400),
                              foregroundColor: AppTheme.textDark,
                            ),
                            child: const Text('Abonné'),
                          )
                        : ElevatedButton(
                            onPressed: _isToggling ? null : _toggleFollow,
                            child: const Text('Suivre'),
                          ),
              ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            if (hasRegion)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 20, color: AppTheme.textLight),
                    const SizedBox(width: 12),
                    const Text('Région : ',
                        style: TextStyle(color: AppTheme.textLight)),
                    Text(user.region!,
                        style: const TextStyle(color: AppTheme.textDark)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'À propos',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                hasBio ? user.bio! : "Cet utilisateur n'a pas encore de bio.",
                style: TextStyle(
                  color: hasBio ? AppTheme.textDark : AppTheme.textLight,
                  fontStyle: hasBio ? FontStyle.normal : FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
