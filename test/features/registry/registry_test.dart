import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/features/registry/application/registry_providers.dart';
import 'package:glam/src/features/registry/data/registry_repository.dart';
import 'package:glam/src/features/registry/domain/registry_models.dart';

import '../../helpers/fake_dio_adapter.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/test_client.dart';

void main() {
  group('registry models', () {
    test('package parses', () {
      final p = GitLabPackage.fromJson(
        (fixtureJson('packages') as List).first as Map<String, dynamic>,
      );

      expect(p.id, 901);
      expect(p.name, 'glam-core');
      expect(p.version, '1.4.0');
      expect(p.packageType, 'pub');
      expect(p.createdAt, isNotNull);
    });

    test('package file parses', () {
      final f = PackageFile.fromJson(
        (fixtureJson('package_files') as List).first as Map<String, dynamic>,
      );

      expect(f.fileName, 'glam-core-1.4.0.tar.gz');
      expect(f.size, 204800);
    });

    test('container repo parses with tags_count', () {
      final r = ContainerRepo.fromJson(
        (fixtureJson('registry_repos') as List).last as Map<String, dynamic>,
      );

      expect(r.path, 'team/glam/worker');
      expect(r.tagsCount, 1);
      expect(r.location, 'registry.gitlab.com/team/glam/worker');
    });

    test('registry tag parses size and revision', () {
      final t = RegistryTag.fromJson(
        (fixtureJson('registry_tags') as List).first as Map<String, dynamic>,
      );

      expect(t.name, 'latest');
      expect(t.shortRevision, 'abc123');
      expect(t.totalSize, 52428800);
    });
  });

  group('RegistryRepository', () {
    test('packages lists with filters', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects/42/packages', fixtureJson('packages'));
      final repo = RegistryRepository(client);

      final page = await repo.packages(42, packageType: 'pub', name: 'glam');

      expect(page.items, hasLength(2));
      final query = adapter.lastRequest!.queryParameters;
      expect(query['package_type'], 'pub');
      expect(query['package_name'], 'glam');
    });

    test('packageFiles and deletePackage hit the right paths', () async {
      final (client, adapter) = testClient();
      adapter
        ..get(
          '/projects/42/packages/901/package_files',
          fixtureJson('package_files'),
        )
        ..delete('/projects/42/packages/901');
      final repo = RegistryRepository(client);

      final files = await repo.packageFiles(42, 901);
      expect(files.single.fileName, 'glam-core-1.4.0.tar.gz');

      await repo.deletePackage(42, 901);
      expect(
        adapter.requestsTo('DELETE', '/projects/42/packages/901'),
        hasLength(1),
      );
    });

    test('containerRepos asks for tags_count', () async {
      final (client, adapter) = testClient();
      adapter.get(
        '/projects/42/registry/repositories',
        fixtureJson('registry_repos'),
      );
      final repo = RegistryRepository(client);

      final page = await repo.containerRepos(42);

      expect(page.items, hasLength(2));
      expect(adapter.lastRequest!.queryParameters['tags_count'], true);
    });

    test('tags list and delete encode the tag name', () async {
      final (client, adapter) = testClient();
      adapter
        ..get(
          '/projects/42/registry/repositories/41/tags',
          fixtureJson('registry_tags'),
        )
        ..delete('/projects/42/registry/repositories/41/tags/latest');
      final repo = RegistryRepository(client);

      final page = await repo.registryTags(42, 41);
      expect(page.items.single.name, 'latest');

      await repo.deleteTag(42, 41, 'latest');
      expect(
        adapter.requestsTo(
          'DELETE',
          '/projects/42/registry/repositories/41/tags/latest',
        ),
        hasLength(1),
      );
    });

    test('deleteContainerRepo removes the whole repository', () async {
      final (client, adapter) = testClient();
      adapter.delete('/projects/42/registry/repositories/41');
      final repo = RegistryRepository(client);

      await repo.deleteContainerRepo(42, 41);

      expect(
        adapter.requestsTo('DELETE', '/projects/42/registry/repositories/41'),
        hasLength(1),
      );
    });
  });

  group('registry providers', () {
    late FakeDioAdapter adapter;
    late ProviderContainer container;

    setUp(() {
      final (client, a) = testClient();
      adapter = a;
      container = ProviderContainer(
        overrides: [
          registryRepositoryProvider.overrideWithValue(
            RegistryRepository(client),
          ),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('projectPackagesProvider loads and deletes', () async {
      adapter
        ..get('/projects/42/packages', fixtureJson('packages'))
        ..delete('/projects/42/packages/901')
        ..get('/projects/42/packages', fixtureJson('packages'));

      final state = await container.read(projectPackagesProvider(42).future);
      expect(state.items, hasLength(2));

      await container
          .read(projectPackagesProvider(42).notifier)
          .deletePackage(901);
      await container.read(projectPackagesProvider(42).future);

      expect(
        adapter.requestsTo('DELETE', '/projects/42/packages/901'),
        hasLength(1),
      );
    });

    test('containerReposProvider loads repos', () async {
      adapter.get(
        '/projects/42/registry/repositories',
        fixtureJson('registry_repos'),
      );

      final state = await container.read(containerReposProvider(42).future);

      expect(state.items, hasLength(2));
      expect(state.items.last.path, 'team/glam/worker');
    });

    test('registryTagsProvider deletes a tag and refreshes', () async {
      const loc = (project: 42, repoId: 41);
      adapter
        ..get(
          '/projects/42/registry/repositories/41/tags',
          fixtureJson('registry_tags'),
        )
        ..delete('/projects/42/registry/repositories/41/tags/latest')
        ..get('/projects/42/registry/repositories/41/tags', const []);

      await container.read(registryTagsProvider(loc).future);
      await container
          .read(registryTagsProvider(loc).notifier)
          .deleteTag('latest');
      final state = await container.read(registryTagsProvider(loc).future);

      expect(state.items, isEmpty);
    });
  });
}
