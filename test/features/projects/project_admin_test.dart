import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/projects/data/projects_repository.dart';
import 'package:glam/src/features/projects/domain/deploy_key.dart';
import 'package:glam/src/features/projects/domain/protected_branch.dart';
import 'package:glam/src/features/projects/domain/webhook.dart';

import '../../helpers/fake_dio_adapter.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/test_client.dart';

void main() {
  group('Webhook model', () {
    test('parses events and url', () {
      final h = Webhook.fromJson(
        (fixtureJson('hooks') as List).first as Map<String, dynamic>,
      );

      expect(h.id, 31);
      expect(h.url, 'https://example.com/hook');
      expect(h.eventLabels, containsAll(['push', 'tag push', 'issues']));
      expect(h.eventFlags['merge_requests_events'], isTrue);
      expect(h.eventFlags['note_events'], isFalse);
      expect(h.enableSslVerification, isTrue);
    });
  });

  group('DeployKey model', () {
    test('parses and shortens the key material', () {
      final k = DeployKey.fromJson(
        (fixtureJson('deploy_keys') as List).first as Map<String, dynamic>,
      );

      expect(k.title, 'CI runner');
      expect(k.canPush, isFalse);
      expect(k.fingerprint.startsWith('…'), isTrue);
      expect(k.fingerprint.length, lessThan(20));
    });

    test('fingerprint handles short material', () {
      const k = DeployKey(id: 1, title: 't', key: 'ssh-ed25519 abc');
      expect(k.fingerprint, 'abc');
    });
  });

  group('ProtectedBranch model', () {
    test('parses access levels and flags', () {
      final list = (fixtureJson('protected_branches') as List)
          .whereType<Map<String, dynamic>>()
          .map(ProtectedBranch.fromJson)
          .toList();

      expect(list.first.name, 'main');
      expect(list.first.pushLevels, [40]);
      expect(list.first.isWildcard, isFalse);
      expect(list.last.name, 'release-*');
      expect(list.last.isWildcard, isTrue);
      expect(list.last.mergeLevels, [30]);
      expect(list.last.allowForcePush, isTrue);
    });

    test('levelLabel maps GitLab access levels', () {
      expect(ProtectedBranch.levelLabel(0), 'No one');
      expect(ProtectedBranch.levelLabel(30), contains('Developers'));
      expect(ProtectedBranch.levelLabel(40), 'Maintainers');
      expect(ProtectedBranch.levelLabel(60), 'Admins');
    });
  });

  group('ProjectsRepository admin endpoints', () {
    test('hooks lists and createHook posts events', () async {
      final (client, adapter) = testClient();
      adapter
        ..get('/projects/42/hooks', fixtureJson('hooks'))
        ..post('/projects/42/hooks', (fixtureJson('hooks') as List).first);
      final repo = ProjectsRepository(client);

      final hooks = await repo.hooks(42);
      expect(hooks, hasLength(1));

      await repo.createHook(
        42,
        url: 'https://example.com/hook',
        token: 'secret',
        events: const {'push_events': true, 'issues_events': true},
      );

      final sent = adapter.lastRequest!.data as Map;
      expect(sent['url'], 'https://example.com/hook');
      expect(sent['token'], 'secret');
      expect(sent['push_events'], true);
      expect(sent['issues_events'], true);
      expect(sent['enable_ssl_verification'], true);
    });

    test('testHook and deleteHook hit the right paths', () async {
      final (client, adapter) = testClient();
      adapter
        ..post('/projects/42/hooks/31/test/push_events', {})
        ..delete('/projects/42/hooks/31');
      final repo = ProjectsRepository(client);

      await repo.testHook(42, 31);
      await repo.deleteHook(42, 31);

      expect(
        adapter.requestsTo('POST', '/projects/42/hooks/31/test/push_events'),
        hasLength(1),
      );
      expect(
        adapter.requestsTo('DELETE', '/projects/42/hooks/31'),
        hasLength(1),
      );
    });

    test('deploy keys list, add, delete', () async {
      final (client, adapter) = testClient();
      adapter
        ..get('/projects/42/deploy_keys', fixtureJson('deploy_keys'))
        ..post(
          '/projects/42/deploy_keys',
          (fixtureJson('deploy_keys') as List).last,
        )
        ..delete('/projects/42/deploy_keys/56');
      final repo = ProjectsRepository(client);

      final keys = await repo.deployKeys(42);
      expect(keys, hasLength(2));

      await repo.addDeployKey(
        42,
        title: 'Deploy bot',
        key: 'ssh-ed25519 BBBB',
        canPush: true,
      );
      final sent = adapter.lastRequest!.data as Map;
      expect(sent['can_push'], true);

      await repo.deleteDeployKey(42, 56);
      expect(
        adapter.requestsTo('DELETE', '/projects/42/deploy_keys/56'),
        hasLength(1),
      );
    });

    test('protected branches list, protect, unprotect', () async {
      final (client, adapter) = testClient();
      adapter
        ..get(
          '/projects/42/protected_branches',
          fixtureJson('protected_branches'),
        )
        ..post(
          '/projects/42/protected_branches',
          (fixtureJson('protected_branches') as List).first,
        )
        ..delete('/projects/42/protected_branches/main');
      final repo = ProjectsRepository(client);

      final branches = await repo.protectedBranches(42);
      expect(branches, hasLength(2));

      await repo.protectBranch(
        42,
        name: 'main',
        pushAccessLevel: 40,
        mergeAccessLevel: 30,
      );
      final sent = adapter.lastRequest!.data as Map;
      expect(sent['name'], 'main');
      expect(sent['push_access_level'], 40);
      expect(sent['merge_access_level'], 30);

      await repo.unprotectBranch(42, 'main');
      expect(
        adapter.requestsTo('DELETE', '/projects/42/protected_branches/main'),
        hasLength(1),
      );
    });

    test('unprotectBranch encodes wildcard names', () async {
      final (client, adapter) = testClient();
      adapter
        ..delete('/projects/42/protected_branches/release-*')
        ..delete('/projects/42/protected_branches/feature%2Fx');
      final repo = ProjectsRepository(client);

      await repo.unprotectBranch(42, 'release-*');
      await repo.unprotectBranch(42, 'feature/x');

      expect(
        adapter.requestsTo(
          'DELETE',
          '/projects/42/protected_branches/release-*',
        ),
        hasLength(1),
      );
      expect(
        adapter.requestsTo(
          'DELETE',
          '/projects/42/protected_branches/feature%2Fx',
        ),
        hasLength(1),
      );
    });
  });

  group('projectAdminActionsProvider', () {
    late FakeDioAdapter adapter;
    late ProviderContainer container;

    setUp(() {
      final (client, a) = testClient();
      adapter = a;
      container = ProviderContainer(
        overrides: [
          projectsRepositoryProvider.overrideWithValue(
            ProjectsRepository(client),
          ),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('addHook refetches the hook list', () async {
      adapter
        ..get('/projects/42/hooks', fixtureJson('hooks'))
        ..post('/projects/42/hooks', (fixtureJson('hooks') as List).first)
        ..get('/projects/42/hooks', fixtureJson('hooks'));

      await container.read(projectHooksProvider(42).future);
      await container
          .read(projectAdminActionsProvider)
          .addHook(42, url: 'https://example.com/x');
      await container.read(projectHooksProvider(42).future);

      expect(adapter.requestsTo('GET', '/projects/42/hooks'), hasLength(2));
    });

    test('protectBranch invalidates the rules list', () async {
      adapter
        ..get(
          '/projects/42/protected_branches',
          fixtureJson('protected_branches'),
        )
        ..post(
          '/projects/42/protected_branches',
          (fixtureJson('protected_branches') as List).first,
        )
        ..get(
          '/projects/42/protected_branches',
          fixtureJson('protected_branches'),
        );

      await container.read(projectProtectedBranchesProvider(42).future);
      await container
          .read(projectAdminActionsProvider)
          .protectBranch(42, name: 'main');
      await container.read(projectProtectedBranchesProvider(42).future);

      expect(
        adapter.requestsTo('GET', '/projects/42/protected_branches'),
        hasLength(2),
      );
    });

    test('deleteDeployKey invalidates the keys list', () async {
      adapter
        ..get('/projects/42/deploy_keys', fixtureJson('deploy_keys'))
        ..delete('/projects/42/deploy_keys/55')
        ..get('/projects/42/deploy_keys', fixtureJson('deploy_keys'));

      await container.read(projectDeployKeysProvider(42).future);
      await container.read(projectAdminActionsProvider).deleteDeployKey(42, 55);
      await container.read(projectDeployKeysProvider(42).future);

      expect(
        adapter.requestsTo('GET', '/projects/42/deploy_keys'),
        hasLength(2),
      );
    });
  });
}
