import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/features/account/data/account_repository.dart';
import 'package:glam/src/features/account/domain/account_models.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(ref.watch(apiClientProvider)),
);

final sshKeysProvider = FutureProvider<List<SshKey>>(
  (ref) => ref.watch(accountRepositoryProvider).sshKeys(),
);

final gpgKeysProvider = FutureProvider<List<GpgKey>>(
  (ref) => ref.watch(accountRepositoryProvider).gpgKeys(),
);

final personalAccessTokensProvider = FutureProvider<List<PersonalAccessToken>>(
  (ref) => ref.watch(accountRepositoryProvider).personalAccessTokens(),
);

/// The token this session authenticates with — revoking it signs
/// the user out, so the UI needs to know which row it is.
final currentTokenProvider = FutureProvider<int?>(
  (ref) async => (await ref.watch(accountRepositoryProvider).currentToken()).id,
);

final notificationSettingsProvider = FutureProvider<NotificationSettings>(
  (ref) => ref.watch(accountRepositoryProvider).notificationSettings(),
);

/// Per-project notification level and custom events.
final projectNotificationProvider =
    FutureProvider.family<NotificationSettings, Object>(
      (ref, projectId) => ref
          .watch(accountRepositoryProvider)
          .projectNotificationSettings(projectId),
    );

/// Per-group notification level and custom events.
final groupNotificationProvider =
    FutureProvider.family<NotificationSettings, Object>(
      (ref, groupId) => ref
          .watch(accountRepositoryProvider)
          .groupNotificationSettings(groupId),
    );

/// Account mutations; each refetches its list on success.
final accountActionsProvider = Provider<AccountActions>(AccountActions.new);

class AccountActions {
  const AccountActions(this._ref);

  final Ref _ref;

  AccountRepository get _repo => _ref.read(accountRepositoryProvider);

  Future<void> addSshKey({
    required String title,
    required String key,
    DateTime? expiresAt,
  }) async {
    await _repo.addSshKey(title: title, key: key, expiresAt: expiresAt);
    _ref.invalidate(sshKeysProvider);
  }

  Future<void> deleteSshKey(int keyId) async {
    await _repo.deleteSshKey(keyId);
    _ref.invalidate(sshKeysProvider);
  }

  Future<void> addGpgKey(String key) async {
    await _repo.addGpgKey(key);
    _ref.invalidate(gpgKeysProvider);
  }

  Future<void> deleteGpgKey(int keyId) async {
    await _repo.deleteGpgKey(keyId);
    _ref.invalidate(gpgKeysProvider);
  }

  Future<void> revokeToken(int tokenId) async {
    await _repo.revokeToken(tokenId);
    _ref.invalidate(personalAccessTokensProvider);
  }

  Future<void> setNotificationLevel(String level) async {
    await _repo.updateNotificationSettings(level: level);
    _ref.invalidate(notificationSettingsProvider);
  }

  Future<void> toggleNotificationEvent(String event, bool on) async {
    await _repo.updateNotificationSettings(events: {event: on});
    _ref.invalidate(notificationSettingsProvider);
  }

  Future<void> setProjectNotificationLevel(
    Object projectId,
    String level,
  ) async {
    await _repo.updateProjectNotificationSettings(projectId, level: level);
    _ref.invalidate(projectNotificationProvider(projectId));
  }

  Future<void> toggleProjectNotificationEvent(
    Object projectId,
    String event,
    bool on,
  ) async {
    await _repo.updateProjectNotificationSettings(
      projectId,
      events: {event: on},
    );
    _ref.invalidate(projectNotificationProvider(projectId));
  }

  Future<void> setGroupNotificationLevel(Object groupId, String level) async {
    await _repo.updateGroupNotificationSettings(groupId, level: level);
    _ref.invalidate(groupNotificationProvider(groupId));
  }

  Future<void> toggleGroupNotificationEvent(
    Object groupId,
    String event,
    bool on,
  ) async {
    await _repo.updateGroupNotificationSettings(groupId, events: {event: on});
    _ref.invalidate(groupNotificationProvider(groupId));
  }
}
