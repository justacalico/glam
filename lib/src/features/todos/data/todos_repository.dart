import 'package:glam/src/core/api/gitlab_api_client.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/features/todos/domain/todo.dart';

/// `/todos` — the user's work queue across projects.
class TodosRepository {
  const TodosRepository(this._client);

  final GitLabApiClient _client;

  Future<Paginated<Todo>> todos({
    String? state,
    String? action,
    String? type,
    int page = 1,
    int perPage = 20,
  }) {
    return _client.getPage(
      '/todos',
      query: {'state': ?state, 'action': ?action, 'type': ?type},
      page: page,
      perPage: perPage,
      decoder: (j) => Todo.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<void> markDone(int id) {
    return _client.post('/todos/$id/mark_as_done', decoder: (_) {});
  }

  Future<void> markAllDone() {
    return _client.post('/todos/mark_as_done', decoder: (_) {});
  }
}
