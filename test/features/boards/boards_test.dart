import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/features/boards/application/boards_providers.dart';
import 'package:glam/src/features/boards/data/boards_repository.dart';
import 'package:glam/src/features/boards/domain/board.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_client.dart';

void main() {
  group('Board models', () {
    test('board parses embedded milestone', () {
      final b = Board.fromJson(
        (fixtureJson('boards') as List).first as Map<String, dynamic>,
      );
      expect(b.name, 'Development');
      expect(b.milestoneId, 61);
    });

    test('list titles come from type or label', () {
      final lists = (fixtureJson('board_lists') as List)
          .cast<Map<String, dynamic>>()
          .map(BoardList.fromJson)
          .toList();
      expect(lists[0].title, 'Open');
      expect(lists[1].title, 'bug');
      expect(lists[2].title, 'Closed');
    });
  });

  group('BoardsRepository', () {
    test('boards, lists, and list issues', () async {
      final (client, adapter) = testClient();
      adapter
        ..get('/projects/42/boards', fixtureJson('boards'))
        ..get('/projects/42/boards/5/lists', fixtureJson('board_lists'))
        ..get('/projects/42/boards/5/lists/11/issues', fixtureJson('issues'));
      final repo = BoardsRepository(client);

      final boards = await repo.boards(42);
      final lists = await repo.lists(42, 5);
      final issues = await repo.listIssues(42, 5, 11);

      expect(boards, hasLength(2));
      expect(lists, hasLength(3));
      expect(issues.items, isNotEmpty);
    });

    test('moveIssue posts list_id to the issue resource', () async {
      final (client, adapter) = testClient();
      adapter.put(
        '/projects/42/boards/5/lists/11/issues/88',
        (fixtureJson('issues') as List).first,
      );
      final repo = BoardsRepository(client);

      await repo.moveIssue(42, 5, 11, 88, toListId: 12);

      final req = adapter
          .requestsTo('PUT', '/projects/42/boards/5/lists/11/issues/88')
          .single;
      expect((req.data as Map)['list_id'], 12);
    });

    test('board create, rename, and delete hit the board paths', () async {
      final (client, adapter) = testClient();
      final board = (fixtureJson('boards') as List).first;
      adapter
        ..post('/projects/42/boards', board)
        ..put('/projects/42/boards/5', board)
        ..delete('/projects/42/boards/5');
      final repo = BoardsRepository(client);

      await repo.createBoard(42, name: 'Sprint board');
      await repo.updateBoard(42, 5, name: 'Renamed');
      await repo.deleteBoard(42, 5);

      final post = adapter.requestsTo('POST', '/projects/42/boards').single;
      expect((post.data as Map)['name'], 'Sprint board');
      final put = adapter.requestsTo('PUT', '/projects/42/boards/5').single;
      expect((put.data as Map)['name'], 'Renamed');
      expect(
        adapter.requestsTo('DELETE', '/projects/42/boards/5'),
        hasLength(1),
      );
    });

    test('list create and delete hit the lists paths', () async {
      final (client, adapter) = testClient();
      adapter
        ..post(
          '/projects/42/boards/5/lists',
          (fixtureJson('board_lists') as List).last,
        )
        ..delete('/projects/42/boards/5/lists/11');
      final repo = BoardsRepository(client);

      await repo.createList(42, 5, labelId: 9);
      await repo.deleteList(42, 5, 11);

      final post = adapter
          .requestsTo('POST', '/projects/42/boards/5/lists')
          .single;
      expect((post.data as Map)['label_id'], 9);
      expect(
        adapter.requestsTo('DELETE', '/projects/42/boards/5/lists/11'),
        hasLength(1),
      );
    });
  });

  group('providers', () {
    test('boardsProvider loads boards', () async {
      final (client, adapter) = testClient();
      adapter
        ..get('/projects/42/boards', fixtureJson('boards'))
        ..get('/projects/42/boards/5/lists', fixtureJson('board_lists'));
      final container = ProviderContainer(
        overrides: [
          boardsRepositoryProvider.overrideWithValue(BoardsRepository(client)),
        ],
      );
      addTearDown(container.dispose);

      final boards = await container.read(boardsProvider(42).future);
      final lists = await container.read(
        boardListsProvider((projectId: 42, boardId: 5)).future,
      );

      expect(boards, hasLength(2));
      expect(lists.first.listType, 'backlog');
    });
  });
}
