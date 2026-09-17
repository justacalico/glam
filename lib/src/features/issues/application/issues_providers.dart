import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/api/paged_list.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/core/models/note.dart';
import 'package:glam/src/core/models/resource_label_event.dart';
import 'package:glam/src/core/models/resource_milestone_event.dart';
import 'package:glam/src/core/models/resource_state_event.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/auth/domain/user.dart';
import 'package:glam/src/features/issues/data/issues_repository.dart';
import 'package:glam/src/features/issues/domain/issue.dart';
import 'package:glam/src/features/issues/domain/issue_link.dart';
import 'package:glam/src/features/issues/domain/issue_statistics.dart';
import 'package:glam/src/features/merge_requests/domain/merge_request.dart';

final issuesRepositoryProvider = Provider<IssuesRepository>(
  (ref) => IssuesRepository(ref.watch(apiClientProvider)),
);

/// Filter state for the global issues list.
typedef IssueFilter = ({
  IssueScope scope,
  String? state,
  String? search,
  String? issueType,
  String? orderBy,
  String? sort,
});

const defaultIssueFilter = (
  scope: IssueScope.assigned,
  state: 'opened',
  search: null,
  issueType: null,
  orderBy: null,
  sort: null,
);

final issueFilterProvider = NotifierProvider<IssueFilterNotifier, IssueFilter>(
  IssueFilterNotifier.new,
);

class IssueFilterNotifier extends Notifier<IssueFilter> {
  @override
  IssueFilter build() => defaultIssueFilter;

  void update(IssueFilter filter) => state = filter;
}

final issuesProvider =
    AsyncNotifierProvider<IssuesNotifier, PagedListState<Issue>>(
      IssuesNotifier.new,
    );

class IssuesNotifier extends PagedListNotifier<Issue> {
  @override
  Future<Paginated<Issue>> fetchPage(int page) {
    final filter = ref.watch(issueFilterProvider);
    return ref
        .watch(issuesRepositoryProvider)
        .issues(
          scope: filter.scope,
          state: filter.state,
          search: filter.search,
          issueType: filter.issueType,
          orderBy: filter.orderBy,
          sort: filter.sort,
          page: page,
        );
  }
}

/// (project, state) for project-scoped issue lists.
typedef ProjectIssueFilter = ({
  Object project,
  String? state,
  String? search,
  String? label,
  String? milestone,
  String? issueType,
  int? assigneeId,
  String? orderBy,
  String? sort,
});

final projectIssuesProvider =
    AsyncNotifierProvider.family<
      ProjectIssuesNotifier,
      PagedListState<Issue>,
      ProjectIssueFilter
    >(ProjectIssuesNotifier.new);

class ProjectIssuesNotifier extends PagedListNotifier<Issue> {
  ProjectIssuesNotifier(this.filter);

  final ProjectIssueFilter filter;

  @override
  Future<Paginated<Issue>> fetchPage(int page) {
    return ref
        .watch(issuesRepositoryProvider)
        .projectIssues(
          filter.project,
          state: filter.state,
          search: filter.search,
          labels: filter.label,
          milestone: filter.milestone,
          issueType: filter.issueType,
          assigneeId: filter.assigneeId,
          orderBy: filter.orderBy,
          sort: filter.sort,
          page: page,
        );
  }
}

/// Open/closed counts for the project issues tab.
final projectIssueStatsProvider =
    FutureProvider.family<IssueStatistics, Object>(
      (ref, project) =>
          ref.watch(issuesRepositoryProvider).projectIssuesStatistics(project),
    );

/// (project, iid) for a single issue.
typedef IssueRef = ({Object project, int iid});

final issueProvider = FutureProvider.family<Issue, IssueRef>(
  (ref, loc) => ref.watch(issuesRepositoryProvider).issue(loc.project, loc.iid),
);

final issueNotesProvider =
    AsyncNotifierProvider.family<
      IssueNotesNotifier,
      PagedListState<Note>,
      IssueRef
    >(IssueNotesNotifier.new);

class IssueNotesNotifier extends PagedListNotifier<Note> {
  IssueNotesNotifier(this.loc);

  final IssueRef loc;

  @override
  Future<Paginated<Note>> fetchPage(int page) {
    return ref
        .watch(issuesRepositoryProvider)
        .notes(loc.project, loc.iid, page: page);
  }

  /// Posts a comment then reloads the thread.
  Future<Note> addComment(String body) async {
    final note = await ref
        .read(issuesRepositoryProvider)
        .addNote(loc.project, loc.iid, body);
    await refresh();
    ref.invalidate(issueParticipantsProvider(loc));
    return note;
  }

  /// Edits a note then reloads the thread.
  Future<void> editComment(int noteId, String body) async {
    await ref
        .read(issuesRepositoryProvider)
        .updateNote(loc.project, loc.iid, noteId, body);
    await refresh();
  }

  /// Deletes a note then reloads the thread.
  Future<void> deleteComment(int noteId) async {
    await ref
        .read(issuesRepositoryProvider)
        .deleteNote(loc.project, loc.iid, noteId);
    await refresh();
  }
}

/// Links between this issue and others (relates_to / blocks /
/// is_blocked_by).
final issueLinksProvider =
    AsyncNotifierProvider.family<IssueLinksNotifier, List<IssueLink>, IssueRef>(
      IssueLinksNotifier.new,
    );

class IssueLinksNotifier extends AsyncNotifier<List<IssueLink>> {
  IssueLinksNotifier(this.loc);

  final IssueRef loc;

  @override
  Future<List<IssueLink>> build() {
    return ref.watch(issuesRepositoryProvider).issueLinks(loc.project, loc.iid);
  }

  /// Adds a link then refetches without a reload spinner — `link_type`
  /// like `is_blocked_by` can flip the stored direction, so trusting
  /// the POST body for an in-place insert would be wrong.
  Future<IssueLink> link(
    Object targetProject,
    int targetIid,
    String linkType,
  ) async {
    final created = await ref
        .read(issuesRepositoryProvider)
        .linkIssue(
          loc.project,
          loc.iid,
          targetProject: targetProject,
          targetIid: targetIid,
          linkType: linkType,
        );
    state = AsyncData(
      await ref.read(issuesRepositoryProvider).issueLinks(loc.project, loc.iid),
    );
    // The link writes a system note ("marked as related to #5").
    ref.invalidate(issueNotesProvider(loc));
    return created;
  }

  /// Removes the link in place so the row disappears without a refetch.
  Future<void> unlink(int linkId) async {
    await ref
        .read(issuesRepositoryProvider)
        .unlinkIssue(loc.project, loc.iid, linkId);
    final current = state.value;
    if (current != null) {
      state = AsyncData([
        for (final l in current)
          if (l.linkId != linkId) l,
      ]);
    }
    ref.invalidate(issueNotesProvider(loc));
  }
}

/// Merge requests related to this issue.
final issueRelatedMrsProvider =
    FutureProvider.family<List<MergeRequest>, IssueRef>(
      (ref, loc) => ref
          .watch(issuesRepositoryProvider)
          .relatedMergeRequests(loc.project, loc.iid),
    );

/// MRs that close this issue on merge (`/issues/:iid/closed_by`).
final issueClosedByMrsProvider =
    FutureProvider.family<List<MergeRequest>, IssueRef>(
      (ref, loc) => ref
          .watch(issuesRepositoryProvider)
          .closedByMergeRequests(loc.project, loc.iid),
    );

final issueParticipantsProvider =
    FutureProvider.family<List<GitLabUser>, IssueRef>(
      (ref, loc) => ref
          .watch(issuesRepositoryProvider)
          .participants(loc.project, loc.iid),
    );

/// Close/reopen history. Missing on older instances; treat as empty.
final issueStateEventsProvider =
    FutureProvider.family<List<ResourceStateEvent>, IssueRef>((ref, loc) async {
      try {
        return await ref
            .watch(issuesRepositoryProvider)
            .stateEvents(loc.project, loc.iid);
      } on ApiException catch (e) {
        if (e.statusCode == 403 || e.statusCode == 404) {
          return const [];
        }
        rethrow;
      }
    });

/// Milestone add/remove history. Missing on older instances.
final issueMilestoneEventsProvider =
    FutureProvider.family<List<ResourceMilestoneEvent>, IssueRef>((
      ref,
      loc,
    ) async {
      try {
        return await ref
            .watch(issuesRepositoryProvider)
            .milestoneEvents(loc.project, loc.iid);
      } on ApiException catch (e) {
        if (e.statusCode == 403 || e.statusCode == 404) {
          return const [];
        }
        rethrow;
      }
    });

/// Label add/remove history. Missing on older instances.
final issueLabelEventsProvider =
    FutureProvider.family<List<ResourceLabelEvent>, IssueRef>((ref, loc) async {
      try {
        return await ref
            .watch(issuesRepositoryProvider)
            .labelEvents(loc.project, loc.iid);
      } on ApiException catch (e) {
        if (e.statusCode == 403 || e.statusCode == 404) {
          return const [];
        }
        rethrow;
      }
    });
