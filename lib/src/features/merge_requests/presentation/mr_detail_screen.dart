import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/models/note.dart';
import 'package:glam/src/core/utils/diff_parser.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/utils/url_launcher.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/avatar_stack.dart';
import 'package:glam/src/core/widgets/comment_composer.dart';
import 'package:glam/src/core/widgets/diff_viewer.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/error_view.dart';
import 'package:glam/src/core/widgets/label_chip.dart';
import 'package:glam/src/core/widgets/markdown_viewer.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/core/widgets/state_chip.dart';
import 'package:glam/src/core/widgets/user_avatar.dart';
import 'package:glam/src/features/auth/domain/user.dart';
import 'package:glam/src/features/engagement/presentation/reactions_row.dart';
import 'package:glam/src/features/merge_requests/application/mr_providers.dart';
import 'package:glam/src/features/merge_requests/presentation/discussion_card.dart';
import 'package:glam/src/features/merge_requests/domain/merge_request.dart';
import 'package:glam/src/features/merge_requests/presentation/mr_form_screen.dart';
import 'package:glam/src/features/repository/domain/repo_models.dart';
import 'package:glam/src/features/repository/presentation/commits_screen.dart';

/// MR detail with three tabs: overview (desc + activity), changed
/// files, and the commit list. Merge actions live in a bottom sheet.
class MrDetailScreen extends ConsumerWidget {
  const MrDetailScreen({required this.projectId, required this.iid, super.key});

  final Object projectId;
  final int iid;

  MrRef get _loc => (project: projectId, iid: iid);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mr = ref.watch(mrProvider(_loc));

    return Scaffold(
      appBar: AppBar(
        title: Text('!$iid'),
        actions: [
          mr.maybeWhen(
            data: (m) => _MrActions(mr: m, loc: _loc),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: AsyncValueWidget<MergeRequest>(
        value: mr,
        onRetry: () => ref.invalidate(mrProvider(_loc)),
        data: (m) => _MrBody(mr: m, loc: _loc),
      ),
    );
  }
}

class _MrBody extends StatelessWidget {
  const _MrBody({required this.mr, required this.loc});

  final MergeRequest mr;
  final MrRef loc;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Changes'),
              Tab(text: 'Commits'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _OverviewTab(mr: mr, loc: loc),
                _ChangesTab(loc: loc),
                _CommitsTab(loc: loc),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.mr, required this.loc});

  final MergeRequest mr;
  final MrRef loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final threads = ref.watch(mrDiscussionsProvider(loc));

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: Insets.pagePadding,
            children: [
              _MrHeader(mr: mr),
              const SizedBox(height: Insets.lg),
              if (mr.isOpen) _MergeBox(mr: mr, loc: loc),
              if (mr.description?.isNotEmpty ?? false) ...[
                const SizedBox(height: Insets.lg),
                Container(
                  padding: const EdgeInsets.all(Insets.lg),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: Radii.borderMd,
                    border: Border.all(color: colors.border),
                  ),
                  child: MarkdownViewer(data: mr.description!),
                ),
              ],
              const SizedBox(height: Insets.md),
              ReactionsRow(
                loc: (
                  kind: 'mr',
                  project: loc.project,
                  iid: loc.iid,
                  noteId: null,
                ),
              ),
              const SizedBox(height: Insets.xl),
              Text('Activity', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: Insets.sm),
              threads.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(Insets.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => ErrorView(error: e),
                data: (state) {
                  final visible = state.items
                      .where((d) => d.notes.any((n) => !n.system))
                      .toList();
                  if (visible.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(Insets.lg),
                      child: Text(
                        'No comments yet',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final d in visible)
                        DiscussionCard(discussion: d, loc: loc),
                    ],
                  );
                },
              ),
              const SizedBox(height: Insets.xl),
            ],
          ),
        ),
        if (mr.isOpen)
          CommentComposer(
            onSend: (body) async {
              await ref
                  .read(mrDiscussionsProvider(loc).notifier)
                  .addComment(body);
            },
          ),
      ],
    );
  }
}

class _MrHeader extends StatelessWidget {
  const _MrHeader({required this.mr});

  final MergeRequest mr;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StateChip.mergeRequestState(mr.state),
            if (mr.draft) ...[
              const SizedBox(width: Insets.sm),
              const StateChip(label: 'Draft', tone: ChipTone.neutral),
            ],
            if (mr.headPipeline?.status != null) ...[
              const SizedBox(width: Insets.sm),
              StateChip.pipeline(mr.headPipeline!.status!),
            ],
          ],
        ),
        const SizedBox(height: Insets.sm),
        Text(mr.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: Insets.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.md,
            vertical: Insets.sm,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceMuted,
            borderRadius: Radii.borderMd,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  mr.sourceBranch,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.sm),
                child: Icon(
                  Icons.arrow_forward,
                  size: 14,
                  color: colors.inkMuted,
                ),
              ),
              Text(
                mr.targetBranch,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12.5,
                  color: colors.inkMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Insets.sm),
        Wrap(
          spacing: Insets.lg,
          runSpacing: Insets.xs,
          children: [
            if (mr.author != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UserAvatar(
                    name: mr.author!.name,
                    avatarUrl: mr.author!.avatarUrl,
                    radius: 10,
                  ),
                  const SizedBox(width: Insets.xs),
                  Text(
                    '${mr.author!.name} opened '
                    '${Format.relative(mr.createdAt)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            if (mr.milestone != null)
              Text(mr.milestone!.title, style: theme.textTheme.bodySmall),
            if (mr.mergedBy != null)
              Text(
                'Merged by ${mr.mergedBy!.name} '
                '${Format.relative(mr.mergedAt)}',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
        if (mr.labels.isNotEmpty) ...[
          const SizedBox(height: Insets.sm),
          Wrap(
            spacing: Insets.xs,
            runSpacing: Insets.xs,
            children: [for (final l in mr.labels) LabelChip(name: l)],
          ),
        ],
        if (mr.assignees.isNotEmpty || mr.reviewers.isNotEmpty) ...[
          const SizedBox(height: Insets.md),
          Wrap(
            spacing: Insets.lg,
            runSpacing: Insets.sm,
            children: [
              if (mr.assignees.isNotEmpty)
                _People(label: 'Assignees', users: mr.assignees),
              if (mr.reviewers.isNotEmpty)
                _People(label: 'Reviewers', users: mr.reviewers),
            ],
          ),
        ],
      ],
    );
  }
}

class _People extends StatelessWidget {
  const _People({required this.label, required this.users});

  final String label;
  final List<GitLabUser> users;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: Insets.xs),
        AvatarStack(users: users),
      ],
    );
  }
}

/// Merge readiness + the merge button.
class _MergeBox extends ConsumerWidget {
  const _MergeBox({required this.mr, required this.loc});

  final MergeRequest mr;
  final MrRef loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final approvals = ref.watch(mrApprovalsProvider(loc)).value;
    final mergeable =
        mr.detailedMergeStatus == 'mergeable' && !mr.draft && !mr.hasConflicts;

    return Container(
      padding: const EdgeInsets.all(Insets.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Radii.borderMd,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                mergeable ? Icons.check_circle_outline : Icons.info_outline,
                size: 18,
                color: mergeable ? colors.success : colors.warning,
              ),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: Text(
                  mr.mergeabilityLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          if (approvals != null && approvals.approvalsRequired > 0) ...[
            const SizedBox(height: Insets.sm),
            Text(
              '${approvals.approvalsRequired - approvals.approvalsLeft}'
              '/${approvals.approvalsRequired} approvals',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: Insets.md),
          Row(
            children: [
              FilledButton.icon(
                onPressed: mergeable
                    ? () => unawaited(_showMergeSheet(context, ref))
                    : null,
                icon: const Icon(Icons.merge, size: 18),
                label: const Text('Merge'),
              ),
              const SizedBox(width: Insets.sm),
              if (approvals != null && !approvals.approved)
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(mrRepositoryProvider)
                        .approve(loc.project, loc.iid);
                    ref.invalidate(mrApprovalsProvider(loc));
                  },
                  icon: const Icon(Icons.thumb_up_outlined, size: 16),
                  label: const Text('Approve'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showMergeSheet(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _MergeSheet(mr: mr, loc: loc),
    );
  }
}

class _MergeSheet extends ConsumerStatefulWidget {
  const _MergeSheet({required this.mr, required this.loc});

  final MergeRequest mr;
  final MrRef loc;

  @override
  ConsumerState<_MergeSheet> createState() => _MergeSheetState();
}

class _MergeSheetState extends ConsumerState<_MergeSheet> {
  var _squash = false;
  var _removeSource = false;
  var _merging = false;
  String? _error;

  Future<void> _merge() async {
    setState(() {
      _merging = true;
      _error = null;
    });
    try {
      await ref
          .read(mrRepositoryProvider)
          .merge(
            widget.loc.project,
            widget.loc.iid,
            squash: _squash,
            removeSourceBranch: _removeSource,
            sha: widget.mr.sha,
          );
      ref
        ..invalidate(mrProvider(widget.loc))
        ..invalidate(projectMrsProvider);
      if (mounted) {
        context.pop();
      }
    } on ApiException catch (e) {
      setState(() {
        _merging = false;
        _error = e.message;
      });
    } on Object {
      setState(() {
        _merging = false;
        _error = 'Merge failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(Insets.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Merge !${widget.mr.iid}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: Insets.sm),
          Text(
            '${widget.mr.sourceBranch} → ${widget.mr.targetBranch}',
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 12.5,
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Squash commits'),
            value: _squash,
            onChanged: (v) => setState(() => _squash = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Delete source branch'),
            value: _removeSource,
            onChanged: (v) => setState(() => _removeSource = v),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.sm),
              child: Text(_error!, style: TextStyle(color: colors.danger)),
            ),
          const SizedBox(height: Insets.sm),
          FilledButton(
            onPressed: _merging ? null : _merge,
            child: _merging
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Merge'),
          ),
          SizedBox(
            height: Insets.lg + MediaQuery.viewPaddingOf(context).bottom,
          ),
        ],
      ),
    );
  }
}

class _MrActions extends ConsumerWidget {
  const _MrActions({required this.mr, required this.loc});

  final MergeRequest mr;
  final MrRef loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (action) async {
        final repo = ref.read(mrRepositoryProvider);
        switch (action) {
          case 'toggle':
            await repo.updateMergeRequest(
              loc.project,
              loc.iid,
              stateEvent: mr.isOpen ? 'close' : 'reopen',
            );
            ref.invalidate(mrProvider(loc));
          case 'rebase':
            await repo.rebase(loc.project, loc.iid);
          case 'subscribe':
            await repo.setSubscribed(
              loc.project,
              loc.iid,
              subscribed: !mr.subscribed,
            );
            ref.invalidate(mrProvider(loc));
          case 'edit':
            unawaited(
              MrFormScreen.show(context, projectId: loc.project, mr: mr),
            );
          case 'copy':
            if (mr.webUrl != null) {
              unawaited(Clipboard.setData(ClipboardData(text: mr.webUrl!)));
            }
          case 'open':
            if (mr.webUrl != null) {
              unawaited(launchExternal(mr.webUrl!));
            }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'toggle',
          child: Text(mr.isOpen ? 'Close MR' : 'Reopen MR'),
        ),
        if (mr.isOpen)
          const PopupMenuItem(value: 'rebase', child: Text('Rebase')),
        PopupMenuItem(
          value: 'subscribe',
          child: Text(mr.subscribed ? 'Unsubscribe' : 'Subscribe'),
        ),
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        const PopupMenuItem(value: 'copy', child: Text('Copy link')),
        const PopupMenuItem(value: 'open', child: Text('Open in browser')),
      ],
    );
  }
}

class _ChangesTab extends ConsumerWidget {
  const _ChangesTab({required this.loc});

  final MrRef loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final changes = ref.watch(mrChangesProvider(loc));
    final diffRefs = ref.watch(mrProvider(loc)).value?.diffRefs;

    return AsyncValueWidget<List<ChangeEntry>>(
      value: changes,
      onRetry: () => ref.invalidate(mrChangesProvider(loc)),
      data: (entries) {
        if (entries.isEmpty) {
          return const EmptyState(
            icon: Icons.difference_outlined,
            title: 'No changes',
          );
        }
        return ListView.separated(
          padding: Insets.pagePadding,
          itemCount: entries.length,
          separatorBuilder: (_, _) => const SizedBox(height: Insets.md),
          itemBuilder: (context, index) =>
              _ChangeCard(entry: entries[index], loc: loc, diffRefs: diffRefs),
        );
      },
    );
  }
}

class _ChangeCard extends ConsumerWidget {
  const _ChangeCard({
    required this.entry,
    required this.loc,
    required this.diffRefs,
  });

  final ChangeEntry entry;
  final MrRef loc;
  final DiffRefs? diffRefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final diff = FileDiff(
      oldPath: entry.oldPath,
      newPath: entry.newPath,
      hunks: DiffParser.parse(entry.diff),
      newFile: entry.newFile,
      deletedFile: entry.deletedFile,
      renamedFile: entry.renamedFile,
    );
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Radii.borderMd,
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.md,
              vertical: Insets.sm,
            ),
            color: colors.surfaceMuted,
            child: Row(
              children: [
                if (entry.newFile)
                  _DiffBadge(text: 'new', color: colors.success)
                else if (entry.deletedFile)
                  _DiffBadge(text: 'deleted', color: colors.danger)
                else if (entry.renamedFile)
                  _DiffBadge(text: 'renamed', color: colors.warning),
                Expanded(
                  child: Text(
                    entry.displayPath,
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (diff.hunks.isNotEmpty) ...[
                  Text(
                    '+${diff.additions}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colors.diffAdd,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                  const SizedBox(width: Insets.xs),
                  Text(
                    '-${diff.deletions}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colors.diffRemove,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (diff.hunks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(Insets.lg),
              child: Text(
                'Binary file or diff too large',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1100,
                child: DiffViewer(
                  diff: diff,
                  onLineTap: diffRefs == null
                      ? null
                      : (line) => _commentOnLine(context, ref, line),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _commentOnLine(
    BuildContext context,
    WidgetRef ref,
    DiffLine line,
  ) async {
    final controller = TextEditingController();
    final refs = diffRefs!;
    final body = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: Insets.lg,
          right: Insets.lg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + Insets.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comment on ${entry.displayPath}:'
              '${line.newLine ?? line.oldLine ?? ''}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: Insets.sm),
            TextField(
              controller: controller,
              autofocus: true,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(hintText: 'Write a comment…'),
            ),
            const SizedBox(height: Insets.md),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('Comment'),
              ),
            ),
          ],
        ),
      ),
    );
    if (body == null || body.isEmpty || !context.mounted) {
      return;
    }
    final isOldSide = line.kind == DiffLineKind.removed;
    await ref
        .read(mrDiscussionsProvider(loc).notifier)
        .addDiffComment(
          body,
          NotePosition(
            baseSha: refs.baseSha,
            startSha: refs.startSha,
            headSha: refs.headSha,
            oldPath: entry.oldPath,
            newPath: entry.newPath,
            oldLine: isOldSide ? line.oldLine : null,
            newLine: isOldSide ? null : line.newLine,
          ),
        );
  }
}

class _DiffBadge extends StatelessWidget {
  const _DiffBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: Insets.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Insets.sm, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: Radii.borderPill,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _CommitsTab extends ConsumerWidget {
  const _CommitsTab({required this.loc});

  final MrRef loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final commits = ref.watch(mrCommitsProvider(loc));
    final notifier = ref.read(mrCommitsProvider(loc).notifier);

    return AsyncValueWidget(
      value: commits,
      onRetry: notifier.refresh,
      data: (data) => PagedListView(
        state: data,
        onLoadMore: notifier.loadMore,
        onRefresh: notifier.refresh,
        padding: const EdgeInsets.symmetric(vertical: Insets.sm),
        separator: Divider(height: 1, color: colors.border, indent: Insets.lg),
        empty: const EmptyState(icon: Icons.commit, title: 'No commits'),
        itemBuilder: (context, index) => CommitTile(
          commit: data.items[index],
          projectId: loc.project.toString(),
        ),
      ),
    );
  }
}
