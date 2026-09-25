import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../config/constants.dart';
import 'user_repository.dart';

class FirestoreUserRepository implements UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
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

    users.sort((a, b) => a.fullName.compareTo(b.fullName));

    return users;
  }
}
