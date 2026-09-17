import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/utils/url_launcher.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/error_view.dart';
import 'package:glam/src/core/widgets/state_chip.dart';
import 'package:glam/src/features/pipelines/application/pipelines_providers.dart';
import 'package:glam/src/features/pipelines/domain/pipeline.dart';

/// Pipeline detail: meta header plus jobs grouped by stage, with
/// retry/cancel actions. A Tests view appears when the pipeline
/// published a test report.
class PipelineDetailScreen extends ConsumerStatefulWidget {
  const PipelineDetailScreen({
    required this.projectId,
    required this.pipelineId,
    super.key,
  });

  final Object projectId;
  final int pipelineId;

  @override
  ConsumerState<PipelineDetailScreen> createState() =>
      _PipelineDetailScreenState();
}

enum _PipelineView { stages, tests }

class _PipelineDetailScreenState extends ConsumerState<PipelineDetailScreen> {
  _PipelineView _view = _PipelineView.stages;

  PipelineRef get _loc => (project: widget.projectId, id: widget.pipelineId);

  @override
  Widget build(BuildContext context) {
    final pipeline = ref.watch(pipelineProvider(_loc));
    final jobs = ref.watch(pipelineJobsProvider(_loc));
    final report = ref.watch(pipelineTestReportProvider(_loc));
    final hasReport = !(report.value?.isEmpty ?? true);

    return Scaffold(
      appBar: AppBar(
        title: Text('Pipeline #${widget.pipelineId}'),
        actions: [
          pipeline.maybeWhen(
            data: (p) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (p.isRunning)
                  IconButton(
                    tooltip: 'Cancel',
                    icon: const Icon(Icons.stop_circle_outlined),
                    onPressed: () => unawaited(_cancel(context, ref)),
                  )
                else if (p.status != 'success')
                  IconButton(
                    tooltip: 'Retry',
                    icon: const Icon(Icons.refresh),
                    onPressed: () => unawaited(_retry(context, ref)),
                  ),
                if (p.webUrl != null)
                  IconButton(
                    tooltip: 'Open in browser',
                    icon: const Icon(Icons.open_in_new, size: 20),
                    onPressed: () => unawaited(launchExternal(p.webUrl!)),
                  ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: AsyncValueWidget<Pipeline>(
        value: pipeline,
        onRetry: () => ref.invalidate(pipelineProvider(_loc)),
        data: (p) => Column(
          children: [
            _PipelineHeader(pipeline: p),
            if (hasReport)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.lg,
                  Insets.sm,
                  Insets.lg,
                  Insets.xs,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<_PipelineView>(
                    segments: const [
                      ButtonSegment(
                        value: _PipelineView.stages,
                        label: Text('Stages'),
                        icon: Icon(Icons.view_list_outlined, size: 16),
                      ),
                      ButtonSegment(
                        value: _PipelineView.tests,
                        label: Text('Tests'),
                        icon: Icon(Icons.science_outlined, size: 16),
                      ),
                    ],
                    selected: {_view},
                    onSelectionChanged: (s) => setState(() => _view = s.first),
                  ),
                ),
              ),
            Expanded(
              child: _view == _PipelineView.tests && hasReport
                  ? _TestReportView(loc: _loc)
                  : jobs.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => ErrorView(error: e),
                      data: (state) => _StageList(
                        jobs: state.items,
                        projectId: widget.projectId,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _retry(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(pipelinesRepositoryProvider)
          .retryPipeline(widget.projectId, widget.pipelineId);
      ref
        ..invalidate(pipelineProvider(_loc))
        ..invalidate(pipelineJobsProvider(_loc));
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(pipelinesRepositoryProvider)
          .cancelPipeline(widget.projectId, widget.pipelineId);
      ref.invalidate(pipelineProvider(_loc));
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _PipelineHeader extends StatelessWidget {
  const _PipelineHeader({required this.pipeline});

  final Pipeline pipeline;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Insets.sm,
            runSpacing: Insets.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StateChip.pipeline(pipeline.status),
              if (pipeline.source != null)
                Text(
                  pipeline.source!.replaceAll('_', ' '),
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          Text(
            '${pipeline.ref ?? ''} @ '
            '${pipeline.sha == null
                ? ''
                : pipeline.sha!.length > 8
                ? pipeline.sha!.substring(0, 8)
                : pipeline.sha!}',
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: Insets.xs),
          Text(
            [
              if (pipeline.user != null) pipeline.user!.name,
              Format.relative(pipeline.createdAt),
              if (pipeline.duration != null)
                'ran ${Format.duration(pipeline.duration?.toDouble())}',
            ].where((s) => s.isNotEmpty).join(' · '),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _StageList extends StatelessWidget {
  const _StageList({required this.jobs, required this.projectId});

  final List<Job> jobs;
  final Object projectId;

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return const EmptyState(
        icon: Icons.work_outline,
        title: 'No jobs in this pipeline',
      );
    }
    // Keep stage order stable: first appearance wins.
    final stages = <String, List<Job>>{};
    for (final job in jobs) {
      stages.putIfAbsent(job.stage ?? 'other', () => []).add(job);
    }
    return ListView(
      padding: Insets.pagePadding,
      children: [
        for (final stage in stages.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: Insets.md, bottom: Insets.sm),
            child: Text(
              stage.key.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                letterSpacing: 0.8,
                color: context.colors.inkMuted,
              ),
            ),
          ),
          for (final job in stage.value)
            _JobTile(job: job, projectId: projectId),
        ],
      ],
    );
  }
}

class _JobTile extends ConsumerWidget {
  const _JobTile({required this.job, required this.projectId});

  final Job job;
  final Object projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: Insets.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Radii.borderMd,
        border: Border.all(color: colors.border),
      ),
      child: InkWell(
        onTap: () =>
            unawaited(context.push(Routes.projectJob(projectId, job.id))),
        borderRadius: Radii.borderMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.md,
            vertical: Insets.sm + 2,
          ),
          child: Row(
            children: [
              StateChip.pipeline(job.status),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.name, style: theme.textTheme.titleSmall),
                    if (job.allowFailure)
                      Text(
                        'allowed to fail',
                        style: theme.textTheme.labelSmall,
                      ),
                  ],
                ),
              ),
              if (job.duration != null)
                Text(
                  Format.duration(job.duration?.toDouble()),
                  style: theme.textTheme.labelSmall,
                ),
              _JobAction(job: job, projectId: projectId),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobAction extends ConsumerWidget {
  const _JobAction({required this.job, required this.projectId});

  final Job job;
  final Object projectId;

  Future<void> _run(WidgetRef ref, String action) {
    final repo = ref.read(pipelinesRepositoryProvider);
    return switch (action) {
      'play' => repo.playJob(projectId, job.id),
      'cancel' => repo.cancelJob(projectId, job.id),
      _ => repo.retryJob(projectId, job.id),
    }.then((_) {
      ref.invalidate(pipelineJobsProvider);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (icon, action, tip) = switch (job.status) {
      'manual' => (Icons.play_arrow, 'play', 'Run manual job'),
      'running' || 'pending' => (Icons.stop, 'cancel', 'Cancel'),
      'failed' || 'canceled' || 'skipped' => (Icons.refresh, 'retry', 'Retry'),
      _ => (Icons.refresh, 'retry', 'Retry'),
    };
    if (job.status == 'success') {
      return const SizedBox.shrink();
    }
    return IconButton(
      tooltip: tip,
      icon: Icon(icon, size: 18),
      onPressed: () => unawaited(_run(ref, action)),
    );
  }
}

/// The pipeline's aggregated test report: totals plus one card per
/// suite. REST only exposes suite-level counts.
class _TestReportView extends ConsumerWidget {
  const _TestReportView({required this.loc});

  final PipelineRef loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(pipelineTestReportProvider(loc));
    final theme = Theme.of(context);
    final colors = context.colors;

    return report.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(error: e),
      data: (r) {
        if (r.suites.isEmpty) {
          return const EmptyState(
            icon: Icons.science_outlined,
            title: 'No test report',
          );
        }
        return ListView(
          padding: Insets.pagePadding,
          children: [
            Wrap(
              spacing: Insets.md,
              runSpacing: Insets.xs,
              children: [
                _Count(label: 'Total', value: r.totalCount),
                _Count(label: 'Passed', value: r.successCount),
                _Count(
                  label: 'Failed',
                  value: r.failedCount,
                  color: colors.danger,
                ),
                _Count(label: 'Skipped', value: r.skippedCount),
                _Count(
                  label: 'Errors',
                  value: r.errorCount,
                  color: colors.warning,
                ),
                Text(
                  'in ${r.totalTime.toStringAsFixed(1)}s',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: Insets.lg),
            for (final suite in r.suites) ...[
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: Radii.borderMd,
                  border: Border.all(color: colors.border),
                ),
                padding: const EdgeInsets.all(Insets.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(suite.name, style: theme.textTheme.titleSmall),
                    const SizedBox(height: Insets.sm),
                    Wrap(
                      spacing: Insets.md,
                      runSpacing: Insets.xs,
                      children: [
                        _Count(label: 'Total', value: suite.totalCount),
                        _Count(label: 'Passed', value: suite.successCount),
                        _Count(
                          label: 'Failed',
                          value: suite.failedCount,
                          color: colors.danger,
                        ),
                        _Count(label: 'Skipped', value: suite.skippedCount),
                        _Count(
                          label: 'Errors',
                          value: suite.errorCount,
                          color: colors.warning,
                        ),
                        Text(
                          '${suite.totalTime.toStringAsFixed(1)}s',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    if (suite.suiteError != null) ...[
                      const SizedBox(height: Insets.sm),
                      Text(
                        suite.suiteError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.danger,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: Insets.md),
            ],
          ],
        );
      },
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.label, required this.value, this.color});

  final String label;
  final int value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      '$label $value',
      style: theme.textTheme.bodySmall?.copyWith(color: color),
    );
  }
}
