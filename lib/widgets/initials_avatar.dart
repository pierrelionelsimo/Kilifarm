import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Avatar affichant les initiales de l'utilisateur sur un fond coloré,
/// déterminé de façon stable à partir de son nom. Sert de solution
/// temporaire en attendant l'ajout de l'upload de vraies photos de
/// profil (prévu pour une itération future, cf. décision V1).
class InitialsAvatar extends StatelessWidget {
  final String fullName;
  final double radius;

  const InitialsAvatar({
    super.key,
    required this.fullName,
    this.radius = 40,
  });

  String get _initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts[0][0];
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  Color get _backgroundColor {
    const palette = [
      AppTheme.primaryGreen,
      AppTheme.secondaryGreen,
      AppTheme.accentOrange,
      AppTheme.earthBrown,
    ];
    if (fullName.isEmpty) return palette[0];
    final sum = fullName.codeUnits.fold(0, (a, b) => a + b);
    return palette[sum % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _backgroundColor,
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.7,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
