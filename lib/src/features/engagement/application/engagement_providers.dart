import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/core/models/award_emoji.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/issues/application/issues_providers.dart';
import 'package:glam/src/features/merge_requests/application/mr_providers.dart';
import 'package:glam/src/features/snippets/application/snippets_providers.dart';

/// Identifies something that can carry emoji reactions: an issue, an MR,
/// a note inside either, or a snippet. `project` is null for personal
/// snippets.
typedef AwardableRef = ({String kind, Object? project, int iid, int? noteId});

/// Reactions on one awardable, grouped for display by the widget layer.
final awardEmojisProvider =
    AsyncNotifierProvider.family<
      AwardEmojisNotifier,
      List<AwardEmoji>,
      AwardableRef
    >(AwardEmojisNotifier.new);

class AwardEmojisNotifier extends AsyncNotifier<List<AwardEmoji>> {
  AwardEmojisNotifier(this.loc);

  final AwardableRef loc;

  @override
  Future<List<AwardEmoji>> build() {
    return loc.noteId == null ? _fetchTop() : _fetchNote();
  }

  Future<List<AwardEmoji>> _fetchTop() {
    return switch (loc.kind) {
      'mr' =>
        ref.watch(mrRepositoryProvider).awardEmojis(loc.project!, loc.iid),
      'snippet' =>
        ref
            .watch(snippetsRepositoryProvider)
            .awardEmojis(loc.iid, projectId: loc.project),
      _ =>
        ref.watch(issuesRepositoryProvider).awardEmojis(loc.project!, loc.iid),
    };
  }

  Future<List<AwardEmoji>> _fetchNote() {
    return switch (loc.kind) {
      'mr' =>
        ref
            .watch(mrRepositoryProvider)
            .noteAwardEmojis(loc.project!, loc.iid, loc.noteId!),
      'snippet' =>
        ref
            .watch(snippetsRepositoryProvider)
            .awardEmojis(loc.iid, projectId: loc.project, noteId: loc.noteId),
      _ =>
        ref
            .watch(issuesRepositoryProvider)
            .noteAwardEmojis(loc.project!, loc.iid, loc.noteId!),
    };
  }

  Future<void> _add(String name) {
    return switch (loc.kind) {
      'mr' =>
        ref
            .read(mrRepositoryProvider)
            .award(loc.project!, loc.iid, name, noteId: loc.noteId),
      'snippet' =>
        ref
            .read(snippetsRepositoryProvider)
            .award(loc.iid, name, projectId: loc.project, noteId: loc.noteId),
      _ =>
        ref
            .read(issuesRepositoryProvider)
            .award(loc.project!, loc.iid, name, noteId: loc.noteId),
    };
  }

  Future<void> _remove(int awardId) {
    return switch (loc.kind) {
      'mr' =>
        ref
            .read(mrRepositoryProvider)
            .removeAward(loc.project!, loc.iid, awardId, noteId: loc.noteId),
      'snippet' =>
        ref
            .read(snippetsRepositoryProvider)
            .removeAward(
              loc.iid,
              awardId,
              projectId: loc.project,
              noteId: loc.noteId,
            ),
      _ =>
        ref
            .read(issuesRepositoryProvider)
            .removeAward(loc.project!, loc.iid, awardId, noteId: loc.noteId),
    };
  }

  /// Adds the reaction, or removes the current user's existing one.
  Future<void> toggle(String name) async {
    final userId = (await ref.read(sessionProvider.future))?.user.id;
    final existing = state.value?.where(
      (a) => a.name == name && a.user?.id == userId,
    );
    if (existing != null && existing.isNotEmpty) {
      await _remove(existing.first.id);
    } else {
      await _add(name);
    }
    state = AsyncData(await build());
  }
}
