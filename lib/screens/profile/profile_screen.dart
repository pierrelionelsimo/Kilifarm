import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/initials_avatar.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final hasRegion = user.region != null && user.region!.isNotEmpty;
    final hasActivity = user.activityType != null && user.activityType!.isNotEmpty;
    final hasPhone = user.phoneNumber != null && user.phoneNumber!.isNotEmpty;
    final hasBio = user.bio != null && user.bio!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifier',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
          ),
        ],
      ),
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
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'Région',
              value: hasRegion ? user.region! : 'Non renseignée',
              isPlaceholder: !hasRegion,
            ),
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: user.email,
            ),
            if (hasPhone)
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Téléphone',
                value: user.phoneNumber!,
              ),
            const SizedBox(height: 20),
            Align(
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
                hasBio ? user.bio! : 'Aucune bio pour le moment.',
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isPlaceholder;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isPlaceholder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textLight),
          const SizedBox(width: 12),
          Text('$label : ', style: const TextStyle(color: AppTheme.textLight)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isPlaceholder ? AppTheme.textLight : AppTheme.textDark,
                fontStyle: isPlaceholder ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
