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

  /// Edits the signed-in user's profile (`PUT /user`). Only fields the
  /// caller passes are sent; send an empty string to clear one.
  Future<GitLabUser> updateProfile({
    String? name,
    String? bio,
    String? location,
    String? publicEmail,
    String? websiteUrl,
    String? pronouns,
    String? organization,
    String? jobTitle,
    String? twitter,
    String? linkedin,
  }) {
    return _client.put(
      '/user',
      body: {
        'name': ?name,
        'bio': ?bio,
        'location': ?location,
        'public_email': ?publicEmail,
        'website_url': ?websiteUrl,
        'pronouns': ?pronouns,
        'organization': ?organization,
        'job_title': ?jobTitle,
        'twitter': ?twitter,
        'linkedin': ?linkedin,
      },
      decoder: (json) => GitLabUser.fromJson(json! as Map<String, dynamic>),
    );
  }

  /// Sets the emoji status (`PUT /user/status`). Pass empty strings to
  /// clear it.
  Future<({String? emoji, String? message})> updateStatus({
    required String emoji,
    required String message,
  }) {
    return _client.put(
      '/user/status',
      body: {'emoji': emoji, 'message': message},
      decoder: (json) {
        final map = json! as Map<String, dynamic>;
        return (
          emoji: map['emoji'] as String?,
          message: map['message'] as String?,
        );
      },
    );
  }
}
