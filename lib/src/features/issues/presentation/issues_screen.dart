import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/filter_menu.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/core/widgets/search_field.dart';
import 'package:glam/src/core/widgets/sort_menu.dart';
import 'package:glam/src/features/issues/application/issues_providers.dart';
import 'package:glam/src/features/issues/data/issues_repository.dart';
import 'package:glam/src/features/issues/presentation/issue_form_screen.dart';
import 'package:glam/src/features/issues/presentation/issue_tile.dart';
import 'package:glam/src/features/labels/domain/label.dart';
import 'package:glam/src/core/models/milestone.dart';
import 'package:glam/src/features/groups/application/groups_providers.dart';
import 'package:glam/src/features/groups/domain/group.dart';
import 'package:glam/src/features/milestones/application/planning_providers.dart';

/// Global issues list with scope/state/search filters.
class IssuesScreen extends ConsumerStatefulWidget {
  const IssuesScreen({super.key});

  @override
  ConsumerState<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends ConsumerState<IssuesScreen> {
  void _setFilter(IssueFilter Function(IssueFilter) update) {
    final current = ref.read(issueFilterProvider);
    ref.read(issueFilterProvider.notifier).update(update(current));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filter = ref.watch(issueFilterProvider);
    final state = ref.watch(issuesProvider);
    final notifier = ref.read(issuesProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Issues'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
                child: SegmentedButton<IssueScope>(
                  segments: [
                    for (final scope in IssueScope.values)
                      ButtonSegment(value: scope, label: Text(scope.label)),
                  ],
                  selected: {filter.scope},
                  onSelectionChanged: (s) => _setFilter(
                    (f) => (
                      scope: s.first,
                      state: f.state,
                      search: f.search,
                      issueType: f.issueType,
                      confidential: null,
                      orderBy: f.orderBy,
                      sort: f.sort,
                    ),
                  ),
                  showSelectedIcon: false,
                ),
              ),
              const SizedBox(height: Insets.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: SearchField(
                        hint: 'Search issues',
                        onChanged: (v) => _setFilter(
                          (f) => (
                            scope: f.scope,
                            state: f.state,
                            search: v,
                            issueType: f.issueType,
                            confidential: f.confidential,
                            orderBy: f.orderBy,
                            sort: f.sort,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Insets.sm),
                    _StateMenu(
                      current: filter.state,
                      onSelect: (s) => _setFilter(
                        (f) => (
                          scope: f.scope,
                          state: s,
                          search: f.search,
                          issueType: f.issueType,
                          confidential: f.confidential,
                          orderBy: f.orderBy,
                          sort: f.sort,
                        ),
                      ),
                    ),
                    FilterMenu(
                      title: 'Type',
                      current: filter.issueType,
                      options: const ['issue', 'incident', 'task', 'test_case'],
                      onSelect: (v) => _setFilter(
                        (f) => (
                          scope: f.scope,
                          state: f.state,
                          search: f.search,
                          issueType: v,
                          confidential: f.confidential,
                          orderBy: f.orderBy,
                          sort: f.sort,
                        ),
                      ),
                    ),
                    FilterMenu(
                      title: 'Confidential',
                      current: switch (filter.confidential) {
                        true => 'true',
                        false => 'false',
                        null => null,
                      },
                      options: const ['true', 'false'],
                      labels: const {
                        'true': 'Confidential',
                        'false': 'Not confidential',
                      },
                      onSelect: (v) => _setFilter(
                        (f) => (
                          scope: f.scope,
                          state: f.state,
                          search: f.search,
                          issueType: f.issueType,
                          confidential: v == null ? null : v == 'true',
                          orderBy: f.orderBy,
                          sort: f.sort,
                        ),
                      ),
                    ),
                    SortMenu(
                      orderBy: filter.orderBy,
                      sort: filter.sort,
                      options: SortOptions.issues,
                      onSelect: (o) => _setFilter(
                        (f) => (
                          scope: f.scope,
                          state: f.state,
                          search: f.search,
                          issueType: f.issueType,
                          confidential: f.confidential,
                          orderBy: o.orderBy,
                          sort: o.sort,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Insets.sm),
            ],
          ),
        ),
      ),
      body: AsyncValueWidget(
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
            icon: Icons.task_alt,
            title: 'No issues match this filter',
          ),
          itemBuilder: (context, index) {
            final issue = data.items[index];
            return IssueTile(
              issue: issue,
              onTap: () => unawaited(
                context.push(Routes.projectIssue(issue.projectId, issue.iid)),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StateMenu extends StatelessWidget {
  const _StateMenu({required this.current, required this.onSelect});

  final String? current;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const options = {'opened': 'Open', 'closed': 'Closed', null: 'All'};
    return PopupMenuButton<String?>(
      initialValue: current,
      onSelected: onSelect,
      itemBuilder: (context) => [
        for (final e in options.entries)
          PopupMenuItem(value: e.key, child: Text(e.value)),
      ],
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: Insets.md),
        decoration: BoxDecoration(
          color: colors.surfaceMuted,
          borderRadius: Radii.borderMd,
        ),
        child: Row(
          children: [
            Text(
              options[current] ?? 'All',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(width: Insets.xs),
            Icon(Icons.expand_more, size: 16, color: colors.inkMuted),
          ],
        ),
      ),
    );
  }
}

/// Issues tab inside project detail: state chips + a new-issue button
/// above the list.
class ProjectIssuesTab extends ConsumerStatefulWidget {
  const ProjectIssuesTab({required this.projectId, super.key});

  final Object projectId;

  @override
  ConsumerState<ProjectIssuesTab> createState() => _ProjectIssuesTabState();
}

class _ProjectIssuesTabState extends ConsumerState<ProjectIssuesTab> {
  String? _state = 'opened';
  String? _search;
  String? _label;
  String? _milestone;
  String? _issueType;
  bool? _confidential;
  int? _assigneeId;
  int? _authorId;
  String? _orderBy;
  String? _sort;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filter = (
      project: widget.projectId,
      state: _state,
      search: _search,
      label: _label,
      milestone: _milestone,
      issueType: _issueType,
      confidential: _confidential,
      assigneeId: _assigneeId,
      authorId: _authorId,
      orderBy: _orderBy,
      sort: _sort,
    );
    final list = ref.watch(projectIssuesProvider(filter));
    final notifier = ref.read(projectIssuesProvider(filter).notifier);
    final stats = ref.watch(projectIssueStatsProvider(widget.projectId)).value;
    final milestones =
        ref
            .watch(
              milestonesProvider((
                scope: (id: widget.projectId, isProject: true),
                state: 'active',
                search: null,
              )),
            )
            .value
            ?.items ??
        const <Milestone>[];
    final labels =
        ref
            .watch(
              labelsProvider((
                scope: (id: widget.projectId, isProject: true),
                search: null,
              )),
            )
            .value ??
        const <Label>[];
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
        const <Member>[];
    const states = {'opened': 'Open', 'closed': 'Closed', null: 'All'};
    final counts = {
      'opened': stats?.opened,
      'closed': stats?.closed,
      null: stats?.all,
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
            hint: 'Search issues',
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
                  label: Text(
                    counts[e.key] != null
                        ? '${e.value} ${counts[e.key]}'
                        : e.value,
                  ),
                  selected: _state == e.key,
                  onSelected: (_) => setState(() => _state = e.key),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: Insets.sm),
              ],
              const Spacer(),
              FilterMenu(
                title: 'Assignee',
                current: _assigneeId == null
                    ? null
                    : members
                          .where((m) => m.id == _assigneeId)
                          .firstOrNull
                          ?.username,
                options: [for (final m in members) m.username],
                onSelect: (v) => setState(
                  () => _assigneeId = v == null
                      ? null
                      : members.where((m) => m.username == v).firstOrNull?.id,
                ),
              ),
              FilterMenu(
                title: 'Author',
                current: _authorId == null
                    ? null
                    : members
                          .where((m) => m.id == _authorId)
                          .firstOrNull
                          ?.username,
                options: [for (final m in members) m.username],
                onSelect: (v) => setState(
                  () => _authorId = v == null
                      ? null
                      : members.where((m) => m.username == v).firstOrNull?.id,
                ),
              ),
              FilterMenu(
                title: 'Label',
                current: _label,
                options: [for (final l in labels) l.name],
                onSelect: (v) => setState(() => _label = v),
              ),
              FilterMenu(
                title: 'Milestone',
                current: _milestone,
                options: [for (final m in milestones) m.title],
                onSelect: (v) => setState(() => _milestone = v),
              ),
              FilterMenu(
                title: 'Type',
                current: _issueType,
                options: const ['issue', 'incident', 'task', 'test_case'],
                onSelect: (v) => setState(() => _issueType = v),
              ),
              FilterMenu(
                title: 'Confidential',
                current: switch (_confidential) {
                  true => 'true',
                  false => 'false',
                  null => null,
                },
                options: const ['true', 'false'],
                labels: const {
                  'true': 'Confidential',
                  'false': 'Not confidential',
                },
                onSelect: (v) => setState(
                  () => _confidential = v == null ? null : v == 'true',
                ),
              ),
              SortMenu(
                orderBy: _orderBy,
                sort: _sort,
                options: SortOptions.issues,
                onSelect: (o) => setState(() {
                  _orderBy = o.orderBy;
                  _sort = o.sort;
                }),
              ),
              IconButton(
                tooltip: 'New issue',
                icon: const Icon(Icons.add),
                onPressed: () => unawaited(
                  IssueFormScreen.show(context, projectId: widget.projectId),
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
              empty: const EmptyState(icon: Icons.task_alt, title: 'No issues'),
              itemBuilder: (context, index) {
                final issue = data.items[index];
                return IssueTile(
                  issue: issue,
                  onTap: () => unawaited(
                    context.push(
                      Routes.projectIssue(issue.projectId, issue.iid),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
