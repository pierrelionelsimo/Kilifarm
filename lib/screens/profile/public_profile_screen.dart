import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../../widgets/initials_avatar.dart';

/// Vue en lecture seule du profil d'un autre utilisateur, ouverte
/// depuis la recherche. Volontairement PAS d'email ni de téléphone
/// affichés ici — un inconnu qui te trouve dans l'annuaire ne doit
/// pas accéder directement à tes coordonnées ; ces infos restent
/// visibles seulement sur TON propre écran de profil.
class PublicProfileScreen extends StatelessWidget {
  final UserModel user;

  const PublicProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 28),
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
