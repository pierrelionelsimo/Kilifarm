import '../models/user_model.dart';

abstract class UserRepository {
  Future<List<UserModel>> searchUsers({
    String? nameQuery,
    String? region,
    String? activityType,
    String? excludeUserId,
  });
}
