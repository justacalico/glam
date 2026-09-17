import 'package:glam/src/core/api/gitlab_api_client.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/features/boards/domain/board.dart';
import 'package:glam/src/features/issues/domain/issue.dart';

/// `/projects/:id/boards` and `/groups/:id/boards` — Kanban columns
/// and their cards.
class BoardsRepository {
  const BoardsRepository(this._client);

  final GitLabApiClient _client;

  String _base(Object id, {required bool isProject}) =>
      '/${isProject ? 'projects' : 'groups'}/${GitLabApiClient.encodeProject(id)}'
      '/boards';

  Future<List<Board>> boards(Object id, {required bool isProject}) {
    return _client.getAll(
      _base(id, isProject: isProject),
      decoder: (j) => Board.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// One board with its lists.
  Future<Board> board(Object id, int boardId, {required bool isProject}) {
    return _client.get(
      '${_base(id, isProject: isProject)}/$boardId',
      decoder: (j) => Board.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<List<BoardList>> lists(
    Object id,
    int boardId, {
    required bool isProject,
  }) {
    return _client.getAll(
      '${_base(id, isProject: isProject)}/$boardId/lists',
      decoder: (j) => BoardList.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Creates a board. Multiple boards need a Premium tier on SaaS.
  Future<Board> createBoard(
    Object id, {
    required bool isProject,
    required String name,
    int? milestoneId,
    List<String>? labels,
    int? weight,
  }) {
    return _client.post(
      _base(id, isProject: isProject),
      body: {
        'name': name,
        'milestone_id': ?milestoneId,
        'labels': ?labels?.join(','),
        'weight': ?weight,
      },
      decoder: (j) => Board.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Updates a board. Scope fields only apply when the caller sends
  /// them; `milestoneId: -1` and an empty `labels` list clear the
  /// filter, matching what the web UI sends.
  Future<Board> updateBoard(
    Object id,
    int boardId, {
    required bool isProject,
    String? name,
    int? milestoneId,
    List<String>? labels,
    int? weight,
  }) {
    return _client.put(
      '${_base(id, isProject: isProject)}/$boardId',
      body: {
        'name': ?name,
        'milestone_id': ?milestoneId,
        'labels': ?labels?.join(','),
        'weight': ?weight,
      },
      decoder: (j) => Board.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<void> deleteBoard(Object id, int boardId, {required bool isProject}) {
    return _client.delete('${_base(id, isProject: isProject)}/$boardId');
  }

  /// Adds a label list to the board.
  Future<BoardList> createList(
    Object id,
    int boardId, {
    required bool isProject,
    required int labelId,
  }) {
    return _client.post(
      '${_base(id, isProject: isProject)}/$boardId/lists',
      body: {'label_id': labelId},
      decoder: (j) => BoardList.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Removes a list. System lists (`backlog`, `closed`) can't be removed.
  Future<void> deleteList(
    Object id,
    int boardId,
    int listId, {
    required bool isProject,
  }) {
    return _client.delete(
      '${_base(id, isProject: isProject)}/$boardId/lists/$listId',
    );
  }

  Future<Paginated<Issue>> listIssues(
    Object id,
    int boardId,
    int listId, {
    required bool isProject,
    int page = 1,
    int perPage = 50,
  }) {
    return _client.getPage(
      '${_base(id, isProject: isProject)}/$boardId/lists/$listId/issues',
      page: page,
      perPage: perPage,
      decoder: (j) => Issue.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Moves an issue into (or within) a list. Pass [toListId] to move
  /// columns, `moveBeforeId`/`moveAfterId` to reorder.
  Future<Issue> moveIssue(
    Object id,
    int boardId,
    int listId,
    int issueId, {
    required bool isProject,
    int? toListId,
    int? moveBeforeId,
    int? moveAfterId,
  }) {
    return _client.put(
      '${_base(id, isProject: isProject)}/$boardId/lists/$listId/issues/$issueId',
      body: {
        'list_id': ?toListId,
        'move_before_id': ?moveBeforeId,
        'move_after_id': ?moveAfterId,
      },
      decoder: (j) => Issue.fromJson(j! as Map<String, dynamic>),
    );
  }
}
