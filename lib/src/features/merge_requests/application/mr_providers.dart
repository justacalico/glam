import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/api/paged_list.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/core/models/discussion.dart';
import 'package:glam/src/core/models/note.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/auth/domain/user.dart';
import 'package:glam/src/features/merge_requests/data/merge_requests_repository.dart';
import 'package:glam/src/features/merge_requests/domain/draft_note.dart';
import 'package:glam/src/features/merge_requests/domain/merge_request.dart';
import 'package:glam/src/features/pipelines/domain/pipeline.dart';
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

/// Diff versions of the MR, newest first.
final mrVersionsProvider = FutureProvider.family<List<MrVersion>, MrRef>(
  (ref, loc) => ref.watch(mrRepositoryProvider).versions(loc.project, loc.iid),
);

typedef VersionRef = ({MrRef mr, int versionId});

/// Diffs pinned to one version's SHAs.
final mrVersionDiffsProvider =
    FutureProvider.family<List<ChangeEntry>, VersionRef>(
      (ref, loc) => ref
          .watch(mrRepositoryProvider)
          .versionDiffs(loc.mr.project, loc.mr.iid, loc.versionId),
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

  /// Top-level comment (individual note thread). New threads land at
  /// the end — GitLab returns discussions oldest-first.
  Future<void> addComment(String body) async {
    final d = await ref
        .read(mrRepositoryProvider)
        .addDiscussion(loc.project, loc.iid, body);
    updateItems((items) => [...items, d]);
    ref.invalidate(mrParticipantsProvider(loc));
  }

  /// Comment pinned to a diff line.
  Future<void> addDiffComment(String body, NotePosition position) async {
    final d = await ref
        .read(mrRepositoryProvider)
        .addDiscussion(loc.project, loc.iid, body, position: position);
    updateItems((items) => [...items, d]);
    ref.invalidate(mrParticipantsProvider(loc));
  }

  /// Replies in a thread, then reloads just that thread so pages
  /// already loaded stay put.
  Future<void> reply(String discussionId, String body) async {
    final repo = ref.read(mrRepositoryProvider);
    await repo.replyToDiscussion(loc.project, loc.iid, discussionId, body);
    final updated = await repo.discussion(loc.project, loc.iid, discussionId);
    _replace(updated);
  }

  Future<void> toggleResolved(Discussion discussion) async {
    if (!discussion.resolvable) {
      return;
    }
    final updated = await ref
        .read(mrRepositoryProvider)
        .setDiscussionResolved(
          loc.project,
          loc.iid,
          discussion.id,
          resolved: !discussion.resolved,
        );
    _replace(updated);
  }

  void _replace(Discussion updated) {
    updateItems(
      (items) => [for (final d in items) d.id == updated.id ? updated : d],
    );
  }
}

final mrPipelinesProvider = FutureProvider.family<List<Pipeline>, MrRef>(
  (ref, loc) =>
      ref.watch(mrRepositoryProvider).mrPipelines(loc.project, loc.iid),
);

final mrParticipantsProvider = FutureProvider.family<List<GitLabUser>, MrRef>(
  (ref, loc) =>
      ref.watch(mrRepositoryProvider).participants(loc.project, loc.iid),
);

/// Pending review comments (draft notes) for the changes tab banner.
final mrDraftNotesProvider =
    AsyncNotifierProvider.family<MrDraftNotesNotifier, List<DraftNote>, MrRef>(
      MrDraftNotesNotifier.new,
    );

class MrDraftNotesNotifier extends AsyncNotifier<List<DraftNote>> {
  MrDraftNotesNotifier(this.loc);

  final MrRef loc;

  @override
  Future<List<DraftNote>> build() {
    return ref.watch(mrRepositoryProvider).draftNotes(loc.project, loc.iid);
  }

  /// Queues a pending comment, optionally pinned to a diff line.
  Future<void> add(String note, {NotePosition? position}) async {
    final d = await ref
        .read(mrRepositoryProvider)
        .createDraftNote(loc.project, loc.iid, note, position: position);
    // Let the initial fetch settle so it can't clobber the new item.
    await future;
    state = AsyncData([...state.value ?? const [], d]);
  }

  Future<void> edit(DraftNote draft, String note) async {
    final updated = await ref
        .read(mrRepositoryProvider)
        .updateDraftNote(loc.project, loc.iid, draft.id, note);
    state = AsyncData([
      for (final d in state.value ?? const <DraftNote>[])
        d.id == draft.id ? updated : d,
    ]);
  }

  Future<void> remove(DraftNote draft) async {
    await ref
        .read(mrRepositoryProvider)
        .deleteDraftNote(loc.project, loc.iid, draft.id);
    state = AsyncData([
      for (final d in state.value ?? const <DraftNote>[])
        if (d.id != draft.id) d,
    ]);
  }

  /// Publishes one draft or the whole review, then refreshes the
  /// discussion thread and participants.
  Future<void> publish({DraftNote? only}) async {
    final repo = ref.read(mrRepositoryProvider);
    if (only == null) {
      try {
        await repo.publishAllDraftNotes(loc.project, loc.iid);
      } on ApiException catch (e) {
        // bulk_publish needs GitLab 15.11+; fall back for older instances.
        if (e.statusCode != 404) rethrow;
        for (final d in state.value ?? const <DraftNote>[]) {
          await repo.publishDraftNote(loc.project, loc.iid, d.id);
        }
      }
      state = const AsyncData([]);
    } else {
      await repo.publishDraftNote(loc.project, loc.iid, only.id);
      state = AsyncData([
        for (final d in state.value ?? const <DraftNote>[])
          if (d.id != only.id) d,
      ]);
    }
    ref
      ..invalidate(mrDiscussionsProvider(loc))
      ..invalidate(mrParticipantsProvider(loc))
      ..invalidate(mrProvider(loc));
  }
}
