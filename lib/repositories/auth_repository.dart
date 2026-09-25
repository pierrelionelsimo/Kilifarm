import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

/// Contrat pour tout service d'authentification. Les Provider ne
/// connaissent que ce contrat — jamais Firebase Auth directement.
abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  User? get currentUser;

  Future<UserModel> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
    required String region,
    required String activityType,
  });

  Future<UserModel?> loginWithEmail({
    required String email,
    required String password,
  });

  Future<UserModel?> fetchUserProfile(String uid);

  Future<UserModel?> signInWithGoogle();

  Future<void> updateProfile(UserModel user);

  Future<void> signOut();
}
