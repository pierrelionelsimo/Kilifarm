import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Placeholder assumé : seul le français est réellement disponible.
/// Une vraie prise en charge multilingue (flutter_localizations +
/// fichiers .arb + remplacement de tous les textes codés en dur dans
/// l'app) est un chantier à part entière, volontairement pas fait ici.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Langue')),
      body: ListView(
        children: const [
          ListTile(
            title: Text('Français'),
            trailing: Icon(Icons.check, color: AppTheme.primaryGreen),
          ),
          _DisabledLanguageTile(label: 'English'),
          _DisabledLanguageTile(label: 'Kiswahili'),
          _DisabledLanguageTile(label: 'Wolof'),
        ],
      ),
    );
  }
}

class _DisabledLanguageTile extends StatelessWidget {
  final String label;

  const _DisabledLanguageTile({required this.label});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: AppTheme.textLight)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Bientôt',
          style: TextStyle(fontSize: 11, color: AppTheme.textLight),
        ),
      ),
    );
  }
}
