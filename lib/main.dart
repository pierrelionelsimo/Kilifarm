import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/feed_provider.dart';
import 'repositories/firebase_auth_repository.dart';
import 'repositories/firestore_post_repository.dart';
import 'repositories/cloudinary_media_repository.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const KilifarmApp());
}

class KilifarmApp extends StatelessWidget {
  const KilifarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ---- Composition root ----
        // Seul endroit du projet où les implémentations CONCRÈTES sont
        // choisies. Partout ailleurs (Provider, écrans, widgets), on ne
        // manipule que des interfaces abstraites (AuthRepository,
        // PostRepository...). Pour swapper un fournisseur demain, une
        // seule ligne change, ici — rien d'autre.
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authRepository: FirebaseAuthRepository(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => FeedProvider(
            postRepository: FirestorePostRepository(
              mediaRepository: CloudinaryMediaRepository(),
            ),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'KILIFARM',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}
