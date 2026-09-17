import 'package:glam/src/core/api/gitlab_api_client.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/core/models/award_emoji.dart';
import 'package:glam/src/core/models/note.dart';
import 'package:glam/src/features/auth/domain/user.dart';
import 'package:glam/src/features/issues/domain/issue.dart';
import 'package:glam/src/features/issues/domain/issue_link.dart';
import 'package:glam/src/features/merge_requests/domain/merge_request.dart';

/// Issue list filter for the global `/issues` endpoint.
enum IssueScope { assigned, created, all }

extension IssueScopeX on IssueScope {
  String get apiValue => switch (this) {
    IssueScope.assigned => 'assigned_to_me',
    IssueScope.created => 'created_by_me',
    IssueScope.all => 'all',
  };

  String get label => switch (this) {
    IssueScope.assigned => 'Assigned',
    IssueScope.created => 'Created',
    IssueScope.all => 'All',
  };
}

/// `/issues`, `/projects/:id/issues`, and notes/discussions.
class IssuesRepository {
  const IssuesRepository(this._client);

  final GitLabApiClient _client;

  String _p(Object projectId) =>
      '/projects/${GitLabApiClient.encodeProject(projectId)}';

  /// Issues across the whole instance for the current user.
  Future<Paginated<Issue>> issues({
    IssueScope scope = IssueScope.assigned,
    String? state,
    String? search,
    int page = 1,
    int perPage = 20,
  }) {
    return _client.getPage(
      '/issues',
      query: {'scope': scope.apiValue, 'state': ?state, 'search': ?search},
      page: page,
      perPage: perPage,
      decoder: (j) => Issue.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Issues inside one project.
  Future<Paginated<Issue>> projectIssues(
    Object projectId, {
    String? state,
    String? search,
    String? labels,
    int? milestoneId,
    int? assigneeId,
    int page = 1,
    int perPage = 20,
  }) {
    return _client.getPage(
      '${_p(projectId)}/issues',
      query: {
        'state': ?state,
        'search': ?search,
        'labels': ?labels,
        'milestone': ?milestoneId?.toString(),
        'assignee_id': ?assigneeId?.toString(),
      },
      page: page,
      perPage: perPage,
      decoder: (j) => Issue.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<Issue> issue(Object projectId, int iid) {
    return _client.get(
      '${_p(projectId)}/issues/$iid',
      decoder: (j) => Issue.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<Issue> createIssue(
    Object projectId, {
    required String title,
    String? description,
    List<String>? labels,
    List<int>? assigneeIds,
    int? milestoneId,
    String? dueDate,
    int? weight,
    bool confidential = false,
  }) {
    return _client.post(
      '${_p(projectId)}/issues',
      body: {
        'title': title,
        'description': ?description,
        'labels': ?labels?.join(','),
        'assignee_ids': ?assigneeIds,
        'milestone_id': ?milestoneId,
        'due_date': ?dueDate,
        'weight': ?weight,
        if (confidential) 'confidential': true,
      },
      decoder: (j) => Issue.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Edits any subset of fields; [stateEvent] is `close`/`reopen`.
  Future<Issue> updateIssue(
    Object projectId,
    int iid, {
    String? title,
    String? description,
    String? stateEvent,
    List<String>? labels,
    List<int>? assigneeIds,
    int? milestoneId,
    String? dueDate,
    int? weight,
  }) {
    return _client.put(
      '${_p(projectId)}/issues/$iid',
      body: {
        'title': ?title,
        'description': ?description,
        'state_event': ?stateEvent,
        'labels': ?labels?.join(','),
        'assignee_ids': ?assigneeIds,
        'milestone_id': ?milestoneId,
        'due_date': ?dueDate,
        'weight': ?weight,
      },
      decoder: (j) => Issue.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<void> deleteIssue(Object projectId, int iid) {
    return _client.delete('${_p(projectId)}/issues/$iid');
  }

  /// Comment thread, oldest first.
  Future<Paginated<Note>> notes(
    Object projectId,
    int iid, {
    int page = 1,
    int perPage = 50,
  }) {
    return _client.getPage(
      '${_p(projectId)}/issues/$iid/notes',
      query: {'sort': 'asc', 'order_by': 'created_at'},
      page: page,
      perPage: perPage,
      decoder: (j) => Note.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<Note> addNote(Object projectId, int iid, String body) {
    return _client.post(
      '${_p(projectId)}/issues/$iid/notes',
      body: {'body': body},
      decoder: (j) => Note.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<Note> updateNote(Object projectId, int iid, int noteId, String body) {
    return _client.put(
      '${_p(projectId)}/issues/$iid/notes/$noteId',
      body: {'body': body},
      decoder: (j) => Note.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<void> deleteNote(Object projectId, int iid, int noteId) {
    return _client.delete('${_p(projectId)}/issues/$iid/notes/$noteId');
  }

  /// Emoji reactions on the issue itself.
  Future<List<AwardEmoji>> awardEmojis(Object projectId, int iid) {
    return _client.getAll(
      '${_p(projectId)}/issues/$iid/award_emoji',
      decoder: (j) => AwardEmoji.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Reactions on a single note inside the issue.
  Future<List<AwardEmoji>> noteAwardEmojis(
    Object projectId,
    int iid,
    int noteId,
  ) {
    return _client.getAll(
      '${_p(projectId)}/issues/$iid/notes/$noteId/award_emoji',
      decoder: (j) => AwardEmoji.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<AwardEmoji> award(
    Object projectId,
    int iid,
    String name, {
    int? noteId,
  }) {
    final base = noteId == null
        ? '${_p(projectId)}/issues/$iid/award_emoji'
        : '${_p(projectId)}/issues/$iid/notes/$noteId/award_emoji';
    return _client.post(
      base,
      body: {'name': name},
      decoder: (j) => AwardEmoji.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<void> removeAward(
    Object projectId,
    int iid,
    int awardId, {
    int? noteId,
  }) {
    final base = noteId == null
        ? '${_p(projectId)}/issues/$iid/award_emoji'
        : '${_p(projectId)}/issues/$iid/notes/$noteId/award_emoji';
    return _client.delete('$base/$awardId');
  }

  /// Toggles the user's subscription on the issue.
  Future<Issue> setSubscribed(
    Object projectId,
    int iid, {
    required bool subscribed,
  }) {
    return _client.post(
      '${_p(projectId)}/issues/$iid/'
      '${subscribed ? 'subscribe' : 'unsubscribe'}',
      decoder: (j) => Issue.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// `2h`, `1d`, ... GitLab duration format.
  Future<void> setTimeEstimate(Object projectId, int iid, String duration) {
    return _client.post(
      '${_p(projectId)}/issues/$iid/time_estimate',
      query: {'duration': duration},
      decoder: (_) {},
    );
  }

  Future<void> addTimeSpent(Object projectId, int iid, String duration) {
    return _client.post(
      '${_p(projectId)}/issues/$iid/add_spent_time',
      query: {'duration': duration},
      decoder: (_) {},
    );
  }

  Future<void> resetTimeSpent(Object projectId, int iid) {
    return _client.post(
      '${_p(projectId)}/issues/$iid/reset_spent_time',
      decoder: (_) {},
    );
  }

  /// Issues linked to this one, each carrying its link record id and
  /// type.
  Future<List<IssueLink>> issueLinks(Object projectId, int iid) {
    return _client.getList(
      '${_p(projectId)}/issues/$iid/links',
      decoder: (j) => IssueLink.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Links this issue to [targetIid]. [targetProject] accepts an id or
  /// a full path like `group/other`.
  Future<IssueLink> linkIssue(
    Object projectId,
    int iid, {
    required Object targetProject,
    required int targetIid,
    String linkType = 'relates_to',
  }) {
    return _client.post(
      '${_p(projectId)}/issues/$iid/links',
      body: {
        'target_project_id': targetProject,
        'target_issue_iid': targetIid,
        'link_type': linkType,
      },
      // POST returns {id, link_type, source_issue, target_issue} — a
      // different shape from the GET list's flat issue rows.
      decoder: (j) {
        final m = j! as Map<String, dynamic>;
        final target = m['target_issue'];
        return IssueLink(
          issue: Issue.fromJson(target is Map<String, dynamic> ? target : m),
          linkId: (m['issue_link_id'] ?? m['id']) as int? ?? 0,
          linkType: m['link_type'] as String? ?? 'relates_to',
        );
      },
    );
  }

  Future<void> unlinkIssue(Object projectId, int iid, int linkId) {
    return _client.delete('${_p(projectId)}/issues/$iid/links/$linkId');
  }

  /// Clones the issue into [toProjectId] (numeric id) and returns the
  /// copy. Pass the issue's own project id for a same-project clone.
  Future<Issue> cloneIssue(
    Object projectId,
    int iid, {
    required int toProjectId,
  }) {
    return _client.post(
      '${_p(projectId)}/issues/$iid/clone',
      body: {'to_project_id': toProjectId},
      decoder: (j) => Issue.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Moves the issue to the project with numeric id [toProjectId].
  Future<Issue> moveIssue(Object projectId, int iid, int toProjectId) {
    return _client.post(
      '${_p(projectId)}/issues/$iid/move',
      body: {'to_project_id': toProjectId},
      decoder: (j) => Issue.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Users who participated in the issue thread.
  Future<List<GitLabUser>> participants(Object projectId, int iid) {
    return _client.getAll(
      '${_p(projectId)}/issues/$iid/participants',
      decoder: (j) => GitLabUser.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Merge requests related to this issue (mentioned or closing it).
  Future<List<MergeRequest>> relatedMergeRequests(Object projectId, int iid) {
    // Paginated endpoint; a bounded list so fetch every page.
    return _client.getAll(
      '${_p(projectId)}/issues/$iid/related_merge_requests',
      decoder: (j) => MergeRequest.fromJson(j! as Map<String, dynamic>),
    );
  }
}
