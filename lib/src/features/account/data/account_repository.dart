import 'package:glam/src/core/api/gitlab_api_client.dart';
import 'package:glam/src/features/account/domain/account_models.dart';

/// Account-level endpoints: `/user/keys`, `/personal_access_tokens`,
/// `/notification_settings`.
class AccountRepository {
  const AccountRepository(this._client);

  final GitLabApiClient _client;

  Future<List<SshKey>> sshKeys() {
    return _client.getAll(
      '/user/keys',
      decoder: (j) => SshKey.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<SshKey> addSshKey({
    required String title,
    required String key,
    DateTime? expiresAt,
  }) {
    return _client.post(
      '/user/keys',
      body: {
        'title': title,
        'key': key,
        if (expiresAt != null)
          'expires_at': expiresAt.toIso8601String().substring(0, 10),
      },
      decoder: (j) => SshKey.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<void> deleteSshKey(int keyId) {
    return _client.delete('/user/keys/$keyId');
  }

  Future<List<PersonalAccessToken>> personalAccessTokens({
    bool activeOnly = true,
  }) {
    return _client.getAll(
      '/personal_access_tokens',
      query: {if (activeOnly) 'state': 'active'},
      decoder: (j) => PersonalAccessToken.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// The token this session authenticates with.
  Future<PersonalAccessToken> currentToken() {
    return _client.get(
      '/personal_access_tokens/self',
      decoder: (j) => PersonalAccessToken.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Revokes a token. GitLab accepts DELETE on `/self` or `/:id`.
  Future<void> revokeToken(int tokenId) {
    return _client.delete('/personal_access_tokens/$tokenId');
  }

  Future<NotificationSettings> notificationSettings() {
    return _client.get(
      '/notification_settings',
      decoder: (j) => NotificationSettings.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<NotificationSettings> updateNotificationSettings({
    String? level,
    String? notificationEmail,
    Map<String, bool> events = const {},
  }) {
    return _client.put(
      '/notification_settings',
      body: {
        'level': ?level,
        'notification_email': ?notificationEmail,
        ...events,
      },
      decoder: (j) => NotificationSettings.fromJson(j! as Map<String, dynamic>),
    );
  }
}
