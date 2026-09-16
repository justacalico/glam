import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/core/api/paged_list.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/todos/data/todos_repository.dart';
import 'package:glam/src/features/todos/domain/todo.dart';

final todosRepositoryProvider = Provider<TodosRepository>(
  (ref) => TodosRepository(ref.watch(apiClientProvider)),
);

typedef TodoFilter = ({String? state, String? action});

final todosProvider =
    AsyncNotifierProvider.family<
      TodosNotifier,
      PagedListState<Todo>,
      TodoFilter
    >(TodosNotifier.new);

class TodosNotifier extends PagedListNotifier<Todo> {
  TodosNotifier(this.filter);

  final TodoFilter filter;

  @override
  Future<Paginated<Todo>> fetchPage(int page) {
    return ref
        .watch(todosRepositoryProvider)
        .todos(state: filter.state, action: filter.action, page: page);
  }

  /// Marks one item done and drops it from the pending list.
  Future<void> markDone(Todo todo) async {
    await ref.read(todosRepositoryProvider).markDone(todo.id);
    await refresh();
  }
}
