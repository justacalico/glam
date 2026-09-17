import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/features/account/application/account_providers.dart';
import 'package:glam/src/features/account/data/account_repository.dart';
import 'package:glam/src/features/account/domain/account_models.dart';

import '../../helpers/fake_dio_adapter.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/test_client.dart';

void main() {
  group('SshKey', () {
    test('parses and fingerprints the key material', () {
      final k = SshKey.fromJson(
        (fixtureJson('ssh_keys') as List).first as Map<String, dynamic>,
      );

      expect(k.title, 'Work laptop');
      expect(k.fingerprint.startsWith('…'), isTrue);
      expect(k.expiresAt, isNotNull);
      expect(k.lastUsedAt, isNotNull);
    });

    test('fingerprint handles irregular spacing', () {
      const k = SshKey(id: 1, title: 't', key: 'ssh-ed25519  abc');
      expect(k.fingerprint, 'abc');
    });
  });

  group('PersonalAccessToken', () {
    test('parses scopes, revoked and expiry', () {
      final list = (fixtureJson('personal_access_tokens') as List)
          .whereType<Map<String, dynamic>>()
          .map(PersonalAccessToken.fromJson)
          .toList();

      expect(list.first.name, 'glam-app');
      expect(list.first.scopes, ['api', 'read_user']);
      expect(list.first.active, isTrue);
      expect(list.first.expired, isFalse);
      expect(list.last.revoked, isTrue);
      expect(list.last.expired, isTrue);
    });

    test('expired flips on the day itself', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final t = PersonalAccessToken(id: 1, name: 'x', expiresAt: today);
      expect(t.expired, isTrue);
    });
  });

  group('NotificationSettings', () {
    test('parses level and known event toggles', () {
      final s = NotificationSettings.fromJson(
        fixtureJson('notification_settings') as Map<String, dynamic>,
      );

      expect(s.level, 'custom');
      expect(s.notificationEmail, 'me@example.com');
      expect(s.events['new_note'], isTrue);
      expect(s.events['failed_pipeline'], isTrue);
      expect(s.events.containsKey('unknown_key'), isFalse);
    });

    test('mention is a valid level', () {
      final s = NotificationSettings.fromJson(const {'level': 'mention'});
      expect(s.level, 'mention');
      expect(NotificationSettings.levelLabels.containsKey('mention'), isTrue);
    });
  });

  group('AccountRepository', () {
    test('ssh keys list, add, delete', () async {
      final (client, adapter) = testClient();
      adapter
        ..get('/user/keys', fixtureJson('ssh_keys'))
        ..post('/user/keys', (fixtureJson('ssh_keys') as List).first)
        ..delete('/user/keys/10');
      final repo = AccountRepository(client);

      final keys = await repo.sshKeys();
      expect(keys, hasLength(1));

      await repo.addSshKey(title: 'Work laptop', key: 'ssh-ed25519 AAAA');
      final sent = adapter.lastRequest!.data as Map;
      expect(sent['title'], 'Work laptop');
      expect(sent['key'], 'ssh-ed25519 AAAA');

      await repo.deleteSshKey(10);
      expect(adapter.requestsTo('DELETE', '/user/keys/10'), hasLength(1));
    });

    test('gpg keys list, add and delete', () async {
      final (client, adapter) = testClient();
      adapter
        ..get('/user/gpg_keys', fixtureJson('gpg_keys'))
        ..post('/user/gpg_keys', (fixtureJson('gpg_keys') as List).first)
        ..delete('/user/gpg_keys/20');
      final repo = AccountRepository(client);

      final keys = await repo.gpgKeys();
      expect(keys, hasLength(1));
      expect(keys.first.emails, ['calico@example.com']);
      expect(keys.first.subkeyIds.first, 'A1B2C3D4E5F60708');

      await repo.addGpgKey('armored-key');
      expect((adapter.lastRequest!.data as Map)['key'], 'armored-key');

      await repo.deleteGpgKey(20);
      expect(adapter.requestsTo('DELETE', '/user/gpg_keys/20'), hasLength(1));
    });

    test('addSshKey sends the expiry date as YYYY-MM-DD', () async {
      final (client, adapter) = testClient();
      adapter.post('/user/keys', (fixtureJson('ssh_keys') as List).first);
      final repo = AccountRepository(client);

      await repo.addSshKey(
        title: 't',
        key: 'k',
        expiresAt: DateTime(2026, 5, 1, 13, 30),
      );

      expect((adapter.lastRequest!.data as Map)['expires_at'], '2026-05-01');
    });

    test('tokens list filters active by default', () async {
      final (client, adapter) = testClient();
      adapter
        ..get('/personal_access_tokens', fixtureJson('personal_access_tokens'))
        ..get('/personal_access_tokens', fixtureJson('personal_access_tokens'))
        ..delete('/personal_access_tokens/77');
      final repo = AccountRepository(client);

      await repo.personalAccessTokens();
      expect(adapter.lastRequest!.queryParameters['state'], 'active');

      await repo.personalAccessTokens(activeOnly: false);
      expect(
        adapter.lastRequest!.queryParameters.containsKey('state'),
        isFalse,
      );

      await repo.revokeToken(77);
      expect(
        adapter.requestsTo('DELETE', '/personal_access_tokens/77'),
        hasLength(1),
      );
    });

    test('currentToken reads /personal_access_tokens/self', () async {
      final (client, adapter) = testClient();
      adapter.get(
        '/personal_access_tokens/self',
        (fixtureJson('personal_access_tokens') as List).first,
      );
      final repo = AccountRepository(client);

      final t = await repo.currentToken();

      expect(t.id, 77);
      expect(
        adapter.requestsTo('GET', '/personal_access_tokens/self'),
        hasLength(1),
      );
    });

    test('notification settings get and put', () async {
      final (client, adapter) = testClient();
      adapter
        ..get('/notification_settings', fixtureJson('notification_settings'))
        ..put('/notification_settings', fixtureJson('notification_settings'));
      final repo = AccountRepository(client);

      final s = await repo.notificationSettings();
      expect(s.level, 'custom');

      await repo.updateNotificationSettings(
        level: 'watch',
        events: const {'new_issue': true},
      );
      final sent = adapter.lastRequest!.data as Map;
      expect(sent['level'], 'watch');
      expect(sent['new_issue'], true);
    });
  });

  group('accountActionsProvider', () {
    late FakeDioAdapter adapter;
    late ProviderContainer container;

    setUp(() {
      final (client, a) = testClient();
      adapter = a;
      container = ProviderContainer(
        overrides: [
          accountRepositoryProvider.overrideWithValue(
            AccountRepository(client),
          ),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('addSshKey refetches the keys list', () async {
      adapter
        ..get('/user/keys', fixtureJson('ssh_keys'))
        ..post('/user/keys', (fixtureJson('ssh_keys') as List).first)
        ..get('/user/keys', fixtureJson('ssh_keys'));

      await container.read(sshKeysProvider.future);
      await container
          .read(accountActionsProvider)
          .addSshKey(title: 't', key: 'k');
      await container.read(sshKeysProvider.future);

      expect(adapter.requestsTo('GET', '/user/keys'), hasLength(2));
    });

    test('revokeToken refetches the token list', () async {
      adapter
        ..get('/personal_access_tokens', fixtureJson('personal_access_tokens'))
        ..delete('/personal_access_tokens/77')
        ..get('/personal_access_tokens', fixtureJson('personal_access_tokens'));

      await container.read(personalAccessTokensProvider.future);
      await container.read(accountActionsProvider).revokeToken(77);
      await container.read(personalAccessTokensProvider.future);

      expect(
        adapter.requestsTo('GET', '/personal_access_tokens'),
        hasLength(2),
      );
    });

    test('setNotificationLevel refetches settings', () async {
      adapter
        ..get('/notification_settings', fixtureJson('notification_settings'))
        ..put('/notification_settings', fixtureJson('notification_settings'))
        ..get('/notification_settings', fixtureJson('notification_settings'));

      await container.read(notificationSettingsProvider.future);
      await container
          .read(accountActionsProvider)
          .setNotificationLevel('watch');
      await container.read(notificationSettingsProvider.future);

      expect(adapter.requestsTo('GET', '/notification_settings'), hasLength(2));
    });

    test('toggleNotificationEvent puts only the event flag', () async {
      adapter
        ..get('/notification_settings', fixtureJson('notification_settings'))
        ..put('/notification_settings', fixtureJson('notification_settings'))
        ..get('/notification_settings', fixtureJson('notification_settings'));

      await container.read(notificationSettingsProvider.future);
      await container
          .read(accountActionsProvider)
          .toggleNotificationEvent('new_issue', true);
      await container.read(notificationSettingsProvider.future);

      final puts = adapter.requestsTo('PUT', '/notification_settings');
      expect(puts, hasLength(1));
      expect((puts.single.data as Map)['new_issue'], isTrue);
      expect((puts.single.data as Map).containsKey('level'), isFalse);
    });

    test('project notification settings get and put', () async {
      adapter
        ..get(
          '/projects/42/notification_settings',
          fixtureJson('notification_settings'),
        )
        ..put(
          '/projects/42/notification_settings',
          fixtureJson('notification_settings'),
        )
        ..get(
          '/projects/42/notification_settings',
          fixtureJson('notification_settings'),
        );

      await container.read(projectNotificationProvider(42).future);
      await container
          .read(accountActionsProvider)
          .setProjectNotificationLevel(42, 'watch');
      await container.read(projectNotificationProvider(42).future);

      final puts = adapter.requestsTo(
        'PUT',
        '/projects/42/notification_settings',
      );
      expect(puts, hasLength(1));
      expect((puts.single.data as Map)['level'], 'watch');
      expect(
        adapter.requestsTo('GET', '/projects/42/notification_settings'),
        hasLength(2),
      );
    });

    test('toggleProjectNotificationEvent puts only the event flag', () async {
      adapter
        ..put(
          '/projects/42/notification_settings',
          fixtureJson('notification_settings'),
        )
        ..get(
          '/projects/42/notification_settings',
          fixtureJson('notification_settings'),
        );

      await container
          .read(accountActionsProvider)
          .toggleProjectNotificationEvent(42, 'new_issue', true);
      await container.read(projectNotificationProvider(42).future);

      final sent = adapter.requestsTo(
        'PUT',
        '/projects/42/notification_settings',
      );
      expect((sent.single.data as Map)['new_issue'], isTrue);
      expect((sent.single.data as Map).containsKey('level'), isFalse);
    });

    test('group notification settings get and put', () async {
      adapter
        ..get(
          '/groups/9/notification_settings',
          fixtureJson('notification_settings'),
        )
        ..put(
          '/groups/9/notification_settings',
          fixtureJson('notification_settings'),
        )
        ..get(
          '/groups/9/notification_settings',
          fixtureJson('notification_settings'),
        );

      await container.read(groupNotificationProvider(9).future);
      await container
          .read(accountActionsProvider)
          .setGroupNotificationLevel(9, 'participating');
      await container.read(groupNotificationProvider(9).future);

      final puts = adapter.requestsTo('PUT', '/groups/9/notification_settings');
      expect(puts, hasLength(1));
      expect((puts.single.data as Map)['level'], 'participating');
      expect(
        adapter.requestsTo('GET', '/groups/9/notification_settings'),
        hasLength(2),
      );
    });
  });
}
