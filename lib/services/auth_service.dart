import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../config/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
    required String region,
    required String activityType,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Erreur lors de la création du compte');
      }

      final UserModel newUser = UserModel(
        uid: user.uid,
        fullName: fullName,
        email: email,
        region: region,
        activityType: activityType,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(newUser.toMap());

      await user.updateDisplayName(fullName);

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<UserModel?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;
      if (user == null) return null;

      return await fetchUserProfile(user.uid) ??
          await _createFallbackProfile(user);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Connexion (ou inscription automatique) via Google.
  /// Retourne `null` si l'utilisateur annule la connexion depuis le
  /// sélecteur de compte Google — ce n'est pas une erreur à afficher.
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // annulé par l'utilisateur

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      if (user == null) return null;

      // Si un profil existe déjà (utilisateur revenant), on le réutilise.
      final existingProfile = await fetchUserProfile(user.uid);
      if (existingProfile != null) return existingProfile;

      // Sinon, première connexion via Google : on crée le profil
      // avec les infos fournies par le compte Google (nom, photo).
      // Région et type d'activité restent vides — à compléter à
      // l'étape "Profil".
      final UserModel newUser = UserModel(
        uid: user.uid,
        fullName: user.displayName ?? 'Utilisateur',
        email: user.email ?? '',
        profileImageUrl: user.photoURL,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(newUser.toMap());

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Erreur de connexion Google. Réessayez.';
    }
  }

  /// Récupère le profil Firestore d'un utilisateur par son uid.
  /// Retourne `null` si le document n'existe pas (compte orphelin).
  /// Utilisée à la connexion ET au redémarrage de l'app (session persistée),
  /// pour éviter le bug où le profil restait vide après un restart.
  Future<UserModel?> fetchUserProfile(String uid) async {
    final DocumentSnapshot doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();

    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  /// Crée un profil minimal si un compte Auth existe sans document
  /// Firestore associé (cas limite : compte créé hors app, migration...).
  Future<UserModel> _createFallbackProfile(User user) async {
    final UserModel basicUser = UserModel(
      uid: user.uid,
      fullName: user.displayName ?? 'Utilisateur',
      email: user.email ?? '',
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(basicUser.toMap());

    return basicUser;
  }

  /// Met à jour le profil Firestore d'un utilisateur.
  /// Utilise `merge: true` pour ne modifier que les champs présents dans
  /// `user.toMap()` sans écraser d'éventuels champs gérés ailleurs
  /// (ex: followersCount, mis à jour par d'autres écrans plus tard).
  Future<void> updateProfile(UserModel user) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw 'Erreur lors de la mise à jour du profil. Réessayez.';
    }
  }

  Future<void> signOut() async {
    // Déconnecte aussi la session Google si elle existe — sinon la
    // prochaine tentative de connexion Google resélectionne le même
    // compte automatiquement sans montrer le sélecteur.
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé. Veuillez vous connecter.';
      case 'invalid-email':
        return 'Adresse email invalide.';
      case 'operation-not-allowed':
        return 'Opération non autorisée. Contactez le support.';
      case 'weak-password':
        return 'Mot de passe trop faible. Minimum 6 caractères.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'user-not-found':
        return 'Aucun compte trouvé avec cet email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email ou mot de passe incorrect.';
      case 'network-request-failed':
        return 'Erreur réseau. Vérifiez votre connexion internet.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez dans quelques minutes.';
      default:
        return 'Erreur : ${e.message}';
    }
  }
}
