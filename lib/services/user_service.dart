import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../config/constants.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Recherche des utilisateurs par région et/ou type d'activité
  /// (filtrés côté serveur, sans index composite nécessaire — deux
  /// égalités simples se combinent sans souci sur Firestore), puis
  /// par nom (filtré côté client, insensible à la casse).
  ///
  /// Choix volontaire pour V1 : pas de recherche plein-texte via un
  /// service tiers (Algolia...) — hors scope, un fetch limité +
  /// filtre en mémoire suffit largement au volume d'utilisateurs
  /// attendu au démarrage.
  Future<List<UserModel>> searchUsers({
    String? nameQuery,
    String? region,
    String? activityType,
    String? excludeUserId,
  }) async {
    Query query = _firestore.collection(AppConstants.usersCollection);

    if (region != null && region.isNotEmpty) {
      query = query.where('region', isEqualTo: region);
    }
    if (activityType != null && activityType.isNotEmpty) {
      query = query.where('activityType', isEqualTo: activityType);
    }

    final snapshot = await query.limit(100).get();

    var users = snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    if (excludeUserId != null) {
      users = users.where((u) => u.uid != excludeUserId).toList();
    }

    if (nameQuery != null && nameQuery.trim().isNotEmpty) {
      final lower = nameQuery.trim().toLowerCase();
      users =
          users.where((u) => u.fullName.toLowerCase().contains(lower)).toList();
    }

    // Tri alphabétique côté client — évite un orderBy() Firestore qui
    // exigerait, lui, un vrai index composite combiné aux filtres.
    users.sort((a, b) => a.fullName.compareTo(b.fullName));

    return users;
  }
}
