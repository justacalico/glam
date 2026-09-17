import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/avatar_stack.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/features/issues/presentation/issue_tile.dart';
import 'package:glam/src/features/merge_requests/application/mr_providers.dart';
import 'package:glam/src/features/merge_requests/domain/merge_request.dart';
import 'package:glam/src/features/merge_requests/presentation/mr_tile.dart';
import 'package:glam/src/features/pipelines/application/pipelines_providers.dart';
import 'package:glam/src/features/pipelines/domain/pipeline.dart';
import 'package:glam/src/features/pipelines/presentation/pipelines_screen.dart';

/// Pipelines attached to this MR plus a run button (open MRs only).
class MrPipelinesTab extends ConsumerStatefulWidget {
  const MrPipelinesTab({required this.mr, required this.loc, super.key});

  final MergeRequest mr;
  final MrRef loc;

  @override
  ConsumerState<MrPipelinesTab> createState() => _MrPipelinesTabState();
}

class _MrPipelinesTabState extends ConsumerState<MrPipelinesTab> {
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pipelines = ref.watch(mrPipelinesProvider(widget.loc));

    return AsyncValueWidget<List<Pipeline>>(
      value: pipelines,
      onRetry: () => ref.invalidate(mrPipelinesProvider(widget.loc)),
      data: (list) => RefreshIndicator(
        onRefresh: () => ref.refresh(mrPipelinesProvider(widget.loc).future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (widget.mr.isOpen)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(Insets.sm),
                  child: TextButton.icon(
                    onPressed: _busy ? null : _run,
                    icon: const Icon(Icons.play_arrow_outlined, size: 18),
                    label: const Text('Run pipeline'),
                  ),
                ),
              ),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.all(Insets.xl),
                child: EmptyState(
                  icon: Icons.rocket_launch_outlined,
                  title: 'No pipelines for this MR',
                ),
              )
            else
              for (final p in list)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PipelineTile(pipeline: p, projectId: widget.loc.project),
                    Divider(height: 1, color: colors.border, indent: Insets.lg),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _run() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(mrRepositoryProvider)
          .createMrPipeline(widget.loc.project, widget.loc.iid);
      if (!mounted) {
        return;
      }
      ref
        ..invalidate(mrPipelinesProvider(widget.loc))
        ..invalidate(mrProvider(widget.loc))
        ..invalidate(pipelinesProvider);
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

/// Issues this MR will close when merged.
class MrClosesIssuesRow extends ConsumerWidget {
  const MrClosesIssuesRow({required this.loc, super.key});

  final MrRef loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issues = ref.watch(mrClosesIssuesProvider(loc));
    return issues.maybeWhen(
      data: (items) => items.isEmpty
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: Insets.md),
                Text(
                  'Closes ${items.length} '
                  'issue${items.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: Insets.xs),
                for (final issue in items)
                  IssueTile(
                    issue: issue,
                    onTap: () => unawaited(
                      context.push(
                        Routes.projectIssue(issue.projectId, issue.iid),
                      ),
                    ),
                  ),
              ],
            ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// Avatars of everyone who commented or reacted on the MR.
class MrParticipantsRow extends ConsumerWidget {
  const MrParticipantsRow({required this.loc, super.key});

  final MrRef loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participants = ref.watch(mrParticipantsProvider(loc));
    return participants.maybeWhen(
      data: (users) => users.isEmpty
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: Insets.md),
                Text(
                  '${users.length} '
                  'participant${users.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: Insets.xs),
                AvatarStack(users: users, max: 8),
              ],
            ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// MRs related to this one via mentions or shared branches.
class MrRelatedMrsRow extends ConsumerWidget {
  const MrRelatedMrsRow({required this.loc, super.key});

  final MrRef loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mrs = ref.watch(mrRelatedMrsProvider(loc));
    return mrs.maybeWhen(
      data: (items) => items.isEmpty
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: Insets.md),
                Text(
                  'Related merge request${items.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: Insets.xs),
                for (final mr in items)
                  MrTile(
                    mr: mr,
                    onTap: () => unawaited(
                      context.push(Routes.projectMr(mr.projectId, mr.iid)),
                    ),
                  ),
              ],
            ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}
