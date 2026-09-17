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

      final boards = await repo.boards(42, isProject: true);
      final lists = await repo.lists(42, 5, isProject: true);
      final issues = await repo.listIssues(42, 5, 11, isProject: true);

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

      await repo.moveIssue(42, 5, 11, 88, isProject: true, toListId: 12);

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

      await repo.createBoard(
        42,
        isProject: true,
        name: 'Sprint board',
        milestoneId: 61,
        labels: const ['bug', 'frontend'],
      );
      await repo.updateBoard(
        42,
        5,
        isProject: true,
        name: 'Renamed',
        milestoneId: -1,
        labels: const [],
        weight: 3,
      );
      await repo.deleteBoard(42, 5, isProject: true);

      final post = adapter.requestsTo('POST', '/projects/42/boards').single;
      expect((post.data as Map)['name'], 'Sprint board');
      expect((post.data as Map)['milestone_id'], 61);
      expect((post.data as Map)['labels'], 'bug,frontend');
      final put = adapter.requestsTo('PUT', '/projects/42/boards/5').single;
      expect((put.data as Map)['name'], 'Renamed');
      expect((put.data as Map)['milestone_id'], -1);
      expect((put.data as Map)['labels'], '');
      expect((put.data as Map)['weight'], 3);
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

      await repo.createList(42, 5, isProject: true, labelId: 9);
      await repo.deleteList(42, 5, 11, isProject: true);

      final post = adapter
          .requestsTo('POST', '/projects/42/boards/5/lists')
          .single;
      expect((post.data as Map)['label_id'], 9);
      expect(
        adapter.requestsTo('DELETE', '/projects/42/boards/5/lists/11'),
        hasLength(1),
      );
    });

    test('group scope hits the /groups paths', () async {
      final (client, adapter) = testClient();
      adapter
        ..get('/groups/9/boards', fixtureJson('boards'))
        ..get('/groups/9/boards/5/lists', fixtureJson('board_lists'));
      final repo = BoardsRepository(client);

      await repo.boards(9, isProject: false);
      await repo.lists(9, 5, isProject: false);

      expect(adapter.requestsTo('GET', '/groups/9/boards'), hasLength(1));
      expect(
        adapter.requestsTo('GET', '/groups/9/boards/5/lists'),
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

      final boards = await container.read(
        boardsProvider((id: 42, isProject: true)).future,
      );
      final lists = await container.read(
        boardListsProvider((
          scope: (id: 42, isProject: true),
          boardId: 5,
        )).future,
      );

      expect(boards, hasLength(2));
      expect(lists.first.listType, 'backlog');
    });
  });
}
