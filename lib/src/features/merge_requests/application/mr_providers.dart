import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/core/api/paged_list.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/core/models/discussion.dart';
import 'package:glam/src/core/models/note.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/merge_requests/data/merge_requests_repository.dart';
import 'package:glam/src/features/merge_requests/domain/merge_request.dart';
import 'package:glam/src/features/repository/domain/repo_models.dart';

final mrRepositoryProvider = Provider<MergeRequestsRepository>(
  (ref) => MergeRequestsRepository(ref.watch(apiClientProvider)),
);

typedef MrFilter = ({MrScope scope, String? state, String? search});

const defaultMrFilter = (
  scope: MrScope.assigned,
  state: 'opened',
  search: null,
);

final mrFilterProvider = NotifierProvider<MrFilterNotifier, MrFilter>(
  MrFilterNotifier.new,
);

class MrFilterNotifier extends Notifier<MrFilter> {
  @override
  MrFilter build() => defaultMrFilter;

  void update(MrFilter filter) => state = filter;
}

final mergeRequestsProvider =
    AsyncNotifierProvider<MergeRequestsNotifier, PagedListState<MergeRequest>>(
      MergeRequestsNotifier.new,
    );

class MergeRequestsNotifier extends PagedListNotifier<MergeRequest> {
  @override
  Future<Paginated<MergeRequest>> fetchPage(int page) {
    final filter = ref.watch(mrFilterProvider);
    return ref
        .watch(mrRepositoryProvider)
        .mergeRequests(
          scope: filter.scope,
          state: filter.state,
          search: filter.search,
          page: page,
        );
  }
}

typedef ProjectMrFilter = ({Object project, String? state, String? search});

final projectMrsProvider =
    AsyncNotifierProvider.family<
      ProjectMrsNotifier,
      PagedListState<MergeRequest>,
      ProjectMrFilter
    >(ProjectMrsNotifier.new);

class ProjectMrsNotifier extends PagedListNotifier<MergeRequest> {
  ProjectMrsNotifier(this.filter);

  final ProjectMrFilter filter;

  @override
  Future<Paginated<MergeRequest>> fetchPage(int page) {
    return ref
        .watch(mrRepositoryProvider)
        .projectMergeRequests(
          filter.project,
          state: filter.state,
          search: filter.search,
          page: page,
        );
  }
}

typedef MrRef = ({Object project, int iid});

final mrProvider = FutureProvider.family<MergeRequest, MrRef>(
  (ref, loc) =>
      ref.watch(mrRepositoryProvider).mergeRequest(loc.project, loc.iid),
);

final mrChangesProvider = FutureProvider.family<List<ChangeEntry>, MrRef>(
  (ref, loc) => ref.watch(mrRepositoryProvider).changes(loc.project, loc.iid),
);

final mrApprovalsProvider = FutureProvider.family<ApprovalState, MrRef>(
  (ref, loc) => ref.watch(mrRepositoryProvider).approvals(loc.project, loc.iid),
);

final mrCommitsProvider =
    AsyncNotifierProvider.family<
      MrCommitsNotifier,
      PagedListState<Commit>,
      MrRef
    >(MrCommitsNotifier.new);

class MrCommitsNotifier extends PagedListNotifier<Commit> {
  MrCommitsNotifier(this.loc);

  final MrRef loc;

  @override
  Future<Paginated<Commit>> fetchPage(int page) {
    return ref
        .watch(mrRepositoryProvider)
        .commits(loc.project, loc.iid, page: page);
  }
}

final mrNotesProvider =
    AsyncNotifierProvider.family<MrNotesNotifier, PagedListState<Note>, MrRef>(
      MrNotesNotifier.new,
    );

class MrNotesNotifier extends PagedListNotifier<Note> {
  MrNotesNotifier(this.loc);

  final MrRef loc;

  @override
  Future<Paginated<Note>> fetchPage(int page) {
    return ref
        .watch(mrRepositoryProvider)
        .notes(loc.project, loc.iid, page: page);
  }

  Future<Note> addComment(String body) async {
    final note = await ref
        .read(mrRepositoryProvider)
        .addNote(loc.project, loc.iid, body);
    await refresh();
    return note;
  }
}

/// Threaded discussions (diff comments + threads) for the overview tab.
final mrDiscussionsProvider =
    AsyncNotifierProvider.family<
      MrDiscussionsNotifier,
      PagedListState<Discussion>,
      MrRef
    >(MrDiscussionsNotifier.new);

class MrDiscussionsNotifier extends PagedListNotifier<Discussion> {
  MrDiscussionsNotifier(this.loc);

  final MrRef loc;

  @override
  Future<Paginated<Discussion>> fetchPage(int page) {
    return ref
        .watch(mrRepositoryProvider)
        .discussions(loc.project, loc.iid, page: page);
  }

  /// Top-level comment (individual note thread).
  Future<void> addComment(String body) async {
    await ref
        .read(mrRepositoryProvider)
        .addDiscussion(loc.project, loc.iid, body);
    await refresh();
  }

  /// Comment pinned to a diff line.
  Future<void> addDiffComment(String body, NotePosition position) async {
    await ref
        .read(mrRepositoryProvider)
        .addDiscussion(loc.project, loc.iid, body, position: position);
    await refresh();
  }

  Future<void> reply(String discussionId, String body) async {
    await ref
        .read(mrRepositoryProvider)
        .replyToDiscussion(loc.project, loc.iid, discussionId, body);
    await refresh();
  }

  Future<void> toggleResolved(Discussion discussion) async {
    final first = discussion.notes.where((n) => n.resolvable).firstOrNull;
    if (first == null) {
      return;
    }
    await ref
        .read(mrRepositoryProvider)
        .resolveDiscussion(
          loc.project,
          loc.iid,
          discussion.id,
          first.id,
          resolved: !discussion.resolved,
        );
    await refresh();
  }
}
