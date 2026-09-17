import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/utils/url_launcher.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/state_chip.dart';
import 'package:glam/src/features/pipelines/application/pipelines_providers.dart';
import 'package:glam/src/features/pipelines/domain/pipeline.dart';
import 'package:glam/src/app/theme/app_typography.dart';

/// Job page: meta header plus the full console trace in monospace.
class JobDetailScreen extends ConsumerWidget {
  const JobDetailScreen({
    required this.projectId,
    required this.jobId,
    super.key,
  });

  final Object projectId;
  final int jobId;

  JobRef get _loc => (project: projectId, id: jobId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(jobProvider(_loc));

    return Scaffold(
      appBar: AppBar(
        title: job.maybeWhen(
          data: (j) => Text(j.name),
          orElse: () => Text('Job #$jobId'),
        ),
        actions: [
          job.maybeWhen(
            data: (j) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (j.status == 'running' || j.status == 'pending')
                  IconButton(
                    tooltip: 'Cancel',
                    icon: const Icon(Icons.stop_circle_outlined),
                    onPressed: () => unawaited(_act(context, ref, 'cancel')),
                  )
                else
                  IconButton(
                    tooltip: 'Retry',
                    icon: const Icon(Icons.refresh),
                    onPressed: () => unawaited(
                      _act(
                        context,
                        ref,
                        j.status == 'manual' ? 'play' : 'retry',
                      ),
                    ),
                  ),
                if (j.webUrl != null)
                  IconButton(
                    tooltip: 'Open in browser',
                    icon: const Icon(Icons.open_in_new, size: 20),
                    onPressed: () => unawaited(launchExternal(j.webUrl!)),
                  ),
                _JobMenu(
                  job: j,
                  onAction: (a) => unawaited(_act(context, ref, a)),
                ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: AsyncValueWidget<Job>(
        value: job,
        onRetry: () => ref.invalidate(jobProvider(_loc)),
        data: (j) => Column(
          children: [
            _JobHeader(job: j),
            Expanded(child: _TraceView(loc: _loc)),
          ],
        ),
      ),
    );
  }

  Future<void> _act(BuildContext context, WidgetRef ref, String action) async {
    if (action == 'artifacts') {
      unawaited(context.push(Routes.projectJobArtifacts(projectId, jobId)));
      return;
    }
    if (action == 'erase' || action == 'delete_artifacts') {
      final erase = action == 'erase';
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(erase ? 'Erase job?' : 'Delete artifacts?'),
          content: Text(
            erase
                ? 'The trace and artifacts are permanently removed.'
                : 'Locked artifacts may remain. Requires a maintainer role.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(erase ? 'Erase' : 'Delete'),
            ),
          ],
        ),
      );
      if (ok != true || !context.mounted) {
        return;
      }
    }
    final repo = ref.read(pipelinesRepositoryProvider);
    try {
      await switch (action) {
        'cancel' => repo.cancelJob(projectId, jobId),
        'play' => repo.playJob(projectId, jobId),
        'erase' => repo.eraseJob(projectId, jobId),
        'keep_artifacts' => repo.keepArtifacts(projectId, jobId),
        'delete_artifacts' => repo.deleteArtifacts(projectId, jobId),
        _ => repo.retryJob(projectId, jobId),
      };
      if (!context.mounted) {
        return;
      }
      ref
        ..invalidate(jobProvider(_loc))
        ..invalidate(jobTraceProvider(_loc))
        ..invalidate(pipelineJobsProvider)
        ..invalidate(projectJobsProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _JobMenu extends StatelessWidget {
  const _JobMenu({required this.job, required this.onAction});

  final Job job;
  final ValueChanged<String> onAction;

  /// Terminal statuses where a job has something erasable.
  static const _erasable = {'success', 'failed', 'canceled', 'skipped'};

  @override
  Widget build(BuildContext context) {
    final items = <PopupMenuEntry<String>>[
      if (job.hasArtifacts)
        const PopupMenuItem(
          value: 'artifacts',
          child: Text('Browse artifacts'),
        ),
      if (job.status == 'success' || job.status == 'failed') ...[
        const PopupMenuItem(
          value: 'keep_artifacts',
          child: Text('Keep artifacts'),
        ),
        const PopupMenuItem(
          value: 'delete_artifacts',
          child: Text('Delete artifacts'),
        ),
      ],
      if (_erasable.contains(job.status))
        const PopupMenuItem(value: 'erase', child: Text('Erase job')),
    ];
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return PopupMenuButton<String>(
      onSelected: onAction,
      itemBuilder: (context) => items,
    );
  }
}

class _JobHeader extends StatelessWidget {
  const _JobHeader({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Insets.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Wrap(
        spacing: Insets.lg,
        runSpacing: Insets.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          StateChip.pipeline(job.status),
          if (job.stage != null)
            Text(job.stage!, style: theme.textTheme.bodySmall),
          if (job.duration != null)
            Text(
              Format.duration(job.duration?.toDouble()),
              style: theme.textTheme.bodySmall,
            ),
          if (job.user != null)
            Text('by ${job.user!.name}', style: theme.textTheme.bodySmall),
          if (job.tagList.isNotEmpty)
            Text(
              job.tagList.join(', '),
              style: const TextStyle(
                fontFamily: GlamFonts.mono,
                fontSize: 11.5,
              ),
            ),
        ],
      ),
    );
  }
}

class _TraceView extends ConsumerWidget {
  const _TraceView({required this.loc});

  final JobRef loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trace = ref.watch(jobTraceProvider(loc));
    final colors = context.colors;

    return AsyncValueWidget<String>(
      value: trace,
      onRetry: () => ref.invalidate(jobTraceProvider(loc)),
      loading: const Center(child: CircularProgressIndicator()),
      data: (body) => Stack(
        children: [
          Container(
            color: colors.codeBackground,
            child: SelectionArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Insets.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    body.isEmpty ? '(empty trace)' : body,
                    style: TextStyle(
                      fontFamily: GlamFonts.mono,
                      fontSize: 11.5,
                      height: 1.5,
                      color: colors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: Insets.md,
            bottom: Insets.md,
            child: IconButton.filled(
              tooltip: 'Copy trace',
              icon: const Icon(Icons.copy_outlined, size: 18),
              onPressed: () =>
                  unawaited(Clipboard.setData(ClipboardData(text: body))),
            ),
          ),
        ],
      ),
    );
  }
}
