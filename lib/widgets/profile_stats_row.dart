import 'package:flutter/material.dart';
import '../config/theme.dart';

class ProfileStatsRow extends StatelessWidget {
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final VoidCallback onTapFollowers;
  final VoidCallback onTapFollowing;

  const ProfileStatsRow({
    super.key,
    required this.postsCount,
    required this.followersCount,
    required this.followingCount,
    required this.onTapFollowers,
    required this.onTapFollowing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Le nombre de publications n'ouvre rien : la grille est déjà
        // visible plus bas sur le même écran.
        _StatItem(count: postsCount, label: 'Publications'),
        const SizedBox(width: 28),
        _StatItem(
          count: followersCount,
          label: 'Abonnés',
          onTap: onTapFollowers,
        ),
        const SizedBox(width: 28),
        _StatItem(
          count: followingCount,
          label: 'Abonnements',
          onTap: onTapFollowing,
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final int count;
  final String label;
  final VoidCallback? onTap;

  const _StatItem({required this.count, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
        ),
      ],
    );

    if (onTap == null) return content;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: content,
      ),
    );
  }
}
