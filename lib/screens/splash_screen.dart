import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initAndNavigate());
  }

  Future<void> _initAndNavigate() async {
    final authProvider = context.read<AuthProvider>();

    // Durée minimale d'affichage pour l'identité visuelle, même si
    // Firebase répond très vite.
    final minDisplay = Future.delayed(const Duration(milliseconds: 800));

    // FIX: on attend la vraie première réponse de Firebase (session
    // retrouvée ou confirmation qu'il n'y a personne) au lieu d'un
    // délai fixe de 2s qui pouvait naviguer avant que l'état soit connu.
    final authReady = authProvider.isInitialized
        ? Future<void>.value()
        : _waitForInit(authProvider);

    await Future.wait([minDisplay, authReady]);

    if (!mounted || _navigated) return;
    _navigated = true;

    if (authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Future<void> _waitForInit(AuthProvider provider) {
    final completer = Completer<void>();
    void listener() {
      if (provider.isInitialized) {
        completer.complete();
        provider.removeListener(listener);
      }
    }

    provider.addListener(listener);
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
                      Image.asset(
                        'assets/icon/icon_sf.png',
                        width: 80,
                        height: 80,
                      ),
            const SizedBox(height: 16),
            const Text(
              'KILIFARM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Agriculture & Élevage Connectés',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
