import '../entities/user.dart';

/// Pure domain repository contract abstracting user and artist operations.
abstract interface class UserRepository {
  /// Retrieves public user details by unique Audius user ID.
  Future<User?> getUser(String userId);

  /// Retrieves top popular users/artists by follower count from `/users/top`.
  Future<List<User>> getTopUsers({int limit = 12, int offset = 0});

  /// Retrieves related artists for [userId] from `/users/{id}/related`.
  Future<List<User>> getRelatedUsers(
    String userId, {
    int limit = 10,
    int offset = 0,
  });
}
