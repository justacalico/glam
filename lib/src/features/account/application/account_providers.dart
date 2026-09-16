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
}
