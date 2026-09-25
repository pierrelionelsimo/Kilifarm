import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  User? _currentUser;
  UserModel? _userModel;
  bool _isLoading = false;
  bool _isInitialized = false; // vrai seulement après la 1ère réponse Firebase
  String? _errorMessage;

  User? get currentUser => _currentUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  // Dépendance explicite, aucune valeur par défaut cachée : c'est
  // main.dart (composition root) qui décide quelle implémentation
  // concrète est réellement utilisée.
  AuthProvider({required AuthRepository authRepository})
      : _authRepository = authRepository {
    _authRepository.authStateChanges.listen((User? user) async {
      _currentUser = user;

      if (user == null) {
        _userModel = null;
      } else {
        // Recharge le profil Firestore à chaque session détectée
        // (démarrage de l'app avec session persistée, pas seulement
        // au moment du login/register explicite).
        try {
          _userModel = await _authRepository.fetchUserProfile(user.uid);
        } catch (_) {
          _userModel = null;
        }
      }

      _isInitialized = true;
      notifyListeners();
    });
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String region,
    required String activityType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final UserModel user = await _authRepository.registerWithEmail(
        fullName: fullName,
        email: email,
        password: password,
        region: region,
        activityType: activityType,
      );

      _userModel = user;
      _currentUser = _authRepository.currentUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final UserModel? user = await _authRepository.loginWithEmail(
        email: email,
        password: password,
      );

      if (user != null) {
        _userModel = user;
        _currentUser = _authRepository.currentUser;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final UserModel? user = await _authRepository.signInWithGoogle();

      if (user != null) {
        _userModel = user;
        _currentUser = _authRepository.currentUser;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Utilisateur a annulé le sélecteur Google : pas une erreur,
      // on ne remplit pas _errorMessage pour éviter un SnackBar inutile.
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    String? region,
    String? activityType,
    String? bio,
    String? phoneNumber,
  }) async {
    if (_userModel == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = _userModel!.copyWith(
        fullName: fullName,
        region: region,
        activityType: activityType,
        bio: bio,
        phoneNumber: phoneNumber,
      );

      await _authRepository.updateProfile(updated);

      _userModel = updated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.signOut();
    _currentUser = null;
    _userModel = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
