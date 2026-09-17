import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/core/widgets/state_chip.dart';
import 'package:glam/src/features/pipelines/application/pipelines_providers.dart';
import 'package:glam/src/features/pipelines/domain/pipeline.dart';
import 'package:glam/src/features/pipelines/presentation/schedules_tab.dart';

/// Pipeline history + schedules for a project — the CI/CD tab.
class PipelinesScreen extends ConsumerStatefulWidget {
  const PipelinesScreen({required this.projectId, super.key});

  final Object projectId;

  @override
  ConsumerState<PipelinesScreen> createState() => _PipelinesScreenState();
}

enum _CicdTab { runs, jobs, schedules }

class _PipelinesScreenState extends ConsumerState<PipelinesScreen> {
  var _tab = _CicdTab.runs;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Insets.lg,
            Insets.sm,
            Insets.lg,
            0,
          ),
          child: SegmentedButton<_CicdTab>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: _CicdTab.runs, label: Text('Runs')),
              ButtonSegment(value: _CicdTab.jobs, label: Text('Jobs')),
              ButtonSegment(
                value: _CicdTab.schedules,
                label: Text('Schedules'),
              ),
            ],
            selected: {_tab},
            onSelectionChanged: (s) => setState(() => _tab = s.first),
          ),
        ),
        Expanded(
          child: switch (_tab) {
            _CicdTab.runs => _PipelineRuns(projectId: widget.projectId),
            _CicdTab.jobs => _ProjectJobs(projectId: widget.projectId),
            _CicdTab.schedules => PipelineSchedulesTab(
              projectId: widget.projectId,
            ),
          },
        ),
      ],
    );
  }
}

class _PipelineRuns extends ConsumerWidget {
  const _PipelineRuns({required this.projectId});

  final Object projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(pipelinesProvider(projectId));
    final notifier = ref.read(pipelinesProvider(projectId).notifier);

    return AsyncValueWidget(
      value: state,
      onRetry: notifier.refresh,
      data: (data) => PagedListView(
        state: data,
        onLoadMore: notifier.loadMore,
        onRefresh: notifier.refresh,
        padding: const EdgeInsets.symmetric(vertical: Insets.sm),
        separator: Divider(height: 1, color: colors.border, indent: Insets.lg),
        empty: const EmptyState(
          icon: Icons.rocket_launch_outlined,
          title: 'No pipelines yet',
        ),
        itemBuilder: (context, index) =>
            PipelineTile(pipeline: data.items[index], projectId: projectId),
      ),
    );
  }
}

/// Every job in the project, with an optional status filter.
class _ProjectJobs extends ConsumerStatefulWidget {
  const _ProjectJobs({required this.projectId});

  final Object projectId;

  @override
  ConsumerState<_ProjectJobs> createState() => _ProjectJobsState();
}

class _ProjectJobsState extends ConsumerState<_ProjectJobs> {
  String? _scope;

  static const _scopes = [
    (null, 'All'),
    ('running', 'Running'),
    ('pending', 'Pending'),
    ('success', 'Passed'),
    ('failed', 'Failed'),
    ('manual', 'Manual'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final loc = (project: widget.projectId, scope: _scope);
    final state = ref.watch(projectJobsProvider(loc));
    final notifier = ref.read(projectJobsProvider(loc).notifier);

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: PopupMenuButton<String?>(
            tooltip: 'Filter jobs',
            onSelected: (v) => setState(() => _scope = v),
            itemBuilder: (context) => [
              for (final (value, label) in _scopes)
                CheckedPopupMenuItem(
                  value: value,
                  checked: _scope == value,
                  child: Text(label),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Insets.lg,
                vertical: Insets.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    [
                      for (final (v, label) in _scopes)
                        if (v == _scope) label,
                    ].first,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Icon(Icons.arrow_drop_down, color: colors.inkMuted),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: AsyncValueWidget(
            value: state,
            onRetry: notifier.refresh,
            data: (data) => PagedListView(
              state: data,
              onLoadMore: notifier.loadMore,
              onRefresh: notifier.refresh,
              padding: const EdgeInsets.only(bottom: Insets.sm),
              separator: Divider(
                height: 1,
                color: colors.border,
                indent: Insets.lg,
              ),
              empty: const EmptyState(
                icon: Icons.construction_outlined,
                title: 'No jobs',
              ),
              itemBuilder: (context, index) =>
                  _JobTile(job: data.items[index], projectId: widget.projectId),
            ),
          ),
        ),
      ],
    );
  }
}

class _JobTile extends StatelessWidget {
  const _JobTile({required this.job, required this.projectId});

  final Job job;
  final Object projectId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      leading: StateChip.pipeline(job.status),
      title: Text(job.name, style: theme.textTheme.titleSmall),
      subtitle: Text(
        [
          '#${job.id}',
          ?job.stage,
          ?job.ref,
          if (job.user != null) 'by ${job.user!.name}',
        ].join(' · '),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: job.duration == null
          ? null
          : Text(
              Format.duration(job.duration?.toDouble()),
              style: theme.textTheme.labelSmall,
            ),
      onTap: () =>
          unawaited(context.push(Routes.projectJob(projectId, job.id))),
    );
  }
}

/// One pipeline row: status, #id, ref@sha, duration, user.
class PipelineTile extends StatelessWidget {
  const PipelineTile({
    required this.pipeline,
    required this.projectId,
    super.key,
  });

  final Pipeline pipeline;
  final Object projectId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => unawaited(
        context.push(Routes.projectPipeline(projectId, pipeline.id)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.lg,
          vertical: Insets.md,
        ),
        child: Row(
          children: [
            StateChip.pipeline(pipeline.status),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '#${pipeline.iid ?? pipeline.id}',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(width: Insets.sm),
                      Flexible(
                        child: Text(
                          pipeline.ref ?? '',
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Insets.xs),
                  Text(
                    '${pipeline.user?.name ?? 'system'}'
                    ' · ${Format.relative(pipeline.createdAt)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  pipeline.sha == null
                      ? ''
                      : pipeline.sha!.length > 8
                      ? pipeline.sha!.substring(0, 8)
                      : pipeline.sha!,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11.5,
                  ),
                ),
                if (pipeline.duration != null)
                  Text(
                    Format.duration(pipeline.duration?.toDouble()),
                    style: theme.textTheme.labelSmall,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
