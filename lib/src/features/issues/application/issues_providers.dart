import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/core/api/paged_list.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/core/models/note.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/issues/data/issues_repository.dart';
import 'package:glam/src/features/issues/domain/issue.dart';

final issuesRepositoryProvider = Provider<IssuesRepository>(
  (ref) => IssuesRepository(ref.watch(apiClientProvider)),
);

/// Filter state for the global issues list.
typedef IssueFilter = ({IssueScope scope, String? state, String? search});

const defaultIssueFilter = (
  scope: IssueScope.assigned,
  state: 'opened',
  search: null,
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
          page: page,
        );
  }
}

/// (project, state) for project-scoped issue lists.
typedef ProjectIssueFilter = ({Object project, String? state, String? search});

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
          page: page,
        );
  }
}

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
    return note;
  }
}
