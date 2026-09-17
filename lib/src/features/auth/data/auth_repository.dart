import 'package:glam/src/core/api/gitlab_api_client.dart';
import 'package:glam/src/features/auth/domain/user.dart';
import 'package:glam/src/features/profile/domain/membership.dart';

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

  /// Users following [id] (`/users/:id/followers`).
  Future<List<GitLabUser>> userFollowers(int id) {
    return _client.getAll(
      '/users/$id/followers',
      decoder: (j) => GitLabUser.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Users [id] follows (`/users/:id/followed_users`).
  Future<List<GitLabUser>> userFollowing(int id) {
    return _client.getAll(
      '/users/$id/followed_users',
      decoder: (j) => GitLabUser.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Groups and projects the signed-in user belongs to
  /// (`/user/memberships`).
  Future<List<Membership>> userMemberships() {
    return _client.getAll(
      '/user/memberships',
      decoder: (j) => Membership.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Users the signed-in account follows (`/user/followed_users`).
  Future<List<GitLabUser>> myFollowed() {
    return _client.getAll(
      '/user/followed_users',
      decoder: (j) => GitLabUser.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<GitLabUser> followUser(int id) {
    return _client.post(
      '/users/$id/follow',
      decoder: (j) => GitLabUser.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<GitLabUser> unfollowUser(int id) {
    return _client.post(
      '/users/$id/unfollow',
      decoder: (j) => GitLabUser.fromJson(j! as Map<String, dynamic>),
    );
  }
}
