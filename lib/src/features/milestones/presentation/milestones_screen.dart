import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/models/milestone.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/markdown_viewer.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/core/widgets/search_field.dart';
import 'package:glam/src/features/issues/presentation/issue_tile.dart';
import 'package:glam/src/features/merge_requests/presentation/mr_tile.dart';
import 'package:glam/src/features/milestones/application/planning_providers.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// Milestones tab inside project (or group) detail.
class MilestonesTab extends ConsumerStatefulWidget {
  const MilestonesTab({required this.scope, super.key});

  final ContainerScope scope;

  @override
  ConsumerState<MilestonesTab> createState() => _MilestonesTabState();
}

class _MilestonesTabState extends ConsumerState<MilestonesTab> {
  String? _state = 'active';
  String? _search;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filter = (scope: widget.scope, state: _state, search: _search);
    final list = ref.watch(milestonesProvider(filter));
    final notifier = ref.read(milestonesProvider(filter).notifier);
    final states = {
      'active': context.l10n.stateActive,
      'closed': context.l10n.stateClosed,
      null: context.l10n.stateAll,
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Insets.lg,
            Insets.sm,
            Insets.lg,
            0,
          ),
          child: SearchField(
            hint: context.l10n.searchMilestones,
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Insets.lg,
            Insets.sm,
            Insets.lg,
            Insets.xs,
          ),
          child: Row(
            children: [
              for (final e in states.entries) ...[
                ChoiceChip(
                  label: Text(e.value),
                  selected: _state == e.key,
                  onSelected: (_) => setState(() => _state = e.key),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: Insets.sm),
              ],
              const Spacer(),
              if (widget.scope.isProject)
                IconButton(
                  tooltip: context.l10n.newMilestone,
                  icon: const Icon(Icons.add),
                  onPressed: () => unawaited(
                    MilestoneFormScreen.show(
                      context,
                      projectId: widget.scope.id,
                    ).then((saved) {
                      if (saved) {
                        ref.invalidate(milestonesProvider);
                      }
                    }),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: AsyncValueWidget(
            value: list,
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
              empty: EmptyState(
                icon: Icons.flag_outlined,
                title: context.l10n.noMilestones,
              ),
              itemBuilder: (context, index) => _MilestoneTile(
                milestone: data.items[index],
                scope: widget.scope,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({required this.milestone, required this.scope});

  final Milestone milestone;
  final ContainerScope scope;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final overdue =
        milestone.dueDate != null &&
        milestone.isActive &&
        milestone.dueDate!.isBefore(DateTime.now());
    return ListTile(
      leading: Icon(
        Icons.flag_outlined,
        size: 18,
        color: milestone.isActive ? colors.accent : colors.inkFaint,
      ),
      title: Text(milestone.title, style: theme.textTheme.titleSmall),
      subtitle: Text(
        [
          if (milestone.startDate != null)
            context.l10n.startsOn(Format.date(milestone.startDate!)),
          if (milestone.dueDate != null)
            context.l10n.dueOn(Format.date(milestone.dueDate!)),
          if (!milestone.isActive) context.l10n.stateClosed,
        ].join(' · '),
        maxLines: 1,
        style: theme.textTheme.bodySmall?.copyWith(
          color: overdue ? colors.danger : null,
        ),
      ),
      dense: true,
      onTap: scope.isProject && milestone.iid != null
          ? () => unawaited(
              context.push(
                '/projects/${Uri.encodeComponent('${scope.id}')}'
                '/milestones/${milestone.iid}',
              ),
            )
          : null,
    );
  }
}

/// Milestone detail: description plus its issues and MRs.
class MilestoneDetailScreen extends ConsumerWidget {
  const MilestoneDetailScreen({required this.loc, super.key});

  final MilestoneRef loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final milestone = ref.watch(milestoneProvider(loc));

    return Scaffold(
      appBar: AppBar(
        title: Text(milestone.value?.title ?? context.l10n.milestone),
        actions: [
          if (milestone.value != null)
            IconButton(
              tooltip: context.l10n.actionEdit,
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => unawaited(
                MilestoneFormScreen.show(
                  context,
                  projectId: loc.projectId,
                  milestone: milestone.value,
                ).then((saved) {
                  if (saved) {
                    ref
                      ..invalidate(milestoneProvider)
                      ..invalidate(milestonesProvider);
                  }
                }),
              ),
            ),
        ],
      ),
      body: AsyncValueWidget(
        value: milestone,
        onRetry: () => ref.invalidate(milestoneProvider(loc)),
        data: (m) => DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Padding(
                padding: Insets.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (m.state != null)
                          Chip(
                            label: Text(
                              m.isActive
                                  ? context.l10n.active
                                  : context.l10n.stateClosed,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        const SizedBox(width: Insets.sm),
                        Text(
                          [
                            if (m.startDate != null) Format.date(m.startDate),
                            if (m.dueDate != null)
                              'due ${Format.date(m.dueDate)}',
                          ].join(' → '),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    if (m.description?.isNotEmpty ?? false) ...[
                      const SizedBox(height: Insets.sm),
                      MarkdownViewer(data: m.description!),
                    ],
                  ],
                ),
              ),
              Divider(height: 1, color: colors.border),
              TabBar(
                tabs: [
                  Tab(text: context.l10n.issuesTitle),
                  Tab(text: context.l10n.mrsTitle),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _MilestoneIssues(loc: loc),
                    _MilestoneMrs(loc: loc),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MilestoneIssues extends ConsumerWidget {
  const _MilestoneIssues({required this.loc});

  final MilestoneRef loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issues = ref.watch(milestoneIssuesProvider(loc));
    return AsyncValueWidget(
      value: issues,
      data: (items) => items.isEmpty
          ? EmptyState(icon: Icons.task_alt, title: context.l10n.noIssues)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: Insets.sm),
              itemCount: items.length,
              itemBuilder: (context, index) => IssueTile(
                issue: items[index],
                onTap: () => unawaited(
                  context.push(
                    '/projects/${items[index].projectId}'
                    '/issues/${items[index].iid}',
                  ),
                ),
              ),
            ),
    );
  }
}

class _MilestoneMrs extends ConsumerWidget {
  const _MilestoneMrs({required this.loc});

  final MilestoneRef loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mrs = ref.watch(milestoneMrsProvider(loc));
    return AsyncValueWidget(
      value: mrs,
      data: (items) => items.isEmpty
          ? EmptyState(icon: Icons.merge, title: context.l10n.noMergeRequests)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: Insets.sm),
              itemCount: items.length,
              itemBuilder: (context, index) => MrTile(
                mr: items[index],
                onTap: () => unawaited(
                  context.push(
                    '/projects/${items[index].projectId}'
                    '/mrs/${items[index].iid}',
                  ),
                ),
              ),
            ),
    );
  }
}

/// Create/edit form for a milestone.
class MilestoneFormScreen extends ConsumerStatefulWidget {
  const MilestoneFormScreen({
    required this.projectId,
    this.milestone,
    super.key,
  });

  final Object projectId;
  final Milestone? milestone;

  static Future<bool> show(
    BuildContext context, {
    required Object projectId,
    Milestone? milestone,
  }) async {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final child = MilestoneFormScreen(
      projectId: projectId,
      milestone: milestone,
    );
    final result = wide
        ? await showDialog<bool>(
            context: context,
            builder: (_) => Dialog(
              clipBehavior: Clip.antiAlias,
              insetPadding: const EdgeInsets.all(Insets.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: child,
              ),
            ),
          )
        : await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            showDragHandle: true,
            builder: (_) => child,
          );
    return result ?? false;
  }

  @override
  ConsumerState<MilestoneFormScreen> createState() =>
      _MilestoneFormScreenState();
}

class _MilestoneFormScreenState extends ConsumerState<MilestoneFormScreen> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  DateTime? _dueDate;
  DateTime? _startDate;
  var _saving = false;
  String? _error;

  bool get _editing => widget.milestone != null;

  @override
  void initState() {
    super.initState();
    final m = widget.milestone;
    _title = TextEditingController(text: m?.title ?? '');
    _description = TextEditingController(text: m?.description ?? '');
    _dueDate = m?.dueDate;
    _startDate = m?.startDate;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  String? _fmt(DateTime? d) => d?.toIso8601String().substring(0, 10);

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty || _saving) {
      setState(
        () => _error = title.isEmpty ? context.l10n.titleRequired : null,
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(milestonesRepositoryProvider);
    try {
      if (_editing) {
        await repo.update(
          widget.projectId,
          widget.milestone!.iid!,
          isProject: true,
          title: title,
          description: _description.text.trim(),
          dueDate: _fmt(_dueDate),
          startDate: _fmt(_startDate),
        );
      } else {
        await repo.create(
          widget.projectId,
          isProject: true,
          title: title,
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          dueDate: _fmt(_dueDate),
          startDate: _fmt(_startDate),
        );
      }
      if (mounted) {
        context.pop(true);
      }
    } on ApiException catch (e) {
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } on Object {
      setState(() {
        _saving = false;
        _error = context.l10n.milestoneSaveFailed;
      });
    }
  }

  Future<void> _pickDate(bool start) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: (start ? _startDate : _dueDate) ?? DateTime.now(),
    );
    if (picked != null) {
      setState(() => start ? _startDate = picked : _dueDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: Insets.lg,
        right: Insets.lg,
        top: Insets.lg,
        bottom: Insets.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _editing ? context.l10n.editMilestone : context.l10n.newMilestone,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: Insets.lg),
          TextField(
            controller: _title,
            autofocus: !_editing,
            decoration: InputDecoration(
              labelText: context.l10n.fieldTitle,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Insets.md),
          TextField(
            controller: _description,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: context.l10n.fieldDescription,
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Insets.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => unawaited(_pickDate(true)),
                  icon: const Icon(Icons.event_outlined, size: 18),
                  label: Text(_fmt(_startDate) ?? context.l10n.startDate),
                ),
              ),
              const SizedBox(width: Insets.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => unawaited(_pickDate(false)),
                  icon: const Icon(Icons.event_outlined, size: 18),
                  label: Text(_fmt(_dueDate) ?? context.l10n.dueDate),
                ),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: Insets.sm),
              child: Text(_error!, style: TextStyle(color: colors.danger)),
            ),
          const SizedBox(height: Insets.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _saving ? null : () => context.pop(false),
                child: Text(context.l10n.actionCancel),
              ),
              const SizedBox(width: Insets.sm),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _editing
                            ? context.l10n.actionSave
                            : context.l10n.createMilestone,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
