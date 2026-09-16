import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/features/issues/domain/issue.dart';
import 'package:glam/src/features/merge_requests/domain/merge_request.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/repository/domain/repo_models.dart';
import 'package:glam/src/features/search/application/search_providers.dart';
import 'package:glam/src/features/search/data/search_repository.dart';
import 'package:glam/src/features/search/domain/search_result.dart';
import 'package:glam/src/features/snippets/domain/snippet.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_client.dart';

void main() {
  group('BlobResult', () {
    test('parses path, ref, and snippet data', () {
      final b = BlobResult.fromJson(
        (fixtureJson('blobs') as List).first as Map<String, dynamic>,
      );
      expect(b.path, 'lib/main.dart');
      expect(b.ref, 'main');
      expect(b.projectId, 42);
      expect(b.data, contains('runApp'));
    });
  });

  group('SearchRepository', () {
    test('global search hits /search with scope', () async {
      final (client, adapter) = testClient();
      adapter.get('/search', fixtureJson('issues'));
      final repo = SearchRepository(client);

      final page = await repo.search(SearchScope.issues, 'login');

      expect(page.items.first, isA<Issue>());
      final q = adapter.lastRequest!.queryParameters;
      expect(q['scope'], 'issues');
      expect(q['search'], 'login');
    });

    test('decodes per scope into the right model', () async {
      final (client, adapter) = testClient();
      adapter.get(
        '/search',
        fixtureJson('project') is List
            ? fixtureJson('project')
            : [fixtureJson('project')],
      );
      final repo = SearchRepository(client);

      final projects = await repo.search(SearchScope.projects, 'glam');
      expect(projects.items.first, isA<Project>());

      adapter.routes.clear();
      adapter.get('/search', fixtureJson('mrs'));
      final mrs = await repo.search(SearchScope.mergeRequests, 'glam');
      expect(mrs.items.first, isA<MergeRequest>());

      adapter.routes.clear();
      adapter.get('/search', fixtureJson('snippets'));
      final snips = await repo.search(SearchScope.snippetTitles, 'dep');
      expect(snips.items.first, isA<Snippet>());
    });

    test('project search uses the project path and blob scope', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects/42/search', fixtureJson('blobs'));
      final repo = SearchRepository(client);

      final page = await repo.searchInProject(
        42,
        SearchScope.blobs,
        'runApp',
        ref: 'main',
      );

      expect(page.items.first, isA<BlobResult>());
      expect(adapter.lastRequest!.path, '/projects/42/search');
      expect(adapter.lastRequest!.queryParameters['ref'], 'main');
    });

    test('group search uses the group path', () async {
      final (client, adapter) = testClient();
      adapter.get('/groups/9/search', fixtureJson('issues'));
      final repo = SearchRepository(client);

      final page = await repo.searchInGroup(9, SearchScope.issues, 'x');

      expect(page.items, isNotEmpty);
      expect(adapter.lastRequest!.path, '/groups/9/search');
    });
  });

  group('searchProvider', () {
    test('picks the endpoint from the query container', () async {
      final (client, adapter) = testClient();
      adapter.get(
        '/projects/42/search',
        fixtureJson('commit') is List
            ? fixtureJson('commit')
            : [fixtureJson('commit')],
      );
      final container = ProviderContainer(
        overrides: [
          searchRepositoryProvider.overrideWithValue(SearchRepository(client)),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(
        searchProvider((
          scope: SearchScope.commits,
          term: 'init',
          projectId: 42,
          groupId: null,
        )).future,
      );

      expect(state.items.first, isA<Commit>());
    });
  });
}
