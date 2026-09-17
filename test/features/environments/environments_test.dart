import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/features/environments/application/environments_providers.dart';
import 'package:glam/src/features/environments/data/environments_repository.dart';
import 'package:glam/src/features/environments/domain/environment.dart';

import '../../helpers/fake_dio_adapter.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/test_client.dart';

void main() {
  group('GlEnvironment model', () {
    test('parses state, external URL, and last deployment', () {
      final env = GlEnvironment.fromJson(
        (fixtureJson('environments') as List).first as Map<String, dynamic>,
      );
      expect(env.name, 'production');
      expect(env.isAvailable, isTrue);
      expect(env.externalUrl, 'https://prod.example.com');
      expect(env.lastDeployment?.iid, 7);
      expect(env.lastDeployment?.deployableName, 'deploy:prod');
      expect(env.lastDeployment?.user?.username, 'jane');
    });

    test('stopped env has no last deployment', () {
      final env = GlEnvironment.fromJson(
        (fixtureJson('environments') as List).last as Map<String, dynamic>,
      );
      expect(env.isAvailable, isFalse);
      expect(env.lastDeployment, isNull);
    });

    test('Deployment parses ref, sha, and status', () {
      final dep = Deployment.fromJson(
        (fixtureJson('deployments') as List).last as Map<String, dynamic>,
      );
      expect(dep.iid, 6);
      expect(dep.status, 'failed');
      expect(dep.ref, 'main');
      expect(dep.sha, '1234567890abcdef');
    });
  });

  group('environments repository', () {
    test('lists environments with the states filter', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects/42/environments', fixtureJson('environments'));
      final repo = EnvironmentsRepository(client);

      final page = await repo.environments(42, states: 'available,stopped');

      expect(page.items, hasLength(2));
      expect(
        adapter.lastRequest!.queryParameters['states'],
        'available,stopped',
      );
    });

    test('createEnvironment posts name and external_url', () async {
      final (client, adapter) = testClient();
      adapter.post(
        '/projects/42/environments',
        (fixtureJson('environments') as List).first,
      );
      final repo = EnvironmentsRepository(client);

      final env = await repo.createEnvironment(
        42,
        name: 'review/app',
        externalUrl: 'https://review.example.com',
      );

      expect(env.name, 'production');
      expect(adapter.lastRequest!.data, {
        'name': 'review/app',
        'external_url': 'https://review.example.com',
      });
    });

    test('stop posts and destroy deletes', () async {
      final (client, adapter) = testClient();
      adapter
        ..post(
          '/projects/42/environments/9/stop',
          (fixtureJson('environments') as List).last,
        )
        ..delete('/projects/42/environments/10');
      final repo = EnvironmentsRepository(client);

      final stopped = await repo.stop(42, 9);
      await repo.destroy(42, 10);

      expect(stopped.state, 'stopped');
      expect(
        adapter.requestsTo('DELETE', '/projects/42/environments/10'),
        hasLength(1),
      );
    });

    test('deployments filter by environment', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects/42/deployments', fixtureJson('deployments'));
      final repo = EnvironmentsRepository(client);

      final page = await repo.deployments(42, environmentId: 9);

      expect(page.items, hasLength(2));
      expect(adapter.lastRequest!.queryParameters['environment'], '9');
    });

    test('feature flags list, toggle, delete', () async {
      final (client, adapter) = testClient();
      adapter
        ..get('/projects/42/feature_flags', [
          {
            'id': 1,
            'name': 'new_checkout',
            'description': 'Checkout v2',
            'active': true,
            'version': 2,
            'scopes': [
              {'id': 7, 'environment_scope': 'production', 'active': true},
            ],
          },
          {'id': 2, 'name': 'beta_nav', 'active': false, 'version': 1},
        ])
        ..put('/projects/42/feature_flags/beta_nav', {
          'id': 2,
          'name': 'beta_nav',
          'active': true,
          'version': 1,
        })
        ..delete('/projects/42/feature_flags/beta_nav');
      final repo = EnvironmentsRepository(client);

      final flags = await repo.featureFlags(42);
      expect(flags, hasLength(2));
      expect(flags.first.scopes.single.environmentScope, 'production');
      expect(flags.last.active, isFalse);

      final updated = await repo.updateFeatureFlag(
        42,
        'beta_nav',
        active: true,
      );
      expect(updated.active, isTrue);
      expect((adapter.lastRequest!.data as Map)['active'], true);

      await repo.deleteFeatureFlag(42, 'beta_nav');
      expect(
        adapter.requestsTo('DELETE', '/projects/42/feature_flags/beta_nav'),
        hasLength(1),
      );
    });
  });

  group('environments providers', () {
    late FakeDioAdapter adapter;
    late ProviderContainer container;

    setUp(() {
      final (client, a) = testClient();
      adapter = a;
      container = ProviderContainer(
        overrides: [
          environmentsRepositoryProvider.overrideWithValue(
            EnvironmentsRepository(client),
          ),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('environmentsProvider loads the list', () async {
      adapter.get('/projects/42/environments', fixtureJson('environments'));

      final state = await container.read(environmentsProvider(42).future);

      expect(state.items, hasLength(2));
      expect(state.items.first.name, 'production');
    });

    test('environmentProvider loads one env', () async {
      adapter.get(
        '/projects/42/environments/9',
        (fixtureJson('environments') as List).first,
      );

      const loc = (project: 42, envId: 9);
      final env = await container.read(environmentProvider(loc).future);

      expect(env.externalUrl, 'https://prod.example.com');
    });

    test('deploymentsProvider scopes by environment', () async {
      adapter.get('/projects/42/deployments', fixtureJson('deployments'));

      const loc = (project: 42, envId: 9);
      final state = await container.read(deploymentsProvider(loc).future);

      expect(state.items, hasLength(2));
      expect(adapter.lastRequest!.queryParameters['environment'], '9');
    });
  });
}
