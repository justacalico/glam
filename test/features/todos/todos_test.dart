import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/features/todos/application/todos_providers.dart';
import 'package:glam/src/features/todos/data/todos_repository.dart';
import 'package:glam/src/features/todos/domain/todo.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_client.dart';

void main() {
  group('Todo model', () {
    late List<Todo> todos;

    setUp(() {
      todos = (fixtureJson('todos') as List)
          .cast<Map<String, dynamic>>()
          .map(Todo.fromJson)
          .toList();
    });

    test('parses target, author, and project', () {
      expect(todos.first.actionName, 'mentioned');
      expect(todos.first.author?.username, 'jane');
      expect(todos.first.projectPath, 'calico/glam');
    });

    test('reference uses # for issues and ! for MRs', () {
      expect(todos[0].reference, '#5');
      expect(todos[1].reference, '!9');
    });

    test('action labels are human readable', () {
      expect(todos[0].actionLabel, 'mentioned you');
      expect(todos[1].actionLabel, 'requested your review');
    });

    test('route links to issue and MR detail pages', () {
      expect(todos[0].route, '/projects/42/issues/5');
      expect(todos[1].route, '/projects/42/mrs/9');
    });
  });

  group('TodosRepository', () {
    test('lists todos with state filter', () async {
      final (client, adapter) = testClient();
      adapter.get('/todos', fixtureJson('todos'));
      final repo = TodosRepository(client);

      final page = await repo.todos(state: 'pending', action: 'mentioned');

      expect(page.items, hasLength(2));
      final query = adapter.lastRequest!.queryParameters;
      expect(query['state'], 'pending');
      expect(query['action'], 'mentioned');
    });

    test('mark done endpoints post to the right paths', () async {
      final (client, adapter) = testClient();
      adapter
        ..post('/todos/101/mark_as_done', const {})
        ..post('/todos/mark_as_done', const {});
      final repo = TodosRepository(client);

      await repo.markDone(101);
      await repo.markAllDone();

      expect(
        adapter.requestsTo('POST', '/todos/101/mark_as_done'),
        hasLength(1),
      );
      expect(adapter.requestsTo('POST', '/todos/mark_as_done'), hasLength(1));
    });
  });

  group('todosProvider', () {
    test('loads pending todos', () async {
      final (client, adapter) = testClient();
      adapter.get('/todos', fixtureJson('todos'));
      final container = ProviderContainer(
        overrides: [
          todosRepositoryProvider.overrideWithValue(TodosRepository(client)),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(
        todosProvider((state: 'pending', action: null)).future,
      );
      expect(state.items, hasLength(2));
    });
  });
}
