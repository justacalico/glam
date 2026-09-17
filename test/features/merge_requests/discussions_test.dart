import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/core/models/discussion.dart';
import 'package:glam/src/core/models/note.dart';
import 'package:glam/src/features/merge_requests/application/mr_providers.dart';
import 'package:glam/src/features/merge_requests/data/merge_requests_repository.dart';

import '../../helpers/fake_dio_adapter.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/test_client.dart';

List<Discussion> _fixture() => (fixtureJson('discussions') as List)
    .whereType<Map<String, dynamic>>()
    .map(Discussion.fromJson)
    .toList();

const _loc = (project: 42, iid: 7);

void main() {
  group('Discussion model', () {
    test('parses a thread with a positioned first note', () {
      final d = _fixture().first;

      expect(d.id, 'abc123');
      expect(d.individualNote, isFalse);
      expect(d.notes, hasLength(2));
      expect(d.first?.body, 'This needs a null check.');
      expect(d.resolvable, isTrue);
      expect(d.resolved, isFalse);
      expect(d.position?.label, 'lib/a.dart:42');
    });

    test('individual note threads parse', () {
      final d = _fixture().last;

      expect(d.individualNote, isTrue);
      expect(d.notes.single.body, 'LGTM overall.');
      expect(d.resolvable, isFalse);
      expect(d.resolved, isFalse);
      expect(d.position, isNull);
    });

    test('resolved is true only when every resolvable note resolved', () {
      const unresolved = Note(id: 1, body: 'a', resolvable: true);
      const resolved = Note(id: 2, body: 'b', resolvable: true, resolved: true);

      expect(
        const Discussion(id: 'x', notes: [unresolved, resolved]).resolved,
        isFalse,
      );
      expect(const Discussion(id: 'x', notes: [resolved]).resolved, isTrue);
    });
  });

  group('NotePosition', () {
    test('label joins path and line', () {
      const pos = NotePosition(newPath: 'lib/a.dart', newLine: 7);
      expect(pos.label, 'lib/a.dart:7');
    });

    test('label falls back to old path and line', () {
      const pos = NotePosition(oldPath: 'lib/b.dart', oldLine: 3);
      expect(pos.label, 'lib/b.dart:3');
    });

    test('old-side label keeps the old path on renamed files', () {
      const pos = NotePosition(
        oldPath: 'old.dart',
        newPath: 'new.dart',
        oldLine: 5,
      );
      expect(pos.label, 'old.dart:5');
    });

    test('label is path alone or null without data', () {
      const pathOnly = NotePosition(newPath: 'lib/a.dart');
      expect(pathOnly.label, 'lib/a.dart');
      expect(const NotePosition().label, isNull);
    });

    test('note position parses from json', () {
      final note = Note.fromJson(const {
        'id': 1,
        'body': 'x',
        'position': {
          'base_sha': 'b',
          'start_sha': 's',
          'head_sha': 'h',
          'old_path': 'old.dart',
          'new_path': 'new.dart',
          'old_line': 1,
          'new_line': 5,
        },
      });
      final pos = note.position!;

      expect(pos.baseSha, 'b');
      expect(pos.headSha, 'h');
      expect(pos.newLine, 5);
      expect(pos.label, 'new.dart:5');
    });
  });

  group('MergeRequestsRepository discussions', () {
    test('lists discussions', () async {
      final (client, adapter) = testClient();
      adapter.get(
        '/projects/42/merge_requests/7/discussions',
        fixtureJson('discussions'),
      );
      final repo = MergeRequestsRepository(client);

      final page = await repo.discussions(42, 7);

      expect(page.items, hasLength(2));
      expect(page.items.first.notes, hasLength(2));
    });

    test('addDiscussion posts a plain body', () async {
      final (client, adapter) = testClient();
      adapter.post(
        '/projects/42/merge_requests/7/discussions',
        (fixtureJson('discussions') as List).last,
      );
      final repo = MergeRequestsRepository(client);

      final d = await repo.addDiscussion(42, 7, 'nice work');

      expect(d.individualNote, isTrue);
      final sent = adapter.lastRequest!.data as Map;
      expect(sent['body'], 'nice work');
      expect(sent.containsKey('position'), isFalse);
    });

    test('addDiscussion with position sends the diff anchor', () async {
      final (client, adapter) = testClient();
      adapter.post(
        '/projects/42/merge_requests/7/discussions',
        (fixtureJson('discussions') as List).first,
      );
      final repo = MergeRequestsRepository(client);

      await repo.addDiscussion(
        42,
        7,
        'nit',
        position: const NotePosition(
          baseSha: 'b',
          startSha: 's',
          headSha: 'h',
          oldPath: 'lib/a.dart',
          newPath: 'lib/a.dart',
          newLine: 42,
        ),
      );

      final sent = adapter.lastRequest!.data as Map;
      final position = sent['position'] as Map;
      expect(position['base_sha'], 'b');
      expect(position['position_type'], 'text');
      expect(position['new_line'], 42);
      expect(position.containsKey('old_line'), isFalse);
    });

    test('addDiscussion sends both lines for context comments', () async {
      final (client, adapter) = testClient();
      adapter.post(
        '/projects/42/merge_requests/7/discussions',
        (fixtureJson('discussions') as List).first,
      );
      final repo = MergeRequestsRepository(client);

      await repo.addDiscussion(
        42,
        7,
        'context nit',
        position: const NotePosition(
          baseSha: 'b',
          startSha: 's',
          headSha: 'h',
          oldPath: 'lib/a.dart',
          newPath: 'lib/a.dart',
          oldLine: 40,
          newLine: 42,
        ),
      );

      final position = (adapter.lastRequest!.data as Map)['position'] as Map;
      expect(position['old_line'], 40);
      expect(position['new_line'], 42);
    });

    test('addDiscussion strips empty strings from the position', () async {
      final (client, adapter) = testClient();
      adapter.post(
        '/projects/42/merge_requests/7/discussions',
        (fixtureJson('discussions') as List).first,
      );
      final repo = MergeRequestsRepository(client);

      await repo.addDiscussion(
        42,
        7,
        'nit',
        position: const NotePosition(
          baseSha: 'b',
          startSha: 's',
          headSha: 'h',
          oldPath: '',
          newPath: 'lib/a.dart',
          newLine: 9,
        ),
      );

      final position = (adapter.lastRequest!.data as Map)['position'] as Map;
      expect(position.containsKey('old_path'), isFalse);
      expect(position['new_path'], 'lib/a.dart');
    });

    test('replyToDiscussion posts into the thread', () async {
      final (client, adapter) = testClient();
      adapter.post(
        '/projects/42/merge_requests/7/discussions/abc123/notes',
        const {'id': 900, 'body': 'reply'},
      );
      final repo = MergeRequestsRepository(client);

      final note = await repo.replyToDiscussion(42, 7, 'abc123', 'reply');

      expect(note.id, 900);
      final sent = adapter.lastRequest!.data as Map;
      expect(sent['body'], 'reply');
    });

    test('updateDiscussionNote puts and deleteDiscussionNote deletes',
        () async {
      final (client, adapter) = testClient();
      adapter
        ..put(
          '/projects/42/merge_requests/7/discussions/abc123/notes/900',
          const {'id': 900, 'body': 'edited'},
        )
        ..delete('/projects/42/merge_requests/7/discussions/abc123/notes/900');
      final repo = MergeRequestsRepository(client);

      final note = await repo.updateDiscussionNote(
        42,
        7,
        'abc123',
        900,
        'edited',
      );
      expect(note.id, 900);
      expect((adapter.lastRequest!.data as Map)['body'], 'edited');

      await repo.deleteDiscussionNote(42, 7, 'abc123', 900);
      expect(adapter.lastRequest!.method, 'DELETE');
    });

    test('setDiscussionResolved puts the resolved flag', () async {
      final (client, adapter) = testClient();
      adapter
        ..put(
          '/projects/42/merge_requests/7/discussions/abc123',
          (fixtureJson('discussions') as List).first,
        )
        ..put(
          '/projects/42/merge_requests/7/discussions/abc123',
          (fixtureJson('discussions') as List).first,
        );
      final repo = MergeRequestsRepository(client);

      final d = await repo.setDiscussionResolved(
        42,
        7,
        'abc123',
        resolved: true,
      );
      expect(d.id, 'abc123');
      expect((adapter.lastRequest!.data as Map)['resolved'], isTrue);

      await repo.setDiscussionResolved(42, 7, 'abc123', resolved: false);
      expect((adapter.lastRequest!.data as Map)['resolved'], isFalse);
    });

    test('discussion fetches one thread', () async {
      final (client, adapter) = testClient();
      adapter.get(
        '/projects/42/merge_requests/7/discussions/abc123',
        (fixtureJson('discussions') as List).first,
      );
      final repo = MergeRequestsRepository(client);

      final d = await repo.discussion(42, 7, 'abc123');

      expect(d.notes, hasLength(2));
      expect(d.position?.label, 'lib/a.dart:42');
    });
  });

  group('mrDiscussionsProvider', () {
    late FakeDioAdapter adapter;
    late ProviderContainer container;

    setUp(() {
      final (client, a) = testClient();
      adapter = a;
      container = ProviderContainer(
        overrides: [
          mrRepositoryProvider.overrideWithValue(
            MergeRequestsRepository(client),
          ),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('loads the paged thread list', () async {
      adapter.get(
        '/projects/42/merge_requests/7/discussions',
        fixtureJson('discussions'),
      );

      final state = await container.read(mrDiscussionsProvider(_loc).future);

      expect(state.items, hasLength(2));
      expect(state.items.first.position?.label, 'lib/a.dart:42');
    });

    test('addComment posts a discussion and appends it', () async {
      adapter
        ..get(
          '/projects/42/merge_requests/7/discussions',
          fixtureJson('discussions'),
        )
        ..post('/projects/42/merge_requests/7/discussions', const {
          'id': 'new1',
          'individual_note': true,
          'notes': [
            {'id': 901, 'body': 'lgtm'},
          ],
        });

      await container.read(mrDiscussionsProvider(_loc).future);
      await container
          .read(mrDiscussionsProvider(_loc).notifier)
          .addComment('lgtm');

      final posts = adapter.requestsTo(
        'POST',
        '/projects/42/merge_requests/7/discussions',
      );
      expect(posts, hasLength(1));
      expect((posts.single.data as Map).containsKey('position'), isFalse);
      // The new thread lands in place — no list refetch.
      expect(
        adapter.requestsTo('GET', '/projects/42/merge_requests/7/discussions'),
        hasLength(1),
      );
      final items = container.read(mrDiscussionsProvider(_loc)).value!.items;
      expect(items.last.id, 'new1');
    });

    test('addDiffComment posts with a position', () async {
      adapter
        ..get(
          '/projects/42/merge_requests/7/discussions',
          fixtureJson('discussions'),
        )
        ..post(
          '/projects/42/merge_requests/7/discussions',
          (fixtureJson('discussions') as List).first,
        );

      await container.read(mrDiscussionsProvider(_loc).future);
      await container
          .read(mrDiscussionsProvider(_loc).notifier)
          .addDiffComment(
            'nit',
            const NotePosition(
              baseSha: 'b',
              startSha: 's',
              headSha: 'h',
              newPath: 'lib/a.dart',
              newLine: 9,
            ),
          );

      final posts = adapter.requestsTo(
        'POST',
        '/projects/42/merge_requests/7/discussions',
      );
      final position = (posts.single.data as Map)['position'] as Map;
      expect(position['new_path'], 'lib/a.dart');
      expect(position['new_line'], 9);
    });

    test('reply posts into the thread and reloads it', () async {
      adapter
        ..get(
          '/projects/42/merge_requests/7/discussions',
          fixtureJson('discussions'),
        )
        ..post('/projects/42/merge_requests/7/discussions/abc123/notes', const {
          'id': 900,
          'body': 'ok',
        })
        ..get(
          '/projects/42/merge_requests/7/discussions/abc123',
          (fixtureJson('discussions') as List).first,
        );

      await container.read(mrDiscussionsProvider(_loc).future);
      await container
          .read(mrDiscussionsProvider(_loc).notifier)
          .reply('abc123', 'ok');

      expect(
        adapter.requestsTo(
          'POST',
          '/projects/42/merge_requests/7/discussions/abc123/notes',
        ),
        hasLength(1),
      );
      expect(
        adapter.requestsTo(
          'GET',
          '/projects/42/merge_requests/7/discussions/abc123',
        ),
        hasLength(1),
      );
    });

    test('toggleResolved resolves the thread', () async {
      adapter
        ..get(
          '/projects/42/merge_requests/7/discussions',
          fixtureJson('discussions'),
        )
        ..put(
          '/projects/42/merge_requests/7/discussions/abc123',
          (fixtureJson('discussions') as List).first,
        );

      await container.read(mrDiscussionsProvider(_loc).future);
      final thread = container
          .read(mrDiscussionsProvider(_loc))
          .value!
          .items
          .first;
      await container
          .read(mrDiscussionsProvider(_loc).notifier)
          .toggleResolved(thread);

      final puts = adapter.requestsTo(
        'PUT',
        '/projects/42/merge_requests/7/discussions/abc123',
      );
      expect(puts, hasLength(1));
      expect((puts.single.data as Map)['resolved'], isTrue);
    });

    test('toggleResolved unresolves a resolved thread', () async {
      const resolvedThread = Discussion(
        id: 'abc123',
        notes: [Note(id: 500, body: 'a', resolvable: true, resolved: true)],
      );
      adapter
        ..get(
          '/projects/42/merge_requests/7/discussions',
          fixtureJson('discussions'),
        )
        ..put(
          '/projects/42/merge_requests/7/discussions/abc123',
          (fixtureJson('discussions') as List).first,
        );

      await container.read(mrDiscussionsProvider(_loc).future);
      await container
          .read(mrDiscussionsProvider(_loc).notifier)
          .toggleResolved(resolvedThread);

      final puts = adapter.requestsTo(
        'PUT',
        '/projects/42/merge_requests/7/discussions/abc123',
      );
      expect((puts.single.data as Map)['resolved'], isFalse);
    });

    test('toggleResolved no-ops on unresolvable threads', () async {
      const thread = Discussion(
        id: 'def456',
        notes: [Note(id: 502, body: 'lgtm')],
      );
      adapter.get(
        '/projects/42/merge_requests/7/discussions',
        fixtureJson('discussions'),
      );

      await container.read(mrDiscussionsProvider(_loc).future);
      await container
          .read(mrDiscussionsProvider(_loc).notifier)
          .toggleResolved(thread);

      expect(adapter.requests.where((r) => r.method == 'PUT'), isEmpty);
    });
  });
}
