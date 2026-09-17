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

    test('registry tag list payload carries name/path/location only', () {
      final t = RegistryTag.fromJson(
        (fixtureJson('registry_tags') as List).first as Map<String, dynamic>,
      );

      expect(t.name, 'latest');
      expect(t.path, 'team/glam:latest');
      expect(t.location, 'registry.gitlab.com/team/glam:latest');
      expect(t.shortRevision, isEmpty);
      expect(t.totalSize, isNull);
    });

    test('registry tag detail parses size and revision', () {
      final t = RegistryTag.fromJson(
        fixtureJson('registry_tag') as Map<String, dynamic>,
      );

      expect(t.name, 'latest');
      expect(t.shortRevision, 'abc123');
      expect(t.totalSize, 52428800);
      expect(t.createdAt, isNotNull);
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
      expect(query['order_by'], 'created_at');
      expect(query['sort'], 'desc');
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

    test('registryTag fetches tag detail', () async {
      final (client, adapter) = testClient();
      adapter.get(
        '/projects/42/registry/repositories/41/tags/latest',
        fixtureJson('registry_tag'),
      );
      final repo = RegistryRepository(client);

      final tag = await repo.registryTag(42, 41, 'latest');

      expect(tag.shortRevision, 'abc123');
      expect(tag.totalSize, 52428800);
    });

    test('tags list and delete encode the tag name', () async {
      final (client, adapter) = testClient();
      adapter
        ..get(
          '/projects/42/registry/repositories/41/tags',
          fixtureJson('registry_tags'),
        )
        ..delete('/projects/42/registry/repositories/41/tags/v1.0.0%2Bbuild');
      final repo = RegistryRepository(client);

      final page = await repo.registryTags(42, 41);
      expect(page.items, hasLength(2));

      await repo.deleteTag(42, 41, 'v1.0.0+build');
      expect(
        adapter.requestsTo(
          'DELETE',
          '/projects/42/registry/repositories/41/tags/v1.0.0%2Bbuild',
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

    test('projectPackagesProvider deletes without refetching', () async {
      adapter
        ..get('/projects/42/packages', fixtureJson('packages'))
        ..delete('/projects/42/packages/901');

      const filter = (project: 42, type: null, name: null);
      final state = await container.read(
        projectPackagesProvider(filter).future,
      );
      expect(state.items, hasLength(2));

      await container
          .read(projectPackagesProvider(filter).notifier)
          .deletePackage(901);

      final items = container
          .read(projectPackagesProvider(filter))
          .value!
          .items;
      expect(items.single.id, 902);
      expect(adapter.requestsTo('GET', '/projects/42/packages'), hasLength(1));
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

    test('registryTagDetailProvider loads tag detail', () async {
      adapter.get(
        '/projects/42/registry/repositories/41/tags/latest',
        fixtureJson('registry_tag'),
      );

      final tag = await container.read(
        registryTagDetailProvider((
          project: 42,
          repoId: 41,
          tag: 'latest',
        )).future,
      );

      expect(tag.shortRevision, 'abc123');
    });

    test('registryTagsProvider removes the tag locally', () async {
      const loc = (project: 42, repoId: 41);
      adapter
        ..get(
          '/projects/42/registry/repositories/41/tags',
          fixtureJson('registry_tags'),
        )
        ..delete('/projects/42/registry/repositories/41/tags/latest');

      await container.read(registryTagsProvider(loc).future);
      await container
          .read(registryTagsProvider(loc).notifier)
          .deleteTag('latest');

      final items = container.read(registryTagsProvider(loc)).value!.items;
      expect(items.single.name, 'v1.0.0');
      expect(
        adapter.requestsTo('GET', '/projects/42/registry/repositories/41/tags'),
        hasLength(1),
      );
    });
  });
}
