import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
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
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/auth/domain/user.dart';
import 'package:glam/src/features/engagement/presentation/reactions_row.dart';
import 'package:glam/src/features/merge_requests/application/mr_providers.dart';
import 'package:glam/src/features/merge_requests/presentation/discussion_card.dart';
import 'package:glam/src/features/merge_requests/domain/draft_note.dart';
import 'package:glam/src/features/merge_requests/domain/merge_request.dart';
import 'package:glam/src/features/merge_requests/presentation/mr_form_screen.dart';
import 'package:glam/src/features/merge_requests/presentation/mr_pipelines_tab.dart';
import 'package:glam/src/features/repository/application/repository_providers.dart';
import 'package:glam/src/features/repository/domain/repo_models.dart';
import 'package:glam/src/features/repository/presentation/commits_screen.dart';

/// MR detail with four tabs: overview (desc + activity), changed
/// files, the commit list, and pipelines. Merge actions live in a
/// bottom sheet.
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
      length: 4,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Changes'),
              Tab(text: 'Commits'),
              Tab(text: 'Pipelines'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _OverviewTab(mr: mr, loc: loc),
                _ChangesTab(mr: mr, loc: loc),
                _CommitsTab(loc: loc),
                MrPipelinesTab(mr: mr, loc: loc),
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
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.pixels > n.metrics.maxScrollExtent - 400) {
                unawaited(
                  ref.read(mrDiscussionsProvider(loc).notifier).loadMore(),
                );
              }
              return false;
            },
            child: ListView(
              padding: Insets.pagePadding,
              children: [
                _MrHeader(mr: mr, loc: loc),
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
                Text(
                  'Activity',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: Insets.sm),
                threads.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(Insets.xl),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => ErrorView(
                    error: e,
                    onRetry: () => ref.invalidate(mrDiscussionsProvider(loc)),
                  ),
                  data: (state) {
                    final visible = state.items
                        .where((d) => d.notes.any((n) => !n.system))
                        .toList();
                    return Column(
                      children: [
                        if (visible.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(Insets.lg),
                            child: Text(
                              'No comments yet',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        for (final d in visible)
                          DiscussionCard(discussion: d, loc: loc),
                        if (state.loadingMore)
                          const Padding(
                            padding: EdgeInsets.all(Insets.lg),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (state.loadMoreFailed)
                          Center(
                            child: TextButton(
                              onPressed: () => ref
                                  .read(mrDiscussionsProvider(loc).notifier)
                                  .loadMore(),
                              child: const Text('Load more failed. Retry'),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: Insets.xl),
              ],
            ),
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
  const _MrHeader({required this.mr, required this.loc});

  final MergeRequest mr;
  final MrRef loc;

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
        MrParticipantsRow(loc: loc),
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
class _MergeBox extends ConsumerStatefulWidget {
  const _MergeBox({required this.mr, required this.loc});

  final MergeRequest mr;
  final MrRef loc;

  @override
  ConsumerState<_MergeBox> createState() => _MergeBoxState();
}

class _MergeBoxState extends ConsumerState<_MergeBox> {
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final mr = widget.mr;
    final loc = widget.loc;
    final colors = context.colors;
    final approvals = ref.watch(mrApprovalsProvider(loc)).value;
    final myId = ref.watch(sessionProvider).value?.user.id;
    final iApproved =
        approvals != null &&
        (approvals.userHasApproved ??
            (myId != null && approvals.approvedBy.any((u) => u.id == myId)));
    final canAct = iApproved || (approvals?.userCanApprove ?? true);
    // Pre-15.6 instances lack detailed_merge_status — fall back to the
    // older merge_status field.
    final mergeable =
        (mr.detailedMergeStatus == null
            ? mr.mergeStatus == 'can_be_merged'
            : mr.detailedMergeStatus == 'mergeable') &&
        !mr.draft &&
        !mr.hasConflicts;
    final pipelineRunning = switch (mr.headPipeline?.status) {
      'created' ||
      'waiting_for_resource' ||
      'waiting_for_callback' ||
      'preparing' ||
      'pending' ||
      'scheduled' ||
      'running' => true,
      _ => false,
    };
    // Auto-merge only makes sense while CI is the blocker — conflicts,
    // missing approvals, or unresolved discussions all 422 on schedule.
    final canAutoMerge =
        mr.mergeWhenPipelineSucceeds ||
        (mr.detailedMergeStatus == null
            ? pipelineRunning
            : const {
                'ci_still_running',
                'ci_must_pass',
              }.contains(mr.detailedMergeStatus));

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
          if (approvals != null) ...[
            const SizedBox(height: Insets.sm),
            Row(
              children: [
                if (approvals.approvalsRequired > 0)
                  Text(
                    '${approvals.approvalsRequired - approvals.approvalsLeft}'
                    '/${approvals.approvalsRequired} approvals',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (approvals.approvedBy.isNotEmpty) ...[
                  if (approvals.approvalsRequired > 0)
                    const SizedBox(width: Insets.sm),
                  AvatarStack(users: approvals.approvedBy),
                ],
              ],
            ),
          ],
          if (mr.mergeWhenPipelineSucceeds)
            Padding(
              padding: const EdgeInsets.only(top: Insets.sm),
              child: Text(
                'Scheduled to merge when the pipeline succeeds',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.inkMuted),
              ),
            ),
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
              if (approvals != null && canAct)
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => unawaited(_toggleApproval(iApproved)),
                  icon: Icon(
                    iApproved
                        ? Icons.thumb_down_outlined
                        : Icons.thumb_up_outlined,
                    size: 16,
                  ),
                  label: Text(iApproved ? 'Revoke approval' : 'Approve'),
                ),
            ],
          ),
          if (mr.mergeWhenPipelineSucceeds)
            Padding(
              padding: const EdgeInsets.only(top: Insets.sm),
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => unawaited(_cancelAutoMerge()),
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: const Text('Cancel auto-merge'),
              ),
            )
          else if (canAutoMerge)
            Padding(
              padding: const EdgeInsets.only(top: Insets.sm),
              child: OutlinedButton.icon(
                onPressed: () =>
                    unawaited(_showMergeSheet(context, ref, autoMerge: true)),
                icon: const Icon(Icons.schedule_outlined, size: 16),
                label: const Text('Merge when pipeline succeeds'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showMergeSheet(
    BuildContext context,
    WidgetRef ref, {
    bool autoMerge = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) =>
          _MergeSheet(mr: widget.mr, loc: widget.loc, autoMerge: autoMerge),
    );
  }

  Future<void> _cancelAutoMerge() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(mrRepositoryProvider)
          .cancelAutoMerge(widget.loc.project, widget.loc.iid);
      if (!mounted) {
        return;
      }
      ref
        ..invalidate(mrProvider(widget.loc))
        ..invalidate(projectMrsProvider)
        ..invalidate(mergeRequestsProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _toggleApproval(bool approved) async {
    setState(() => _busy = true);
    final repo = ref.read(mrRepositoryProvider);
    try {
      if (approved) {
        await repo.unapprove(widget.loc.project, widget.loc.iid);
      } else {
        await repo.approve(widget.loc.project, widget.loc.iid);
      }
      if (!mounted) {
        return;
      }
      ref
        ..invalidate(mrApprovalsProvider(widget.loc))
        ..invalidate(mrProvider(widget.loc));
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}

class _MergeSheet extends ConsumerStatefulWidget {
  const _MergeSheet({
    required this.mr,
    required this.loc,
    this.autoMerge = false,
  });

  final MergeRequest mr;
  final MrRef loc;

  /// Preset by the "Merge when pipeline succeeds" entry point.
  final bool autoMerge;

  @override
  ConsumerState<_MergeSheet> createState() => _MergeSheetState();
}

class _MergeSheetState extends ConsumerState<_MergeSheet> {
  var _squash = false;
  var _removeSource = false;
  var _merging = false;
  String? _error;

  late final bool _autoMerge = widget.autoMerge;

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
            mergeWhenPipelineSucceeds: _autoMerge,
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
          if (_autoMerge)
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.sm),
              child: Text(
                'Merges automatically once the pipeline succeeds.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.inkMuted),
              ),
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
                : Text(_autoMerge ? 'Set auto-merge' : 'Merge'),
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

  /// Cherry-picks or reverts the merge/squash commit onto a prompted
  /// branch, then navigates to the new commit. GitLab only exposes
  /// commit-level pick/revert, so the merge commit sha is used.
  Future<void> _pickCommit(
    BuildContext context,
    WidgetRef ref, {
    required bool revert,
  }) async {
    final sha = mr.mergeCommitSha ?? mr.squashCommitSha;
    if (sha == null) {
      return;
    }
    final label = revert ? 'Revert' : 'Cherry-pick';
    final branch = TextEditingController(text: mr.targetBranch);
    final target = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$label !${mr.iid}'),
        content: TextField(
          controller: branch,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Target branch'),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, branch.text.trim()),
            child: Text(label),
          ),
        ],
      ),
    );
    branch.dispose();
    if (target == null || target.isEmpty || !context.mounted) {
      return;
    }
    try {
      final repo = ref.read(repositoryRepositoryProvider);
      final commit = revert
          ? await repo.revert(loc.project, sha, branch: target)
          : await repo.cherryPick(loc.project, sha, branch: target);
      if (context.mounted) {
        ref.invalidate(mrDiscussionsProvider(loc));
        unawaited(context.push(Routes.projectCommit(loc.project, commit.id)));
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (action) async {
        final repo = ref.read(mrRepositoryProvider);
        try {
          switch (action) {
            case 'toggle':
              await repo.updateMergeRequest(
                loc.project,
                loc.iid,
                stateEvent: mr.isOpen ? 'close' : 'reopen',
              );
            case 'draft':
              final title = mr.draft
                  ? stripDraftPrefix(mr.title)
                  : 'Draft: ${mr.title}';
              if (title.isEmpty) {
                return;
              }
              await repo.updateMergeRequest(loc.project, loc.iid, title: title);
            case 'subscribe':
              await repo.setSubscribed(
                loc.project,
                loc.iid,
                subscribed: !mr.subscribed,
              );
            case 'rebase':
              await repo.rebase(loc.project, loc.iid);
            case 'cherry_pick':
              await _pickCommit(context, ref, revert: false);
              return;
            case 'revert':
              await _pickCommit(context, ref, revert: true);
              return;
            case 'edit':
              if (context.mounted) {
                unawaited(
                  MrFormScreen.show(context, projectId: loc.project, mr: mr),
                );
              }
              return;
            case 'copy':
              if (mr.webUrl != null) {
                unawaited(Clipboard.setData(ClipboardData(text: mr.webUrl!)));
              }
              return;
            case 'open':
              if (mr.webUrl != null) {
                unawaited(launchExternal(mr.webUrl!));
              }
              return;
          }
          if (!context.mounted) {
            return;
          }
          ref
            ..invalidate(mrProvider(loc))
            ..invalidate(projectMrsProvider)
            ..invalidate(mergeRequestsProvider);
        } on ApiException catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(e.message)));
          }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'toggle',
          child: Text(mr.isOpen ? 'Close MR' : 'Reopen MR'),
        ),
        if (mr.isOpen) ...[
          PopupMenuItem(
            value: 'draft',
            child: Text(mr.draft ? 'Mark as ready' : 'Mark as draft'),
          ),
          const PopupMenuItem(value: 'rebase', child: Text('Rebase')),
        ],
        if (mr.isMerged &&
            (mr.mergeCommitSha != null || mr.squashCommitSha != null)) ...[
          const PopupMenuItem(value: 'cherry_pick', child: Text('Cherry-pick')),
          const PopupMenuItem(value: 'revert', child: Text('Revert')),
        ],
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

class _ChangesTab extends ConsumerStatefulWidget {
  const _ChangesTab({required this.mr, required this.loc});

  final MergeRequest mr;
  final MrRef loc;

  @override
  ConsumerState<_ChangesTab> createState() => _ChangesTabState();
}

class _ChangesTabState extends ConsumerState<_ChangesTab> {
  /// Selected diff version, or null for the MR's current head.
  int? _versionId;

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;
    final versions = ref.watch(mrVersionsProvider(loc));
    // Drop the selection if a refetch no longer lists the version:
    // the dropdown asserts on unmatched values and the diff endpoint
    // would 404.
    var versionId = _versionId;
    final versionList = versions.value;
    if (versionId != null &&
        versionList != null &&
        versionList.every((v) => v.id != versionId)) {
      versionId = null;
    }
    final changes = versionId == null
        ? ref.watch(mrChangesProvider(loc))
        : ref.watch(mrVersionDiffsProvider((mr: loc, versionId: versionId)));
    final diffRefs = ref.watch(mrProvider(loc)).value?.diffRefs;

    return Column(
      children: [
        // Hoisted above the async section so pending drafts stay
        // reachable while changes load or when there are none.
        _ReviewBanner(loc: loc),
        versions.maybeWhen(
          data: (list) => list.length < 2
              ? const SizedBox.shrink()
              : _VersionPicker(
                  versions: list,
                  selected: versionId,
                  onSelected: (v) => setState(() => _versionId = v),
                ),
          orElse: () => const SizedBox.shrink(),
        ),
        Expanded(
          child: AsyncValueWidget<List<ChangeEntry>>(
            value: changes,
            onRetry: () => versionId == null
                ? ref.invalidate(mrChangesProvider(loc))
                : ref.invalidate(
                    mrVersionDiffsProvider((mr: loc, versionId: versionId)),
                  ),
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
                itemBuilder: (context, index) => _ChangeCard(
                  entry: entries[index],
                  loc: loc,
                  diffRefs: diffRefs,
                  isOpen: widget.mr.isOpen,
                  commentable: versionId == null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Dropdown for picking an older diff version, or the current head.
class _VersionPicker extends StatelessWidget {
  const _VersionPicker({
    required this.versions,
    required this.selected,
    required this.onSelected,
  });

  final List<MrVersion> versions;
  final int? selected;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    // Ids are monotonic, so this orders newest first even when
    // timestamps tie or are missing.
    final sorted = [...versions]..sort((a, b) => b.id.compareTo(a.id));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        Insets.lg,
        Insets.sm,
        Insets.lg,
        Insets.xs,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Icon(Icons.history, size: 16, color: colors.inkMuted),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: DropdownButton<int?>(
              value: selected,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              style: theme.textTheme.bodyMedium,
              items: [
                const DropdownMenuItem<int?>(child: Text('Latest changes')),
                // sorted[0] is the newest version, which shows the same
                // diff as Latest, so only older versions get entries.
                for (var i = 1; i < sorted.length; i++)
                  DropdownMenuItem<int?>(
                    value: sorted[i].id,
                    child: Text(
                      'Version ${sorted.length - i} · ${sorted[i].shortSha}'
                      ' · ${sorted[i].realSize} '
                      'file${sorted[i].realSize == 1 ? '' : 's'}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: onSelected,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows while review comments are queued: count plus publish/manage
/// actions.
class _ReviewBanner extends ConsumerStatefulWidget {
  const _ReviewBanner({required this.loc});

  final MrRef loc;

  @override
  ConsumerState<_ReviewBanner> createState() => _ReviewBannerState();
}

class _ReviewBannerState extends ConsumerState<_ReviewBanner> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final drafts = ref.watch(mrDraftNotesProvider(widget.loc));
    final count = drafts.value?.length ?? 0;
    if (count == 0) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.lg,
        vertical: Insets.sm,
      ),
      color: colors.warningSoft,
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$count pending comment${count == 1 ? '' : 's'} in your review',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          TextButton(
            onPressed: _busy ? null : _showDrafts,
            child: const Text('Review'),
          ),
          FilledButton(
            onPressed: _busy ? null : _publish,
            child: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Publish'),
          ),
        ],
      ),
    );
  }

  Future<void> _publish() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit review?'),
        content: const Text('All pending comments become visible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Publish all'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(mrDraftNotesProvider(widget.loc).notifier).publish();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _showDrafts() {
    return showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => _DraftsSheet(loc: widget.loc),
    );
  }
}

class _DraftsSheet extends ConsumerStatefulWidget {
  const _DraftsSheet({required this.loc});

  final MrRef loc;

  @override
  ConsumerState<_DraftsSheet> createState() => _DraftsSheetState();
}

class _DraftsSheetState extends ConsumerState<_DraftsSheet> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final drafts = ref.watch(mrDraftNotesProvider(widget.loc));
    final list = drafts.value ?? const [];

    if (list.isEmpty && drafts.hasValue) {
      return const Padding(
        padding: Insets.pagePadding,
        child: Text('No pending comments.'),
      );
    }
    return ListView(
      padding: Insets.pagePadding,
      children: [
        for (final d in list)
          ListTile(
            dense: true,
            leading: const Icon(Icons.rate_review_outlined, size: 18),
            title: Text(d.note, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: d.position?.label == null
                ? null
                : Text(
                    d.position!.label!,
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11.5,
                    ),
                  ),
            trailing: PopupMenuButton<String>(
              enabled: !_busy,
              onSelected: (a) => unawaited(_act(d, a)),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'publish', child: Text('Publish')),
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _act(DraftNote draft, String action) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    final notifier = ref.read(mrDraftNotesProvider(widget.loc).notifier);
    try {
      switch (action) {
        case 'publish':
          await notifier.publish(only: draft);
        case 'delete':
          await notifier.remove(draft);
        case 'edit':
          await _edit(draft);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _edit(DraftNote draft) async {
    final controller = TextEditingController(text: draft.note);
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit comment'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 5,
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.isEmpty || !mounted) {
      return;
    }
    await ref.read(mrDraftNotesProvider(widget.loc).notifier).edit(draft, text);
  }
}

class _ChangeCard extends ConsumerWidget {
  const _ChangeCard({
    required this.entry,
    required this.loc,
    required this.diffRefs,
    required this.isOpen,
    required this.commentable,
  });

  final ChangeEntry entry;
  final MrRef loc;
  final DiffRefs? diffRefs;
  final bool isOpen;

  /// Comments anchor to the MR's head refs, so line taps are only
  /// offered while viewing the latest diff.
  final bool commentable;

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
                  onLineTap: diffRefs == null || !commentable
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
    // (body, pending) — pending adds the comment to the review queue.
    final result = await showModalBottomSheet<(String, bool)>(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isOpen)
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(context, (controller.text.trim(), true)),
                    child: const Text('Add to review'),
                  ),
                const SizedBox(width: Insets.sm),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, (controller.text.trim(), false)),
                  child: const Text('Comment'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    final body = result?.$1;
    if (body == null || body.isEmpty || !context.mounted) {
      return;
    }
    // Re-read at send time: pushed commits move the diff refs.
    final refs = ref.read(mrProvider(loc)).value?.diffRefs ?? diffRefs;
    if (refs?.baseSha == null ||
        refs?.startSha == null ||
        refs?.headSha == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing diff refs. Refresh the MR and try again.'),
        ),
      );
      return;
    }
    // Removed lines anchor on the old side, added on the new, context
    // on both — GitLab needs the pair to compute the line code.
    final position = NotePosition(
      baseSha: refs!.baseSha,
      startSha: refs.startSha,
      headSha: refs.headSha,
      oldPath: entry.oldPath,
      newPath: entry.newPath,
      oldLine: line.kind == DiffLineKind.added ? null : line.oldLine,
      newLine: line.kind == DiffLineKind.removed ? null : line.newLine,
    );
    try {
      if (result!.$2) {
        await ref
            .read(mrDraftNotesProvider(loc).notifier)
            .add(body, position: position);
      } else {
        await ref
            .read(mrDiscussionsProvider(loc).notifier)
            .addDiffComment(body, position);
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
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
