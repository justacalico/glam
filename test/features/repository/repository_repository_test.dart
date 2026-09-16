import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/features/repository/data/repository_repository.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_client.dart';

void main() {
  group('tree', () {
    test('decodes a directory listing', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects/42/repository/tree', fixtureJson('tree'));
      final repo = RepositoryRepository(client);

      final page = await repo.tree(42, ref: 'main');

      expect(page.items, hasLength(3));
      expect(page.items[0].name, 'lib');
      final query = adapter.lastRequest!.queryParameters;
      expect(query['ref'], 'main');
      expect(query['order_by'], 'name');
    });
  });

  group('file', () {
    test('fetches and decodes file metadata', () async {
      final (client, adapter) = testClient();
      adapter.get(
        '/projects/42/repository/files/lib%2Fmain.dart',
        fixtureJson('repo_file'),
      );
      final repo = RepositoryRepository(client);

      final file = await repo.file(42, 'lib/main.dart', ref: 'main');

      expect(file.name, 'main.dart');
      expect(file.decodedContent, contains('material.dart'));
      expect(adapter.lastRequest!.queryParameters['ref'], 'main');
    });

    test('rawFile returns the plain body', () async {
      final (client, adapter) = testClient();
      adapter.get(
        '/projects/42/repository/files/lib%2Fmain.dart/raw',
        'void main() {}',
      );
      final repo = RepositoryRepository(client);

      final body = await repo.rawFile(42, 'lib/main.dart', ref: 'dev');

      expect(body, 'void main() {}');
      expect(adapter.lastRequest!.queryParameters['ref'], 'dev');
    });
  });

  group('file mutations', () {
    test('updateFile PUTs branch/content/message', () async {
      final (client, adapter) = testClient();
      adapter.put('/projects/42/repository/files/a.txt', {
        'file_path': 'a.txt',
      });
      final repo = RepositoryRepository(client);

      final file = await repo.updateFile(
        42,
        'a.txt',
        branch: 'main',
        content: 'hi',
        commitMessage: 'update a',
      );

      expect(file.path, 'a.txt');
      expect(file.content, 'hi');
      final sent = adapter.lastRequest!.data as Map;
      expect(sent['commit_message'], 'update a');
      expect(sent['branch'], 'main');
    });

    test('createFile POSTs to the files endpoint', () async {
      final (client, adapter) = testClient();
      adapter.post('/projects/42/repository/files/b.txt', {});
      final repo = RepositoryRepository(client);

      await repo.createFile(
        42,
        'b.txt',
        branch: 'main',
        content: 'x',
        commitMessage: 'add b',
      );

      expect(
        adapter.requestsTo('POST', '/projects/42/repository/files/b.txt'),
        hasLength(1),
      );
    });
  });

  group('commits', () {
    test('lists commits with ref and path filters', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects/42/repository/commits', [fixtureJson('commit')]);
      final repo = RepositoryRepository(client);

      final page = await repo.commits(42, ref: 'dev', path: 'lib');

      expect(page.items.single.shortId, '61049424');
      final query = adapter.lastRequest!.queryParameters;
      expect(query['ref_name'], 'dev');
      expect(query['path'], 'lib');
    });

    test('with_stats flag is sent when requested', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects/42/repository/commits', const []);
      final repo = RepositoryRepository(client);

      await repo.commits(42, withStats: true);

      expect(adapter.lastRequest!.queryParameters['with_stats'], true);
    });

    test('commit returns a single commit', () async {
      final (client, adapter) = testClient();
      adapter.get(
        '/projects/42/repository/commits/abc123',
        fixtureJson('commit'),
      );
      final repo = RepositoryRepository(client);

      final c = await repo.commit(42, 'abc123');

      expect(c.title, 'Sanitize for network graph');
    });

    test('commitDiff decodes change entries', () async {
      final (client, adapter) = testClient();
      adapter.get(
        '/projects/42/repository/commits/abc123/diff',
        fixtureJson('commit_diff'),
      );
      final repo = RepositoryRepository(client);

      final diffs = await repo.commitDiff(42, 'abc123');

      expect(diffs, hasLength(2));
      expect(diffs.first.newPath, 'lib/main.dart');
    });
  });

  group('branches', () {
    test('lists branches', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects/42/repository/branches', fixtureJson('branches'));
      final repo = RepositoryRepository(client);

      final page = await repo.branches(42);

      expect(page.items, hasLength(2));
      expect(page.items.first.isDefault, isTrue);
    });

    test('search query is forwarded', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects/42/repository/branches', const []);
      final repo = RepositoryRepository(client);

      await repo.branches(42, search: 'feat');

      expect(adapter.lastRequest!.queryParameters['search'], 'feat');
    });

    test('createBranch posts branch and ref', () async {
      final (client, adapter) = testClient();
      adapter.post(
        '/projects/42/repository/branches',
        (fixtureJson('branches') as List).first,
      );
      final repo = RepositoryRepository(client);

      final b = await repo.createBranch(42, branch: 'dev', ref: 'main');

      expect(b.name, 'main');
      final sent = adapter.lastRequest!.data as Map;
      expect(sent['branch'], 'dev');
      expect(sent['ref'], 'main');
    });

    test('deleteBranch issues a DELETE', () async {
      final (client, adapter) = testClient();
      adapter.delete('/projects/42/repository/branches/dev');
      final repo = RepositoryRepository(client);

      await repo.deleteBranch(42, 'dev');

      expect(
        adapter.requestsTo('DELETE', '/projects/42/repository/branches/dev'),
        hasLength(1),
      );
    });
  });

  group('tags', () {
    test('lists tags sorted by version desc', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects/42/repository/tags', fixtureJson('tags'));
      final repo = RepositoryRepository(client);

      final page = await repo.tags(42);

      expect(page.items, hasLength(2));
      final query = adapter.lastRequest!.queryParameters;
      expect(query['order_by'], 'version');
      expect(query['sort'], 'desc');
    });

    test('createTag posts name/ref/message', () async {
      final (client, adapter) = testClient();
      adapter.post(
        '/projects/42/repository/tags',
        (fixtureJson('tags') as List).first,
      );
      final repo = RepositoryRepository(client);

      final tag = await repo.createTag(
        42,
        name: 'v1.3.0',
        ref: 'main',
        message: 'release',
      );

      expect(tag.name, 'v1.2.0');
      final sent = adapter.lastRequest!.data as Map;
      expect(sent['tag_name'], 'v1.3.0');
      expect(sent['ref'], 'main');
    });

    test('deleteTag issues a DELETE', () async {
      final (client, adapter) = testClient();
      adapter.delete('/projects/42/repository/tags/v1.1.0');
      final repo = RepositoryRepository(client);

      await repo.deleteTag(42, 'v1.1.0');

      expect(
        adapter.requestsTo('DELETE', '/projects/42/repository/tags/v1.1.0'),
        hasLength(1),
      );
    });
  });

  group('releases', () {
    test('lists releases', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects/42/releases', fixtureJson('releases'));
      final repo = RepositoryRepository(client);

      final page = await repo.releases(42);

      expect(page.items.single.tagName, 'v1.2.0');
      expect(page.items.single.assets, hasLength(1));
    });

    test('createRelease posts tag/name/description', () async {
      final (client, adapter) = testClient();
      adapter.post(
        '/projects/42/releases',
        (fixtureJson('releases') as List).first,
      );
      final repo = RepositoryRepository(client);

      final r = await repo.createRelease(
        42,
        tag: 'v1.3.0',
        name: '1.3.0',
        description: 'notes',
      );

      expect(r.tagName, 'v1.2.0');
      final sent = adapter.lastRequest!.data as Map;
      expect(sent['tag_name'], 'v1.3.0');
      expect(sent['description'], 'notes');
    });
  });

  group('readme', () {
    test('returns the first existing candidate', () async {
      final (client, adapter) = testClient();
      adapter.get(
        '/projects/42/repository/files/README.md',
        fixtureJson('repo_file'),
      );
      final repo = RepositoryRepository(client);

      final file = await repo.readme(42, ref: 'main');

      expect(file, isNotNull);
      expect(
        adapter.lastRequest!.path,
        '/projects/42/repository/files/README.md',
      );
    });

    test('tries the next candidate on failure', () async {
      final (client, adapter) = testClient();
      adapter
        ..fail('/projects/42/repository/files/README.md', status: 404)
        ..get(
          '/projects/42/repository/files/readme.md',
          fixtureJson('repo_file'),
        );
      final repo = RepositoryRepository(client);

      final file = await repo.readme(42);

      expect(file, isNotNull);
      expect(
        adapter.requestsTo('GET', '/projects/42/repository/files/readme.md'),
        hasLength(1),
      );
    });

    test('returns null when no readme exists', () async {
      final (client, adapter) = testClient();
      final repo = RepositoryRepository(client);

      final file = await repo.readme(42);

      expect(file, isNull);
    });
  });

  group('languages', () {
    test('decodes the language map', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects/42/languages', {'Dart': 82.3, 'Shell': 17.7});
      final repo = RepositoryRepository(client);

      final langs = await repo.languages(42);

      expect(langs['Dart'], 82.3);
      expect(langs['Shell'], 17.7);
    });
  });

  group('blame', () {
    test('decodes blame hunks', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects/42/repository/files/lib%2Fmain.dart/blame', [
        {
          'commit': fixtureJson('commit'),
          'lines': ['a', 'b'],
        },
      ]);
      final repo = RepositoryRepository(client);

      final hunks = await repo.blame(42, 'lib/main.dart', ref: 'main');

      expect(hunks.single.lines, ['a', 'b']);
      expect(hunks.single.commit.shortId, '61049424');
    });
  });
}
