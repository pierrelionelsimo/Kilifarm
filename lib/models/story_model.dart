import 'package:cloud_firestore/cloud_firestore.dart';

/// Une story expire 24h après sa création — pas de champ `expiresAt`
/// stocké séparément, calculé à la volée depuis `createdAt` pour
/// éviter un champ redondant à tenir synchronisé.
class StoryModel {
  final String id;
  final String userId;
  final String userName;
  final String imageUrl;
  final DateTime createdAt;

  StoryModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.imageUrl,
    required this.createdAt,
  });

  bool get isExpired =>
      DateTime.now().difference(createdAt) > const Duration(hours: 24);

  factory StoryModel.fromMap(String id, Map<String, dynamic> map) {
    return StoryModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
    };
  }
}
