import 'package:glam/src/core/api/gitlab_api_client.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/features/boards/domain/board.dart';
import 'package:glam/src/features/issues/domain/issue.dart';

/// `/projects/:id/boards` — Kanban columns and their cards.
class BoardsRepository {
  const BoardsRepository(this._client);

  final GitLabApiClient _client;

  String _base(Object projectId) =>
      '/projects/${GitLabApiClient.encodeProject(projectId)}/boards';

  Future<List<Board>> boards(Object projectId) {
    return _client.getAll(
      _base(projectId),
      decoder: (j) => Board.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// One board with its lists.
  Future<Board> board(Object projectId, int boardId) {
    return _client.get(
      '${_base(projectId)}/$boardId',
      decoder: (j) => Board.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<List<BoardList>> lists(Object projectId, int boardId) {
    return _client.getAll(
      '${_base(projectId)}/$boardId/lists',
      decoder: (j) => BoardList.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<Paginated<Issue>> listIssues(
    Object projectId,
    int boardId,
    int listId, {
    int page = 1,
    int perPage = 50,
  }) {
    return _client.getPage(
      '${_base(projectId)}/$boardId/lists/$listId/issues',
      page: page,
      perPage: perPage,
      decoder: (j) => Issue.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Moves an issue into (or within) a list. Pass [toListId] to move
  /// columns, `moveBeforeId`/`moveAfterId` to reorder.
  Future<Issue> moveIssue(
    Object projectId,
    int boardId,
    int listId,
    int issueId, {
    int? toListId,
    int? moveBeforeId,
    int? moveAfterId,
  }) {
    return _client.put(
      '${_base(projectId)}/$boardId/lists/$listId/issues/$issueId',
      body: {
        'list_id': ?toListId,
        'move_before_id': ?moveBeforeId,
        'move_after_id': ?moveAfterId,
      },
      decoder: (j) => Issue.fromJson(j! as Map<String, dynamic>),
    );
  }
}
