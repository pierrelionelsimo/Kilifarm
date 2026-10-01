import 'package:flutter/material.dart';
import '../../config/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confidentialité')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dernière mise à jour : ${DateTime.now().year}',
              style: const TextStyle(color: AppTheme.textLight, fontSize: 12),
            ),
            const SizedBox(height: 16),
            const _Section(
              title: 'Données que nous collectons',
              body:
                  'Lorsque vous créez un compte KILIFARM, nous collectons votre nom '
                  "complet et votre adresse email, ainsi que — si vous les renseignez "
                  "— votre région, votre type d'activité, votre numéro de téléphone et "
                  'une courte biographie. Lorsque vous publiez du contenu, nous '
                  'stockons le texte et les photos que vous partagez, ainsi que vos '
                  'likes, commentaires et abonnements.',
            ),
            const _Section(
              title: 'Où sont stockées vos données',
              body:
                  "Vos informations de compte et vos publications sont stockées sur "
                  "Firebase (Google), un service d'hébergement cloud sécurisé. Vos "
                  'photos sont hébergées séparément sur Cloudinary.',
            ),
            const _Section(
              title: 'Comment nous utilisons vos données',
              body:
                  "Vos données servent uniquement à faire fonctionner l'application : "
                  'afficher votre profil, vos publications, et vous connecter avec '
                  "d'autres utilisateurs de la communauté agricole. Nous ne vendons ni "
                  "ne partageons vos données avec des tiers à des fins commerciales, et "
                  "l'application ne diffuse aucune publicité.",
            ),
            const _Section(
              title: 'Vos droits',
              body:
                  'Vous pouvez modifier ou supprimer vos publications à tout moment '
                  "depuis l'application. Pour toute demande de suppression complète de "
                  'votre compte et de vos données, contactez-nous via les coordonnées '
                  'ci-dessous.',
            ),
            const _Section(
              title: 'Contact',
              body:
                  'Pour toute question sur cette politique de confidentialité, '
                  "contactez l'équipe KILIFARM à kilifarm@gmail.com.",
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Text(
                "Ce texte est un premier brouillon rédigé pour une app en "
                "développement. Avant une publication publique large, fais-le "
                "relire par quelqu'un ayant une compétence juridique — ce document "
                'ne constitue pas un avis juridique.',
                style: TextStyle(fontSize: 12, color: Colors.deepOrange),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(color: AppTheme.textDark, height: 1.4)),
        ],
      ),
    );
  }
}
