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
import 'package:glam/src/features/pipelines/domain/bridge.dart';
import 'package:glam/src/features/pipelines/domain/pipeline.dart';
import 'package:glam/src/features/pipelines/domain/pipeline_schedule.dart';
import 'package:glam/src/app/theme/app_typography.dart';
import 'package:glam/src/core/utils/l10n.dart';

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

enum _PipelineView { stages, tests, variables, downstream }

class _PipelineDetailScreenState extends ConsumerState<PipelineDetailScreen> {
  _PipelineView _view = _PipelineView.stages;
  bool _retried = false;

  PipelineRef get _loc => (project: widget.projectId, id: widget.pipelineId);

  @override
  Widget build(BuildContext context) {
    final pipeline = ref.watch(pipelineProvider(_loc));
    final jobsFilter = (
      project: widget.projectId,
      id: widget.pipelineId,
      retried: _retried,
    );
    final jobs = ref.watch(pipelineJobsProvider(jobsFilter));
    final report = ref.watch(pipelineTestReportProvider(_loc));
    final variables = ref.watch(pipelineVariablesProvider(_loc));
    final bridges = ref.watch(pipelineBridgesProvider(_loc));
    final hasReport = !(report.value?.isEmpty ?? true);
    final hasVariables = variables.value?.isNotEmpty ?? false;
    final hasBridges = bridges.value?.isNotEmpty ?? false;
    final view = switch (_view) {
      _PipelineView.tests when !hasReport => _PipelineView.stages,
      _PipelineView.variables when !hasVariables => _PipelineView.stages,
      _PipelineView.downstream when !hasBridges => _PipelineView.stages,
      _ => _view,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.pipelineP0(widget.pipelineId)),
        actions: [
          pipeline.maybeWhen(
            data: (p) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (p.isRunning)
                  IconButton(
                    tooltip: context.l10n.actionCancel,
                    icon: const Icon(Icons.stop_circle_outlined),
                    onPressed: () => unawaited(_cancel(context, ref)),
                  )
                else if (p.status != 'success')
                  IconButton(
                    tooltip: context.l10n.actionRetry,
                    icon: const Icon(Icons.refresh),
                    onPressed: () => unawaited(_retry(context, ref)),
                  ),
                if (p.webUrl != null)
                  IconButton(
                    tooltip: context.l10n.actionOpenBrowser,
                    icon: const Icon(Icons.open_in_new, size: 20),
                    onPressed: () => unawaited(launchExternal(p.webUrl!)),
                  ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            tooltip: _retried
                ? context.l10n.hideRetriedJobs
                : context.l10n.showRetriedJobs,
            isSelected: _retried,
            icon: const Icon(Icons.replay, size: 20),
            onPressed: () => setState(() => _retried = !_retried),
          ),
        ],
      ),
      body: AsyncValueWidget<Pipeline>(
        value: pipeline,
        onRetry: () => ref.invalidate(pipelineProvider(_loc)),
        data: (p) => Column(
          children: [
            _PipelineHeader(pipeline: p),
            if (hasReport || hasVariables || hasBridges)
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
                    segments: [
                      ButtonSegment(
                        value: _PipelineView.stages,
                        label: Text(context.l10n.stages),
                        icon: Icon(Icons.view_list_outlined, size: 16),
                      ),
                      if (hasReport)
                        ButtonSegment(
                          value: _PipelineView.tests,
                          label: Text(context.l10n.tests),
                          icon: Icon(Icons.science_outlined, size: 16),
                        ),
                      if (hasVariables)
                        ButtonSegment(
                          value: _PipelineView.variables,
                          label: Text(context.l10n.variables),
                          icon: Icon(Icons.tune, size: 16),
                        ),
                      if (hasBridges)
                        ButtonSegment(
                          value: _PipelineView.downstream,
                          label: Text(context.l10n.downstream),
                          icon: Icon(Icons.account_tree_outlined, size: 16),
                        ),
                    ],
                    selected: {view},
                    onSelectionChanged: (s) => setState(() => _view = s.first),
                  ),
                ),
              ),
            Expanded(
              child: view == _PipelineView.tests
                  ? _TestReportView(loc: _loc)
                  : view == _PipelineView.variables
                  ? _VariablesView(loc: _loc)
                  : view == _PipelineView.downstream
                  ? _DownstreamView(loc: _loc, projectId: widget.projectId)
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
        ..invalidate(
          pipelineJobsProvider((
            project: widget.projectId,
            id: widget.pipelineId,
            retried: _retried,
          )),
        );
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
            context.l10n.refAtSha(
              pipeline.ref ?? '',
              pipeline.sha == null
                  ? ''
                  : pipeline.sha!.length > 8
                  ? pipeline.sha!.substring(0, 8)
                  : pipeline.sha!,
            ),
            style: const TextStyle(fontFamily: GlamFonts.mono, fontSize: 12.5),
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
      return EmptyState(
        icon: Icons.work_outline,
        title: context.l10n.noJobsInThisPipeline,
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
                        context.l10n.allowedToFail,
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
      'manual' => (Icons.play_arrow, 'play', context.l10n.runManualJob),
      'running' ||
      'pending' => (Icons.stop, 'cancel', context.l10n.actionCancel),
      'failed' ||
      'canceled' ||
      'skipped' => (Icons.refresh, 'retry', context.l10n.actionRetry),
      _ => (Icons.refresh, 'retry', context.l10n.actionRetry),
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
          return EmptyState(
            icon: Icons.science_outlined,
            title: context.l10n.noTestReport,
          );
        }
        final coverage = ref.watch(pipelineCoverageProvider(loc)).value;
        return ListView(
          padding: Insets.pagePadding,
          children: [
            Wrap(
              spacing: Insets.md,
              runSpacing: Insets.xs,
              children: [
                _Count(label: context.l10n.total, value: r.totalCount),
                _Count(
                  label: context.l10n.pipelineStatusSuccess,
                  value: r.successCount,
                ),
                _Count(
                  label: context.l10n.pipelineStatusFailed,
                  value: r.failedCount,
                  color: colors.danger,
                ),
                _Count(
                  label: context.l10n.pipelineStatusSkipped,
                  value: r.skippedCount,
                ),
                _Count(
                  label: context.l10n.errors,
                  value: r.errorCount,
                  color: colors.warning,
                ),
                if (coverage != null)
                  _Count(
                    label: context.l10n.coverage,
                    value: coverage.round(),
                    suffix: '%',
                  ),
                Text(
                  context.l10n.durationInSecs(r.totalTime.toStringAsFixed(1)),
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
                        _Count(
                          label: context.l10n.total,
                          value: suite.totalCount,
                        ),
                        _Count(
                          label: context.l10n.pipelineStatusSuccess,
                          value: suite.successCount,
                        ),
                        _Count(
                          label: context.l10n.pipelineStatusFailed,
                          value: suite.failedCount,
                          color: colors.danger,
                        ),
                        _Count(
                          label: context.l10n.pipelineStatusSkipped,
                          value: suite.skippedCount,
                        ),
                        _Count(
                          label: context.l10n.errors,
                          value: suite.errorCount,
                          color: colors.warning,
                        ),
                        Text(
                          context.l10n.secsValue(
                            suite.totalTime.toStringAsFixed(1),
                          ),
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

/// Key/value rows for the variables a pipeline ran with.
class _VariablesView extends ConsumerWidget {
  const _VariablesView({required this.loc});

  final PipelineRef loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variables = ref.watch(pipelineVariablesProvider(loc));
    final theme = Theme.of(context);
    final colors = context.colors;

    return AsyncValueWidget<List<ScheduleVariable>>(
      value: variables,
      onRetry: () => ref.invalidate(pipelineVariablesProvider(loc)),
      data: (items) => items.isEmpty
          ? EmptyState(
              icon: Icons.tune,
              title: context.l10n.varsEmpty,
              message: context.l10n.thisPipelineRanWithoutExtraVariables,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(Insets.lg),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final v = items[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: Insets.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.key,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontFamily: 'monospace',
                              ),
                            ),
                            if (v.value.isNotEmpty)
                              Text(
                                v.value,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.inkFaint,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      if (v.variableType != 'env_var')
                        Text(v.variableType, style: theme.textTheme.labelSmall),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

/// Bridge jobs and the downstream pipelines they triggered.
class _DownstreamView extends ConsumerWidget {
  const _DownstreamView({required this.loc, required this.projectId});

  final PipelineRef loc;
  final Object projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bridges = ref.watch(pipelineBridgesProvider(loc));
    final theme = Theme.of(context);
    final colors = context.colors;

    return AsyncValueWidget<List<Bridge>>(
      value: bridges,
      onRetry: () => ref.invalidate(pipelineBridgesProvider(loc)),
      data: (items) => items.isEmpty
          ? EmptyState(
              icon: Icons.account_tree_outlined,
              title: context.l10n.noDownstreamPipelines,
              message: context.l10n.thisPipelineDidNotTriggerAny,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(Insets.lg),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final b = items[i];
                final d = b.downstream;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: StateChip.pipeline(b.status),
                  title: Text(b.name, style: theme.textTheme.titleSmall),
                  subtitle: d == null
                      ? Text(
                          b.stage ?? 'not triggered',
                          style: theme.textTheme.bodySmall,
                        )
                      : Text(
                          [
                            'pipeline #${d.id}',
                            ?d.projectName,
                            ?d.ref,
                          ].join(' · '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.inkMuted,
                          ),
                        ),
                  trailing: d == null ? null : StateChip.pipeline(d.status),
                  onTap: d == null
                      ? null
                      : () => context.push(
                          Routes.projectPipeline(
                            d.projectId ?? projectId,
                            d.id,
                          ),
                        ),
                );
              },
            ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({
    required this.label,
    required this.value,
    this.color,
    this.suffix = '',
  });

  final String label;
  final int value;
  final Color? color;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      context.l10n.statText(label, value, suffix),
      style: theme.textTheme.bodySmall?.copyWith(color: color),
    );
  }
}
