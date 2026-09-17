import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/features/snippets/application/snippets_providers.dart';
import 'package:glam/src/features/snippets/data/snippets_repository.dart';
import 'package:glam/src/features/snippets/domain/snippet.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_client.dart';

void main() {
  group('Snippet model', () {
    test('parses author, files, and dates', () {
      final s = Snippet.fromJson(
        (fixtureJson('snippets') as List).first as Map<String, dynamic>,
      );
      expect(s.title, 'Deploy script');
      expect(s.author?.username, 'jane');
      expect(s.files.single.path, 'deploy.sh');
      expect(s.updatedAt, isNotNull);
    });
  });

  group('SnippetsRepository', () {
    test('lists user snippets and public snippets', () async {
      final (client, adapter) = testClient();
      adapter
        ..get('/snippets', fixtureJson('snippets'))
        ..get('/snippets/public', fixtureJson('snippets'));
      final repo = SnippetsRepository(client);

      final mine = await repo.snippets(search: 'deploy');
      final pub = await repo.publicSnippets();

      expect(mine.items, hasLength(2));
      expect(
        adapter.requestsTo('GET', '/snippets').single.queryParameters['search'],
        'deploy',
      );
      expect(pub.items, hasLength(2));
    });

    test('scopes to projects when projectId is set', () async {
      final (client, adapter) = testClient();
      adapter
        ..get('/projects/42/snippets', fixtureJson('snippets'))
        ..get(
          '/projects/42/snippets/21',
          (fixtureJson('snippets') as List).first,
        )
        ..get('/projects/42/snippets/21/raw', '#!/bin/sh');
      final repo = SnippetsRepository(client);

      final list = await repo.projectSnippets(42);
      final one = await repo.snippet(21, projectId: 42);
      final raw = await repo.raw(21, projectId: 42);

      expect(list.items, hasLength(2));
      expect(one.id, 21);
      expect(raw, '#!/bin/sh');
    });

    test('multi-file raw uses the files path', () async {
      final (client, adapter) = testClient();
      adapter.get('/snippets/21/files/main/lib%2Fa.dart/raw', 'void main() {}');
      final repo = SnippetsRepository(client);

      final raw = await repo.raw(21, filePath: 'lib/a.dart');

      expect(raw, 'void main() {}');
    });

    test('create/update/delete hit the right verbs and bodies', () async {
      final (client, adapter) = testClient();
      adapter
        ..post('/snippets', (fixtureJson('snippets') as List).first)
        ..put('/snippets/21', (fixtureJson('snippets') as List).first)
        ..delete('/snippets/21');
      final repo = SnippetsRepository(client);

      final created = await repo.create(
        title: 'Deploy script',
        fileName: 'deploy.sh',
        content: 'echo hi',
        visibility: 'internal',
      );
      await repo.update(21, title: 'New title');
      await repo.delete(21);

      expect(created.id, 21);
      final post = adapter.requestsTo('POST', '/snippets').single;
      expect((post.data as Map)['visibility'], 'internal');
      expect((post.data as Map)['content'], 'echo hi');
      final put = adapter.requestsTo('PUT', '/snippets/21').single;
      expect((put.data as Map)['title'], 'New title');
      expect(adapter.requestsTo('DELETE', '/snippets/21'), hasLength(1));
    });

    test('award emojis scope personal vs project paths', () async {
      final (client, adapter) = testClient();
      adapter
        ..get('/snippets/21/award_emoji', [
          {'id': 1, 'name': 'thumbsup', 'user': {'id': 7}},
        ])
        ..get('/projects/42/snippets/21/award_emoji', [])
        ..post('/projects/42/snippets/21/award_emoji', {'id': 2})
        ..delete('/projects/42/snippets/21/award_emoji/2');
      final repo = SnippetsRepository(client);

      final awards = await repo.awardEmojis(21);
      expect(awards.single.name, 'thumbsup');

      await repo.awardEmojis(21, projectId: 42);
      expect(
        adapter.lastRequest!.path,
        '/projects/42/snippets/21/award_emoji',
      );

      await repo.award(21, 'rocket', projectId: 42);
      final sent = adapter.lastRequest!.data as Map;
      expect(sent['name'], 'rocket');

      await repo.removeAward(21, 2, projectId: 42);
      expect(
        adapter.requestsTo(
          'DELETE',
          '/projects/42/snippets/21/award_emoji/2',
        ),
        hasLength(1),
      );
    });

    test('notes CRUD and note-level emoji hit /notes paths', () async {
      final (client, adapter) = testClient();
      adapter
        ..get('/snippets/21/notes', [
          {'id': 30, 'body': 'nice', 'author': {'id': 7}},
        ])
        ..post('/snippets/21/notes', {'id': 31})
        ..put('/snippets/21/notes/30', {'id': 30})
        ..delete('/snippets/21/notes/30')
        ..get('/snippets/21/notes/30/award_emoji', []);
      final repo = SnippetsRepository(client);

      final notes = await repo.notes(21);
      expect(notes.items.single.body, 'nice');

      await repo.addNote(21, 'thanks');
      expect((adapter.lastRequest!.data as Map)['body'], 'thanks');

      await repo.updateNote(21, 30, 'edited');
      await repo.deleteNote(21, 30);
      expect(
        adapter.requestsTo('DELETE', '/snippets/21/notes/30'),
        hasLength(1),
      );

      await repo.awardEmojis(21, noteId: 30);
      expect(
        adapter.lastRequest!.path,
        '/snippets/21/notes/30/award_emoji',
      );
    });
  });

  group('providers', () {
    test('scope switch picks mine vs public', () async {
      final (client, adapter) = testClient();
      adapter
        ..get('/snippets', fixtureJson('snippets'))
        ..get('/snippets/public', const [])
        ..get('/snippets/21', (fixtureJson('snippets') as List).first)
        ..get('/snippets/21/raw', 'body');
      final container = ProviderContainer(
        overrides: [
          snippetsRepositoryProvider.overrideWithValue(
            SnippetsRepository(client),
          ),
        ],
      );
      addTearDown(container.dispose);

      final mine = await container.read(
        snippetsProvider((scope: SnippetScope.mine, search: null)).future,
      );
      final pub = await container.read(
        snippetsProvider((scope: SnippetScope.public, search: null)).future,
      );
      final s = await container.read(
        snippetProvider((id: 21, projectId: null)).future,
      );
      final raw = await container.read(
        snippetRawProvider((id: 21, projectId: null)).future,
      );

      expect(mine.items, hasLength(2));
      expect(pub.items, isEmpty);
      expect(s.title, 'Deploy script');
      expect(raw, 'body');
    });
  });
}
