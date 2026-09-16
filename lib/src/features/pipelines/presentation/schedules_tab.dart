import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/core/widgets/state_chip.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/pipelines/application/pipelines_providers.dart';
import 'package:glam/src/features/pipelines/data/pipelines_repository.dart';
import 'package:glam/src/features/pipelines/domain/pipeline_schedule.dart';
import 'package:glam/src/features/repository/application/repository_providers.dart';

/// Scheduled pipelines for a project — the Schedules half of the
/// Pipelines tab.
class PipelineSchedulesTab extends ConsumerWidget {
  const PipelineSchedulesTab({required this.projectId, super.key});

  final Object projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(pipelineSchedulesProvider(projectId));
    final notifier = ref.read(pipelineSchedulesProvider(projectId).notifier);

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () =>
                unawaited(_ScheduleForm.show(context, projectId: projectId)),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New schedule'),
          ),
        ),
        Expanded(
          child: AsyncValueWidget(
            value: state,
            onRetry: notifier.refresh,
            data: (data) => PagedListView<PipelineSchedule>(
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
                icon: Icons.schedule_outlined,
                title: 'No scheduled pipelines',
              ),
              itemBuilder: (context, index) =>
                  _ScheduleTile(projectId: projectId, s: data.items[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScheduleTile extends ConsumerWidget {
  const _ScheduleTile({required this.projectId, required this.s});

  final Object projectId;
  final PipelineSchedule s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final myId = ref.watch(sessionProvider).value?.user.id;
    final notifier = ref.read(pipelineSchedulesProvider(projectId).notifier);

    return ListTile(
      leading: Icon(
        Icons.schedule,
        size: 20,
        color: s.active ? context.colors.success : context.colors.inkMuted,
      ),
      title: Text(
        s.description.isEmpty ? 'Schedule #${s.id}' : s.description,
        style: theme.textTheme.titleSmall,
      ),
      subtitle: Text(
        [
          '${s.ref} · ${s.cron} ${s.cronTimezone}',
          if (s.nextRunAt != null) 'next ${Format.relative(s.nextRunAt)}',
          if (s.owner != null) s.owner!.name,
        ].join(' · '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (s.lastPipelineStatus != null)
            Padding(
              padding: const EdgeInsets.only(right: Insets.xs),
              child: StateChip.pipeline(s.lastPipelineStatus!),
            ),
          PopupMenuButton<String>(
            onSelected: (action) =>
                unawaited(_action(context, ref, notifier, action, myId)),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'play', child: Text('Run now')),
              if (myId != null && s.owner?.id != myId)
                const PopupMenuItem(
                  value: 'own',
                  child: Text('Take ownership'),
                ),
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _action(
    BuildContext context,
    WidgetRef ref,
    PipelineSchedulesNotifier notifier,
    String action,
    int? myId,
  ) async {
    try {
      switch (action) {
        case 'play':
          await notifier.play(s.id);
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Schedule triggered')));
          }
        case 'own':
          await notifier.takeOwnership(s.id);
        case 'edit':
          final detail = await ref
              .read(pipelinesRepositoryProvider)
              .pipelineSchedule(projectId, s.id);
          if (context.mounted) {
            unawaited(
              _ScheduleForm.show(
                context,
                projectId: projectId,
                schedule: detail,
              ),
            );
          }
        case 'delete':
          final ok = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete schedule?'),
              content: Text(
                '"${s.description.isEmpty ? s.cron : s.description}"'
                ' stops running.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
          if ((ok ?? false) && context.mounted) {
            await notifier.remove(s.id);
          }
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Something went wrong')));
      }
    }
  }
}

class _ScheduleForm extends ConsumerStatefulWidget {
  const _ScheduleForm({required this.projectId, this.schedule});

  final Object projectId;
  final PipelineSchedule? schedule;

  static Future<void> show(
    BuildContext context, {
    required Object projectId,
    PipelineSchedule? schedule,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => _ScheduleForm(projectId: projectId, schedule: schedule),
    );
  }

  @override
  ConsumerState<_ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends ConsumerState<_ScheduleForm> {
  late final TextEditingController _description;
  late final TextEditingController _cron;
  late final TextEditingController _timezone;
  late List<
    ({TextEditingController key, TextEditingController value, String type})
  >
  _vars;
  late final Set<String> _existingKeys;
  String? _ref;
  var _active = true;
  var _saving = false;
  String? _error;

  /// Set once a create succeeds so a retry after a variable failure
  /// updates instead of duplicating the schedule.
  int? _createdId;

  bool get _editing => widget.schedule != null || _createdId != null;

  @override
  void initState() {
    super.initState();
    final s = widget.schedule;
    _description = TextEditingController(text: s?.description ?? '');
    _cron = TextEditingController(text: s?.cron ?? '');
    _timezone = TextEditingController(text: s?.cronTimezone ?? 'UTC');
    _ref = s?.ref;
    _active = s?.active ?? true;
    _existingKeys = {
      for (final v in s?.variables ?? <ScheduleVariable>[]) v.key,
    };
    _vars = [
      for (final v in s?.variables ?? <ScheduleVariable>[])
        (
          key: TextEditingController(text: v.key),
          value: TextEditingController(text: v.value),
          type: v.variableType,
        ),
    ];
  }

  @override
  void dispose() {
    _description.dispose();
    _cron.dispose();
    _timezone.dispose();
    for (final v in _vars) {
      v.key.dispose();
      v.value.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final cron = _cron.text.trim();
    final keys = _vars
        .map((v) => v.key.text.trim())
        .where((k) => k.isNotEmpty)
        .toList();
    if (_ref == null ||
        _ref!.isEmpty ||
        cron.isEmpty ||
        _description.text.trim().isEmpty ||
        keys.length != keys.toSet().length ||
        _saving) {
      setState(
        () => _error = _ref == null || _ref!.isEmpty
            ? 'Pick a target ref'
            : _description.text.trim().isEmpty
            ? 'A description is required'
            : cron.isEmpty
            ? 'A cron expression is required'
            : 'Variable keys must be unique',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(pipelinesRepositoryProvider);
    try {
      final id = await _saveSchedule(repo);
      await _saveVariables(repo, id);
      ref.invalidate(pipelineSchedulesProvider(widget.projectId));
      if (mounted) {
        context.pop();
      }
    } on ApiException catch (e) {
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } on Object {
      setState(() {
        _saving = false;
        _error = 'Could not save the schedule';
      });
    }
  }

  Future<int> _saveSchedule(PipelinesRepository repo) async {
    if (_editing) {
      final s = await repo.updateSchedule(
        widget.projectId,
        widget.schedule?.id ?? _createdId!,
        description: _description.text.trim(),
        ref: _ref,
        cron: _cron.text.trim(),
        cronTimezone: _timezone.text.trim(),
        active: _active,
      );
      return s.id;
    }
    final s = await repo.createSchedule(
      widget.projectId,
      description: _description.text.trim(),
      ref: _ref!,
      cron: _cron.text.trim(),
      cronTimezone: _timezone.text.trim(),
      active: _active,
    );
    _createdId = s.id;
    return s.id;
  }

  Future<void> _saveVariables(PipelinesRepository repo, int id) async {
    final kept = <String>{};
    for (final v in _vars) {
      final key = v.key.text.trim();
      if (key.isEmpty) {
        continue;
      }
      kept.add(key);
      if (_existingKeys.contains(key)) {
        await repo.updateScheduleVariable(
          widget.projectId,
          id,
          key,
          value: v.value.text,
          variableType: v.type,
        );
      } else {
        await repo.createScheduleVariable(
          widget.projectId,
          id,
          key: key,
          value: v.value.text,
          variableType: v.type,
        );
      }
    }
    for (final removed in _existingKeys.difference(kept)) {
      await repo.deleteScheduleVariable(widget.projectId, id, removed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final branches = ref.watch(branchesProvider(widget.projectId));
    final branchNames = branches.value?.items.map((b) => b.name).toList();

    return AlertDialog(
      title: Text(_editing ? 'Edit schedule' : 'New schedule'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _description,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Insets.md),
              DropdownButtonFormField<String>(
                initialValue: _ref,
                decoration: const InputDecoration(
                  labelText: 'Target ref',
                  border: OutlineInputBorder(),
                ),
                items: [
                  // The current ref may be a tag or past the first
                  // branches page; keep it selectable either way.
                  if (_ref != null &&
                      !(branchNames ?? const <String>[]).contains(_ref))
                    DropdownMenuItem(
                      value: _ref,
                      child: Text(
                        _ref!,
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  for (final b in branchNames ?? <String>[])
                    DropdownMenuItem(
                      value: b,
                      child: Text(
                        b,
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _ref = v),
              ),
              const SizedBox(height: Insets.md),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _cron,
                      decoration: const InputDecoration(
                        labelText: 'Cron',
                        hintText: '0 2 * * *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: Insets.md),
                  Expanded(
                    child: TextField(
                      controller: _timezone,
                      decoration: const InputDecoration(
                        labelText: 'Timezone',
                        hintText: 'UTC',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
              Row(
                children: [
                  Text('Variables', style: theme.textTheme.labelLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: () => setState(
                      () => _vars.add((
                        key: TextEditingController(),
                        value: TextEditingController(),
                        type: 'env_var',
                      )),
                    ),
                  ),
                ],
              ),
              for (var i = 0; i < _vars.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: Insets.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _vars[i].key,
                          decoration: const InputDecoration(
                            hintText: 'KEY',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: Insets.sm),
                      Expanded(
                        child: TextField(
                          controller: _vars[i].value,
                          decoration: const InputDecoration(
                            hintText: 'value',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => setState(() {
                          _vars[i].key.dispose();
                          _vars[i].value.dispose();
                          _vars.removeAt(i);
                        }),
                      ),
                    ],
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: Insets.sm),
                  child: Text(_error!, style: TextStyle(color: colors.danger)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => context.pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_editing ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
