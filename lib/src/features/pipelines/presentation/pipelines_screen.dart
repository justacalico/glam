import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/filter_menu.dart';
import 'package:glam/src/features/groups/application/groups_providers.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/core/widgets/state_chip.dart';
import 'package:glam/src/features/pipelines/application/pipelines_providers.dart';
import 'package:glam/src/features/pipelines/domain/pipeline.dart';
import 'package:glam/src/features/pipelines/domain/pipeline_trigger.dart';
import 'package:glam/src/features/repository/application/repository_providers.dart';
import 'package:glam/src/features/pipelines/presentation/schedules_tab.dart';
import 'package:glam/src/app/theme/app_typography.dart';

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
          child: Row(
            children: [
              Expanded(
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
              TextButton.icon(
                icon: const Icon(Icons.checklist_outlined, size: 16),
                label: const Text('Lint'),
                onPressed: () =>
                    CiLintSheet.show(context, projectId: widget.projectId),
              ),
            ],
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

class _PipelineRuns extends ConsumerStatefulWidget {
  const _PipelineRuns({required this.projectId});

  final Object projectId;

  @override
  ConsumerState<_PipelineRuns> createState() => _PipelineRunsState();
}

class _PipelineRunsState extends ConsumerState<_PipelineRuns> {
  String? _status;
  String? _source;
  String? _ref;
  String? _username;

  static const _statusValues = [
    'running',
    'pending',
    'success',
    'failed',
    'canceled',
    'skipped',
    'manual',
  ];
  static const _statusLabels = {
    'running': 'Running',
    'pending': 'Pending',
    'success': 'Passed',
    'failed': 'Failed',
    'canceled': 'Canceled',
    'skipped': 'Skipped',
    'manual': 'Manual',
  };

  static const _sourceValues = [
    'push',
    'web',
    'schedule',
    'api',
    'trigger',
    'merge_request_event',
    'pipeline',
    'chat',
  ];
  static const _sourceLabels = {
    'push': 'Push',
    'web': 'Web',
    'schedule': 'Schedule',
    'api': 'API',
    'trigger': 'Trigger',
    'merge_request_event': 'Merge request',
    'pipeline': 'Pipeline',
    'chat': 'Chat',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final branches =
        ref
            .watch(branchesProvider((project: widget.projectId, search: null)))
            .value
            ?.items ??
        const [];
    final members =
        ref
            .watch(
              membersProvider((
                id: widget.projectId,
                isProject: true,
                query: null,
              )),
            )
            .value
            ?.items ??
        const [];
    final filter = (
      project: widget.projectId,
      status: _status,
      source: _source,
      ref: _ref,
      username: _username,
    );
    final state = ref.watch(pipelinesProvider(filter));
    final notifier = ref.read(pipelinesProvider(filter).notifier);

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: Insets.lg),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilterMenu(
                    title: 'Source',
                    current: _source,
                    options: _sourceValues,
                    labels: _sourceLabels,
                    onSelect: (v) => setState(() => _source = v),
                  ),
                  FilterMenu(
                    title: 'Ref',
                    current: _ref,
                    options: [for (final b in branches) b.name],
                    onSelect: (v) => setState(() => _ref = v),
                  ),
                  FilterMenu(
                    title: 'User',
                    current: _username,
                    options: [for (final m in members) m.username],
                    onSelect: (v) => setState(() => _username = v),
                  ),
                  FilterMenu(
                    title: 'Status',
                    current: _status,
                    options: _statusValues,
                    labels: _statusLabels,
                    onSelect: (v) => setState(() => _status = v),
                  ),
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
              padding: const EdgeInsets.symmetric(vertical: Insets.sm),
              separator: Divider(
                height: 1,
                color: colors.border,
                indent: Insets.lg,
              ),
              empty: const EmptyState(
                icon: Icons.rocket_launch_outlined,
                title: 'No pipelines yet',
              ),
              itemBuilder: (context, index) => PipelineTile(
                pipeline: data.items[index],
                projectId: widget.projectId,
              ),
            ),
          ),
        ),
      ],
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

  static const _scopeValues = [
    'running',
    'pending',
    'success',
    'failed',
    'canceled',
    'skipped',
    'manual',
  ];
  static const _scopeLabels = {
    'running': 'Running',
    'pending': 'Pending',
    'success': 'Passed',
    'failed': 'Failed',
    'canceled': 'Canceled',
    'skipped': 'Skipped',
    'manual': 'Manual',
  };

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
          child: Padding(
            padding: const EdgeInsets.only(right: Insets.lg),
            child: FilterMenu(
              title: 'Scope',
              current: _scope,
              options: _scopeValues,
              labels: _scopeLabels,
              onSelect: (v) => setState(() => _scope = v),
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
                            fontFamily: GlamFonts.mono,
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
                    fontFamily: GlamFonts.mono,
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

/// `.gitlab-ci.yml` validation against `POST /projects/:id/ci/lint`.
/// Prefills from the repo's `.gitlab-ci.yml` when it exists.
class CiLintSheet extends ConsumerStatefulWidget {
  const CiLintSheet({required this.projectId, super.key});

  final Object projectId;

  static Future<void> show(BuildContext context, {required Object projectId}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => CiLintSheet(projectId: projectId),
    );
  }

  @override
  ConsumerState<CiLintSheet> createState() => _CiLintSheetState();
}

class _CiLintSheetState extends ConsumerState<CiLintSheet> {
  final _content = TextEditingController();
  bool _loading = false;
  CiLintResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_prefill());
  }

  Future<void> _prefill() async {
    try {
      final yaml = await ref
          .read(repositoryRepositoryProvider)
          .rawFile(widget.projectId, '.gitlab-ci.yml');
      if (mounted && _content.text.isEmpty) {
        _content.text = yaml;
      }
    } on ApiException {
      // No .gitlab-ci.yml (or no access) — the field stays empty.
    }
  }

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  Future<void> _lint() async {
    if (_content.text.trim().isEmpty) {
      return;
    }
    setState(() {
      _loading = true;
      _result = null;
      _error = null;
    });
    try {
      final result = await ref
          .read(pipelinesRepositoryProvider)
          .ciLint(widget.projectId, _content.text);
      if (mounted) {
        setState(() => _result = result);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Insets.lg,
          0,
          Insets.lg,
          Insets.lg + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CI lint', style: theme.textTheme.titleMedium),
            const SizedBox(height: Insets.sm),
            TextField(
              controller: _content,
              maxLines: 8,
              style: const TextStyle(fontFamily: GlamFonts.mono, fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'stages:\n  - build',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: Insets.sm),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _loading ? null : _lint,
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(_loading ? 'Checking…' : 'Validate'),
                ),
                const SizedBox(width: Insets.md),
                if (_result != null)
                  StateChip(
                    label: _result!.valid ? 'valid' : 'invalid',
                    tone: _result!.valid ? ChipTone.success : ChipTone.danger,
                  ),
                if (_result != null && _result!.jobs.isNotEmpty) ...[
                  const SizedBox(width: Insets.sm),
                  Text(
                    '${_result!.jobs.length} jobs',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: Insets.sm),
              Text(_error!, style: TextStyle(color: colors.danger)),
            ],
            if (_result != null) ...[
              for (final e in _result!.errors)
                Padding(
                  padding: const EdgeInsets.only(top: Insets.xs),
                  child: Text(
                    e,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.danger,
                    ),
                  ),
                ),
              for (final w in _result!.warnings)
                Padding(
                  padding: const EdgeInsets.only(top: Insets.xs),
                  child: Text(w, style: theme.textTheme.bodySmall),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
