import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/features/repository/application/repository_providers.dart';
import 'package:glam/src/features/repository/data/repository_repository.dart';

import '../../helpers/fake_dio_adapter.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/test_client.dart';

void main() {
  late FakeDioAdapter adapter;
  late ProviderContainer container;

  setUp(() {
    final (client, a) = testClient();
    adapter = a;
    container = ProviderContainer(
      overrides: [
        repositoryRepositoryProvider.overrideWithValue(
          RepositoryRepository(client),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('treeProvider loads and sorts a directory', () async {
    adapter.get('/projects/42/repository/tree', [
      {'name': 'zeta.dart', 'path': 'zeta.dart', 'type': 'blob'},
      {'name': 'alpha.dart', 'path': 'alpha.dart', 'type': 'blob'},
      {'name': 'src', 'path': 'src', 'type': 'tree'},
    ]);

    const loc = (project: 42, ref: 'main', path: null);
    final state = await container.read(treeProvider(loc).future);

    expect(sortTreeEntries(state.items).map((e) => e.name), [
      'src',
      'alpha.dart',
      'zeta.dart',
    ]);
  });

  test('repoFileProvider fetches a file', () async {
    adapter.get(
      '/projects/42/repository/files/README.md',
      fixtureJson('repo_file'),
    );

    const loc = (project: 42, path: 'README.md', ref: null);
    final file = await container.read(repoFileProvider(loc).future);

    expect(file.path, 'lib/main.dart');
  });

  test('commitsProvider paginates', () async {
    adapter
      ..get(
        '/projects/42/repository/commits',
        [fixtureJson('commit')],
        headers: {
          'x-next-page': ['2'],
        },
      )
      ..get('/projects/42/repository/commits', [fixtureJson('commit')]);

    const loc = (project: 42, ref: null, path: null);
    await container.read(commitsProvider(loc).future);
    await container.read(commitsProvider(loc).notifier).loadMore();

    final state = container.read(commitsProvider(loc)).value!;
    expect(state.items, hasLength(2));
    expect(state.hasMore, isFalse);
  });

  test('commitsProvider sends the path filter', () async {
    adapter.get('/projects/42/repository/commits', [fixtureJson('commit')]);

    const loc = (project: 42, ref: 'main', path: 'lib/main.dart');
    await container.read(commitsProvider(loc).future);

    final sent = adapter.requestsTo('GET', '/projects/42/repository/commits');
    expect(sent.single.uri.queryParameters['path'], 'lib/main.dart');
    expect(sent.single.uri.queryParameters['ref_name'], 'main');
  });

  test('branchesProvider loads branches', () async {
    adapter.get('/projects/7/repository/branches', fixtureJson('branches'));

    final state = await container.read(branchesProvider(7).future);

    expect(state.items, hasLength(2));
    expect(state.items.first.isDefault, isTrue);
  });

  test('tagsProvider loads tags', () async {
    adapter.get('/projects/7/repository/tags', fixtureJson('tags'));

    final state = await container.read(tagsProvider(7).future);

    expect(state.items.first.name, 'v1.2.0');
  });

  test('releasesProvider loads releases', () async {
    adapter.get('/projects/7/releases', fixtureJson('releases'));

    final state = await container.read(releasesProvider(7).future);

    expect(state.items.single.tagName, 'v1.2.0');
  });

  test('commitProvider and commitDiffProvider fetch detail', () async {
    adapter
      ..get('/projects/7/repository/commits/abc', fixtureJson('commit'))
      ..get(
        '/projects/7/repository/commits/abc/diff',
        fixtureJson('commit_diff'),
      );

    const loc = (project: 7, sha: 'abc');
    final commit = await container.read(commitProvider(loc).future);
    final diffs = await container.read(commitDiffProvider(loc).future);

    expect(commit.shortId, '61049424');
    expect(diffs, hasLength(2));
  });

  test('languagesProvider decodes the map', () async {
    adapter.get('/projects/7/languages', {'Dart': 100.0});

    final langs = await container.read(languagesProvider(7).future);

    expect(langs['Dart'], 100.0);
  });

  test('blameProvider loads hunks for a file', () async {
    adapter.get(
      '/projects/42/repository/files/lib%2Fmain.dart/blame',
      fixtureJson('blame'),
    );

    const loc = (project: 42, path: 'lib/main.dart', ref: 'main');
    final hunks = await container.read(blameProvider(loc).future);

    expect(hunks, hasLength(2));
    expect(hunks.last.lines.last, '}');
  });

  test('compareProvider loads commits and diffs', () async {
    adapter.get('/projects/42/repository/compare', fixtureJson('compare'));

    const loc = (project: 42, from: 'main', to: 'dev');
    final result = await container.read(compareProvider(loc).future);

    expect(result.commits, hasLength(1));
    expect(result.diffs, hasLength(2));
    expect(result.diffs.first.newPath, 'lib/main.dart');
  });

  test('commitStatusesProvider loads checks', () async {
    adapter.get(
      '/projects/42/repository/commits/abc123/statuses',
      fixtureJson('commit_statuses'),
    );

    const loc = (project: 42, sha: 'abc123');
    final statuses = await container.read(commitStatusesProvider(loc).future);

    expect(statuses, hasLength(2));
    expect(statuses.last.name, 'coverage');
  });

  test('commitCommentsProvider loads the thread', () async {
    adapter.get(
      '/projects/42/repository/commits/abc123/comments',
      fixtureJson('commit_comments'),
    );

    const loc = (project: 42, sha: 'abc123');
    final comments = await container.read(commitCommentsProvider(loc).future);

    expect(comments, hasLength(2));
    expect(comments.last.anchor, 'lib/main.dart:4');
  });
}
