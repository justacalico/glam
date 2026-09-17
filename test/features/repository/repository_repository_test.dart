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

    test('blame returns hunks with commit and lines', () async {
      final (client, adapter) = testClient();
      adapter.get(
        '/projects/42/repository/files/lib%2Fmain.dart/blame',
        fixtureJson('blame'),
      );
      final repo = RepositoryRepository(client);

      final hunks = await repo.blame(42, 'lib/main.dart', ref: 'main');

      expect(hunks, hasLength(2));
      expect(hunks.first.commit.shortId, '61049424');
      expect(hunks.first.lines, hasLength(3));
      expect(hunks.last.commit.authorName, 'Jane Doe');
      expect(adapter.lastRequest!.queryParameters['ref'], 'main');
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

    test('compare decodes commits, diffs, and flags', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects/42/repository/compare', fixtureJson('compare'));
      final repo = RepositoryRepository(client);

      final result = await repo.compare(42, 'main', 'feature/x');

      expect(result.commits.single.shortId, '61049424');
      expect(result.diffs, hasLength(2));
      expect(result.compareSameRef, isFalse);
      expect(result.compareTimeout, isFalse);
      final query = adapter.lastRequest!.queryParameters;
      expect(query['from'], 'main');
      expect(query['to'], 'feature/x');
    });

    test('compare decodes same-ref and timeout flags', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects/42/repository/compare', {
        'commits': const <Object?>[],
        'diffs': const <Object?>[],
        'compare_timeout': true,
        'compare_same_ref': true,
      });
      final repo = RepositoryRepository(client);

      final result = await repo.compare(42, 'main', 'main');

      expect(result.compareSameRef, isTrue);
      expect(result.compareTimeout, isTrue);
      expect(result.commits, isEmpty);
      expect(result.diffs, isEmpty);
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

    test('commitStatuses decodes checks with context fallback', () async {
      final (client, adapter) = testClient();
      adapter.get(
        '/projects/42/repository/commits/abc123/statuses',
        fixtureJson('commit_statuses'),
      );
      final repo = RepositoryRepository(client);

      final statuses = await repo.commitStatuses(42, 'abc123');

      expect(statuses, hasLength(2));
      expect(statuses.first.name, 'jenkins');
      expect(statuses.first.authorName, 'Administrator');
      expect(statuses.first.finishedAt, isNotNull);
      expect(statuses.last.name, 'coverage');
      expect(statuses.last.ref, isNull);
    });

    test('commitComments decodes plain and anchored comments', () async {
      final (client, adapter) = testClient();
      adapter.get(
        '/projects/42/repository/commits/abc123/comments',
        fixtureJson('commit_comments'),
      );
      final repo = RepositoryRepository(client);

      final comments = await repo.commitComments(42, 'abc123');

      expect(comments, hasLength(2));
      expect(comments.first.anchor, isNull);
      expect(comments.last.anchor, 'lib/main.dart:4');
      expect(comments.last.lineType, 'new');
      expect(comments.last.author?.name, 'John Smith');
    });

    test('addCommitComment posts note and anchor fields', () async {
      final (client, adapter) = testClient();
      adapter.post(
        '/projects/42/repository/commits/abc123/comments',
        (fixtureJson('commit_comments')! as List).last,
      );
      final repo = RepositoryRepository(client);

      final comment = await repo.addCommitComment(
        42,
        'abc123',
        note: 'unused import',
        anchor: (path: 'lib/main.dart', line: 4, lineType: 'new'),
      );

      expect(comment.anchor, 'lib/main.dart:4');
      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body['note'], 'unused import');
      expect(body['path'], 'lib/main.dart');
      expect(body['line'], 4);
      expect(body['line_type'], 'new');
    });

    test('addCommitComment omits anchor fields for plain comments', () async {
      final (client, adapter) = testClient();
      adapter.post(
        '/projects/42/repository/commits/abc123/comments',
        (fixtureJson('commit_comments')! as List).first,
      );
      final repo = RepositoryRepository(client);

      await repo.addCommitComment(42, 'abc123', note: 'looks good');

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body.containsKey('path'), isFalse);
      expect(body.containsKey('line'), isFalse);
      expect(body.containsKey('line_type'), isFalse);
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

  group('write operations', () {
    test('updateFile puts content with branch and message', () async {
      final (client, adapter) = testClient();
      adapter.put('/projects/42/repository/files/lib%2Fmain.dart', {
        'file_path': 'lib/main.dart',
        'branch': 'main',
      });
      final repo = RepositoryRepository(client);

      final file = await repo.updateFile(
        42,
        'lib/main.dart',
        branch: 'main',
        content: 'void main() {}',
        commitMessage: 'tweak',
      );

      expect(file.path, 'lib/main.dart');
      expect(adapter.lastRequest!.data, {
        'branch': 'main',
        'content': 'void main() {}',
        'commit_message': 'tweak',
      });
    });

    test('createFile posts and deleteFile sends body', () async {
      final (client, adapter) = testClient();
      adapter
        ..post('/projects/42/repository/files/notes.txt', {
          'file_path': 'notes.txt',
          'branch': 'main',
        })
        ..delete('/projects/42/repository/files/notes.txt');
      final repo = RepositoryRepository(client);

      await repo.createFile(
        42,
        'notes.txt',
        branch: 'main',
        content: 'hi',
        commitMessage: 'add notes',
      );
      await repo.deleteFile(
        42,
        'notes.txt',
        branch: 'main',
        commitMessage: 'remove notes',
      );

      expect(
        (adapter
                .requestsTo('POST', '/projects/42/repository/files/notes.txt')
                .single
                .data
            as Map)['commit_message'],
        'add notes',
      );
      final del = adapter
          .requestsTo('DELETE', '/projects/42/repository/files/notes.txt')
          .single;
      expect(del.data, {'branch': 'main', 'commit_message': 'remove notes'});
    });

    test('cherryPick and revert post the target branch', () async {
      final (client, adapter) = testClient();
      adapter
        ..post(
          '/projects/42/repository/commits/abc/cherry_pick',
          fixtureJson('commit'),
        )
        ..post(
          '/projects/42/repository/commits/abc/revert',
          fixtureJson('commit'),
        );
      final repo = RepositoryRepository(client);

      final picked = await repo.cherryPick(42, 'abc', branch: 'main');
      await repo.revert(42, 'abc', branch: 'stable');

      expect(picked.shortId, '61049424');
      expect(
        (adapter
                .requestsTo(
                  'POST',
                  '/projects/42/repository/commits/abc/cherry_pick',
                )
                .single
                .data
            as Map)['branch'],
        'main',
      );
      expect(
        (adapter
                .requestsTo(
                  'POST',
                  '/projects/42/repository/commits/abc/revert',
                )
                .single
                .data
            as Map)['branch'],
        'stable',
      );
    });

    test('createTag and deleteTag hit the tags endpoints', () async {
      final (client, adapter) = testClient();
      adapter
        ..post(
          '/projects/42/repository/tags',
          (fixtureJson('tags') as List).first,
        )
        ..delete('/projects/42/repository/tags/v1.0');
      final repo = RepositoryRepository(client);

      await repo.createTag(42, name: 'v1.0', ref: 'main', message: 'release');
      await repo.deleteTag(42, 'v1.0');

      expect(adapter.lastRequest!.method, 'DELETE');
      expect(
        (adapter.requestsTo('POST', '/projects/42/repository/tags').single.data
            as Map)['tag_name'],
        'v1.0',
      );
    });

    test('createRelease posts tag, name and notes', () async {
      final (client, adapter) = testClient();
      adapter.post(
        '/projects/42/releases',
        (fixtureJson('releases') as List).first,
      );
      final repo = RepositoryRepository(client);

      await repo.createRelease(
        42,
        tag: 'v2.0',
        name: 'Two',
        description: 'notes',
      );

      expect(adapter.lastRequest!.data, {
        'tag_name': 'v2.0',
        'name': 'Two',
        'description': 'notes',
      });
    });
  });
}
