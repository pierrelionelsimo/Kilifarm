import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? bio;
  final String? region;
  final String? activityType; // 'agriculteur', 'eleveur', 'mixte'
  final DateTime createdAt;
  final int followersCount;
  final int followingCount;
  final int postsCount;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.profileImageUrl,
    this.bio,
    this.region,
    this.activityType,
    required this.createdAt,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
      bio: map['bio'],
      region: map['region'],
      activityType: map['activityType'],
      // FIX: cast explicite + valeur de repli si le champ est absent
      // ou pas encore écrit (ex: juste après un serverTimestamp()).
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      followersCount: map['followersCount'] ?? 0,
      followingCount: map['followingCount'] ?? 0,
      postsCount: map['postsCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'region': region,
      'activityType': activityType,
      'createdAt': createdAt,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
    };
  }

  UserModel copyWith({
    String? fullName,
    String? bio,
    String? region,
    String? activityType,
    String? profileImageUrl,
    String? phoneNumber,
  }) {
    return UserModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      region: region ?? this.region,
      activityType: activityType ?? this.activityType,
      createdAt: createdAt,
      followersCount: followersCount,
      followingCount: followingCount,
      postsCount: postsCount,
    );
  }
}
