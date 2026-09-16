import 'package:glam/src/core/api/gitlab_api_client.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/core/models/award_emoji.dart';
import 'package:glam/src/core/models/discussion.dart';
import 'package:glam/src/core/models/note.dart';
import 'package:glam/src/features/merge_requests/domain/merge_request.dart';
import 'package:glam/src/features/repository/domain/repo_models.dart';

/// MR list filter for the global endpoint.
enum MrScope { assigned, review, created, all }

extension MrScopeX on MrScope {
  String get apiValue => switch (this) {
    MrScope.assigned => 'assigned_to_me',
    MrScope.review => 'reviewer_id',
    MrScope.created => 'created_by_me',
    MrScope.all => 'all',
  };

  String get label => switch (this) {
    MrScope.assigned => 'Assigned',
    MrScope.review => 'Review',
    MrScope.created => 'Created',
    MrScope.all => 'All',
  };
}

/// `/merge_requests`, `/projects/:id/merge_requests`, notes, changes,
/// and the merge/approve actions.
class MergeRequestsRepository {
  const MergeRequestsRepository(this._client);

  final GitLabApiClient _client;

  String _p(Object projectId) =>
      '/projects/${GitLabApiClient.encodeProject(projectId)}';

  /// MRs across the instance.
  Future<Paginated<MergeRequest>> mergeRequests({
    MrScope scope = MrScope.assigned,
    String? state,
    String? search,
    int page = 1,
    int perPage = 20,
  }) {
    // The reviewer scope uses reviewer_id=<self> via `reviewer_username`;
    // 'reviewer_id' alone isn't a scope value, so map it explicitly.
    final query = <String, Object?>{'state': ?state, 'search': ?search};
    if (scope == MrScope.review) {
      query['scope'] = 'all';
      query['reviewer_id'] = 'self';
    } else {
      query['scope'] = scope.apiValue;
    }
    return _client.getPage(
      '/merge_requests',
      query: query,
      page: page,
      perPage: perPage,
      decoder: (j) => MergeRequest.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// MRs inside one project.
  Future<Paginated<MergeRequest>> projectMergeRequests(
    Object projectId, {
    String? state,
    String? search,
    String? labels,
    String? targetBranch,
    int? milestoneId,
    int page = 1,
    int perPage = 20,
  }) {
    return _client.getPage(
      '${_p(projectId)}/merge_requests',
      query: {
        'state': ?state,
        'search': ?search,
        'labels': ?labels,
        'target_branch': ?targetBranch,
        'milestone': ?milestoneId?.toString(),
      },
      page: page,
      perPage: perPage,
      decoder: (j) => MergeRequest.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<MergeRequest> mergeRequest(Object projectId, int iid) {
    return _client.get(
      '${_p(projectId)}/merge_requests/$iid',
      decoder: (j) => MergeRequest.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Changed files for an MR (`/changes` is deprecated upstream but
  /// still the most compatible way to get diffs for self-hosted).
  Future<List<ChangeEntry>> changes(Object projectId, int iid) {
    return _client.get(
      '${_p(projectId)}/merge_requests/$iid/changes',
      decoder: (j) {
        final map = j! as Map<String, dynamic>;
        final changes = map['changes'];
        if (changes is! List) {
          return const <ChangeEntry>[];
        }
        return changes
            .whereType<Map<String, dynamic>>()
            .map(ChangeEntry.fromJson)
            .toList();
      },
    );
  }

  /// Commits on the source branch since the merge base.
  Future<Paginated<Commit>> commits(
    Object projectId,
    int iid, {
    int page = 1,
    int perPage = 50,
  }) {
    return _client.getPage(
      '${_p(projectId)}/merge_requests/$iid/commits',
      page: page,
      perPage: perPage,
      decoder: (j) => Commit.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<MergeRequest> createMergeRequest(
    Object projectId, {
    required String sourceBranch,
    required String targetBranch,
    required String title,
    String? description,
    List<String>? labels,
    List<int>? assigneeIds,
    List<int>? reviewerIds,
    int? milestoneId,
    bool squash = false,
    bool removeSourceBranch = false,
  }) {
    return _client.post(
      '${_p(projectId)}/merge_requests',
      body: {
        'source_branch': sourceBranch,
        'target_branch': targetBranch,
        'title': title,
        'description': ?description,
        'labels': ?labels?.join(','),
        'assignee_ids': ?assigneeIds,
        'reviewer_ids': ?reviewerIds,
        'milestone_id': ?milestoneId,
        if (squash) 'squash': true,
        if (removeSourceBranch) 'remove_source_branch': true,
      },
      decoder: (j) => MergeRequest.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<MergeRequest> updateMergeRequest(
    Object projectId,
    int iid, {
    String? title,
    String? description,
    String? stateEvent,
    String? targetBranch,
    List<String>? labels,
    List<int>? assigneeIds,
    List<int>? reviewerIds,
    int? milestoneId,
  }) {
    return _client.put(
      '${_p(projectId)}/merge_requests/$iid',
      body: {
        'title': ?title,
        'description': ?description,
        'state_event': ?stateEvent,
        'target_branch': ?targetBranch,
        'labels': ?labels?.join(','),
        'assignee_ids': ?assigneeIds,
        'reviewer_ids': ?reviewerIds,
        'milestone_id': ?milestoneId,
      },
      decoder: (j) => MergeRequest.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// The merge action itself.
  Future<MergeRequest> merge(
    Object projectId,
    int iid, {
    bool squash = false,
    bool removeSourceBranch = false,
    String? mergeCommitMessage,
    String? sha,
    bool mergeWhenPipelineSucceeds = false,
  }) {
    return _client.put(
      '${_p(projectId)}/merge_requests/$iid/merge',
      body: {
        if (squash) 'squash': true,
        if (removeSourceBranch) 'should_remove_source_branch': true,
        'merge_commit_message': ?mergeCommitMessage,
        'sha': ?sha,
        if (mergeWhenPipelineSucceeds) 'merge_when_pipeline_succeeds': true,
      },
      decoder: (j) => MergeRequest.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<MergeRequest> rebase(Object projectId, int iid) {
    return _client.put(
      '${_p(projectId)}/merge_requests/$iid/rebase',
      decoder: (j) => MergeRequest.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<ApprovalState> approvals(Object projectId, int iid) {
    return _client.get(
      '${_p(projectId)}/merge_requests/$iid/approvals',
      decoder: (j) => ApprovalState.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<void> approve(Object projectId, int iid) {
    return _client.post(
      '${_p(projectId)}/merge_requests/$iid/approve',
      decoder: (j) => j,
    );
  }

  Future<void> unapprove(Object projectId, int iid) {
    return _client.post(
      '${_p(projectId)}/merge_requests/$iid/unapprove',
      decoder: (j) => j,
    );
  }

  /// Threads (diff comments + regular comments), oldest first.
  Future<Paginated<Discussion>> discussions(
    Object projectId,
    int iid, {
    int page = 1,
    int perPage = 30,
  }) {
    return _client.getPage(
      '${_p(projectId)}/merge_requests/$iid/discussions',
      query: {'per_page': perPage},
      page: page,
      decoder: (j) => Discussion.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// One thread by id.
  Future<Discussion> discussion(
    Object projectId,
    int iid,
    String discussionId,
  ) {
    return _client.get(
      '${_p(projectId)}/merge_requests/$iid/discussions/$discussionId',
      decoder: (j) => Discussion.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Starts a new thread; pass [position] for a diff-line comment.
  /// Empty strings are stripped from the position payload — GitLab
  /// rejects blank path/sha fields.
  Future<Discussion> addDiscussion(
    Object projectId,
    int iid,
    String body, {
    NotePosition? position,
  }) {
    return _client.post(
      '${_p(projectId)}/merge_requests/$iid/discussions',
      body: {
        'body': body,
        if (position != null)
          'position': <String, Object?>{
            'base_sha': position.baseSha,
            'start_sha': position.startSha,
            'head_sha': position.headSha,
            'position_type': 'text',
            'old_path': position.oldPath,
            'new_path': position.newPath,
            'old_line': position.oldLine,
            'new_line': position.newLine,
          }..removeWhere((_, v) => v == null || (v is String && v.isEmpty)),
      },
      decoder: (j) => Discussion.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Replies inside an existing thread.
  Future<Note> replyToDiscussion(
    Object projectId,
    int iid,
    String discussionId,
    String body,
  ) {
    return _client.post(
      '${_p(projectId)}/merge_requests/$iid/discussions/$discussionId/notes',
      body: {'body': body},
      decoder: (j) => Note.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Marks a whole thread resolved/unresolved.
  Future<Discussion> setDiscussionResolved(
    Object projectId,
    int iid,
    String discussionId, {
    required bool resolved,
  }) {
    return _client.put(
      '${_p(projectId)}/merge_requests/$iid/discussions/$discussionId',
      body: {'resolved': resolved},
      decoder: (j) => Discussion.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Emoji reactions on the MR.
  Future<List<AwardEmoji>> awardEmojis(Object projectId, int iid) {
    return _client.getAll(
      '${_p(projectId)}/merge_requests/$iid/award_emoji',
      decoder: (j) => AwardEmoji.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Reactions on a single note.
  Future<List<AwardEmoji>> noteAwardEmojis(
    Object projectId,
    int iid,
    int noteId,
  ) {
    return _client.getAll(
      '${_p(projectId)}/merge_requests/$iid/notes/$noteId/award_emoji',
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
        ? '${_p(projectId)}/merge_requests/$iid/award_emoji'
        : '${_p(projectId)}/merge_requests/$iid/notes/$noteId/award_emoji';
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
        ? '${_p(projectId)}/merge_requests/$iid/award_emoji'
        : '${_p(projectId)}/merge_requests/$iid/notes/$noteId/award_emoji';
    return _client.delete('$base/$awardId');
  }

  /// Toggles the user's subscription on the MR.
  Future<MergeRequest> setSubscribed(
    Object projectId,
    int iid, {
    required bool subscribed,
  }) {
    return _client.post(
      '${_p(projectId)}/merge_requests/$iid/'
      '${subscribed ? 'subscribe' : 'unsubscribe'}',
      decoder: (j) => MergeRequest.fromJson(j! as Map<String, dynamic>),
    );
  }
}
