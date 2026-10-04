import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';
import '../models/user_model.dart';
import 'follow_repository.dart';

/// Double sous-collection, même logique que les likes :
/// - users/{cible}/followers/{toi}   -> existe si tu suis cette personne
/// - users/{toi}/following/{cible}   -> le miroir, pour lister "qui je suis"
///
/// Les deux s'écrivent dans le même batch, avec incrémentation atomique
/// de followersCount / followingCount sur les deux documents users.
class FirestoreFollowRepository implements FollowRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<bool> isFollowing({
    required String currentUserId,
    required String targetUserId,
  }) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUserId)
        .get();
    return doc.exists;
  }

  @override
  Future<bool> toggleFollow({
    required String currentUserId,
    required String targetUserId,
  }) async {
    final usersRef = _firestore.collection(AppConstants.usersCollection);
    final followerRef =
        usersRef.doc(targetUserId).collection('followers').doc(currentUserId);
    final followingRef =
        usersRef.doc(currentUserId).collection('following').doc(targetUserId);

    final alreadyFollowing = await isFollowing(
      currentUserId: currentUserId,
      targetUserId: targetUserId,
    );

    final batch = _firestore.batch();

    if (alreadyFollowing) {
      batch.delete(followerRef);
      batch.delete(followingRef);
      batch.update(usersRef.doc(targetUserId), {
        'followersCount': FieldValue.increment(-1),
      });
      batch.update(usersRef.doc(currentUserId), {
        'followingCount': FieldValue.increment(-1),
      });
    } else {
      batch.set(followerRef, {
        'userId': currentUserId,
        'followedAt': FieldValue.serverTimestamp(),
      });
      batch.set(followingRef, {
        'userId': targetUserId,
        'followedAt': FieldValue.serverTimestamp(),
      });
      batch.update(usersRef.doc(targetUserId), {
        'followersCount': FieldValue.increment(1),
      });
      batch.update(usersRef.doc(currentUserId), {
        'followingCount': FieldValue.increment(1),
      });
    }

    await batch.commit();
    return !alreadyFollowing;
  }

  @override
  Future<List<UserModel>> getFollowers(String userId) {
    return _resolveUsers(_firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection('followers'));
  }

  @override
  Future<List<UserModel>> getFollowing(String userId) {
    return _resolveUsers(_firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection('following'));
  }

  /// Les docs de `followers`/`following` ne stockent que l'UID (comme
  /// ID de doc) ; on va chercher le UserModel complet derrière, en
  /// parallèle plutôt qu'un par un pour ne pas empiler les allers-retours.
  Future<List<UserModel>> _resolveUsers(CollectionReference ref) async {
    final snapshot = await ref.get();
    final usersRef = _firestore.collection(AppConstants.usersCollection);

    final docs = await Future.wait(
      snapshot.docs.map((doc) => usersRef.doc(doc.id).get()),
    );

    return docs
        .where((d) => d.exists)
        .map((d) => UserModel.fromMap(d.data() as Map<String, dynamic>))
        .toList();
  }
}
