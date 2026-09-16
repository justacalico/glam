import 'package:glam/src/core/api/gitlab_api_client.dart';
import 'package:glam/src/features/auth/domain/user.dart';

/// Validates credentials against `GET /user` and fetches the signed-in
/// profile.
class AuthRepository {
  const AuthRepository(this._client);

  final GitLabApiClient _client;

  Future<GitLabUser> fetchCurrentUser() {
    return _client.get(
      '/user',
      decoder: (json) {
        return GitLabUser.fromJson(json! as Map<String, dynamic>);
      },
    );
  }

  Future<GitLabUser> fetchUser(int id) {
    return _client.get(
      '/users/$id',
      decoder: (json) {
        return GitLabUser.fromJson(json! as Map<String, dynamic>);
      },
    );
  }

  Future<GitLabUser> fetchUserByUsername(String username) async {
    final users = await _client.getList(
      '/users',
      query: {'username': username},
      decoder: (json) => GitLabUser.fromJson(json! as Map<String, dynamic>),
    );
    if (users.isEmpty) {
      throw const FormatException('user not found');
    }
    return users.first;
  }
}
