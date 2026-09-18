import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/models/milestone.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/filter_menu.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/core/widgets/search_field.dart';
import 'package:glam/src/core/widgets/sort_menu.dart';
import 'package:glam/src/features/merge_requests/application/mr_providers.dart';
import 'package:glam/src/features/merge_requests/data/merge_requests_repository.dart';
import 'package:glam/src/features/groups/application/groups_providers.dart';
import 'package:glam/src/features/groups/domain/group.dart';
import 'package:glam/src/features/labels/domain/label.dart';
import 'package:glam/src/features/merge_requests/presentation/mr_form_screen.dart';
import 'package:glam/src/features/milestones/application/planning_providers.dart';
import 'package:glam/src/features/repository/application/repository_providers.dart';
import 'package:glam/src/features/repository/domain/repo_models.dart';
import 'package:glam/src/features/merge_requests/presentation/mr_tile.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// Global MR list with scope/state/search filters.
class MergeRequestsScreen extends ConsumerStatefulWidget {
  const MergeRequestsScreen({super.key});

  @override
  ConsumerState<MergeRequestsScreen> createState() =>
      _MergeRequestsScreenState();
}

class _MergeRequestsScreenState extends ConsumerState<MergeRequestsScreen> {
  void _setFilter(MrFilter Function(MrFilter) update) {
    final current = ref.read(mrFilterProvider);
    ref.read(mrFilterProvider.notifier).update(update(current));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filter = ref.watch(mrFilterProvider);
    final state = ref.watch(mergeRequestsProvider);
    final notifier = ref.read(mergeRequestsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.mrsTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
                child: SegmentedButton<MrScope>(
                  segments: [
                    for (final scope in MrScope.values)
                      ButtonSegment(
                        value: scope,
                        label: Text(context.l10n.mrScopeLabel(scope)),
                      ),
                  ],
                  selected: {filter.scope},
                  onSelectionChanged: (s) => _setFilter(
                    (f) => (
                      scope: s.first,
                      state: f.state,
                      search: f.search,
                      wip: f.wip,
                      myReactionEmoji: f.myReactionEmoji,
                      updatedDays: f.updatedDays,
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
                      flex: 2,
                      child: SearchField(
                        hint: context.l10n.searchMrs,
                        onChanged: (v) => _setFilter(
                          (f) => (
                            scope: f.scope,
                            state: f.state,
                            search: v,
                            wip: f.wip,
                            myReactionEmoji: f.myReactionEmoji,
                            updatedDays: f.updatedDays,
                            orderBy: f.orderBy,
                            sort: f.sort,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Insets.sm),
                    Flexible(
                      flex: 3,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterMenu(
                              title: context.l10n.state,
                              current: filter.state,
                              options: const ['opened', 'merged', 'closed'],
                              labels: {
                                'opened': context.l10n.stateOpen,
                                'merged': context.l10n.stateMerged,
                                'closed': context.l10n.stateClosed,
                              },
                              onSelect: (s) => _setFilter(
                                (f) => (
                                  scope: f.scope,
                                  state: s,
                                  search: f.search,
                                  wip: f.wip,
                                  myReactionEmoji: f.myReactionEmoji,
                                  updatedDays: f.updatedDays,
                                  orderBy: f.orderBy,
                                  sort: f.sort,
                                ),
                              ),
                            ),
                            const SizedBox(width: Insets.sm),
                            FilterMenu(
                              title: context.l10n.draft,
                              current: filter.wip,
                              options: const ['yes', 'no'],
                              labels: {
                                'yes': context.l10n.draftsOnly,
                                'no': context.l10n.noDrafts,
                              },
                              onSelect: (w) => _setFilter(
                                (f) => (
                                  scope: f.scope,
                                  state: f.state,
                                  search: f.search,
                                  wip: w,
                                  myReactionEmoji: f.myReactionEmoji,
                                  updatedDays: f.updatedDays,
                                  orderBy: f.orderBy,
                                  sort: f.sort,
                                ),
                              ),
                            ),
                            FilterMenu(
                              title: context.l10n.activityTitle,
                              current: filter.updatedDays == null
                                  ? null
                                  : '${filter.updatedDays}',
                              options: const ['1', '7', '30'],
                              labels: {
                                '1': context.l10n.last24h,
                                '7': context.l10n.lastWeek,
                                '30': context.l10n.lastMonth,
                              },
                              onSelect: (v) => _setFilter(
                                (f) => (
                                  scope: f.scope,
                                  state: f.state,
                                  search: f.search,
                                  wip: f.wip,
                                  myReactionEmoji: f.myReactionEmoji,
                                  updatedDays: v == null ? null : int.parse(v),
                                  orderBy: f.orderBy,
                                  sort: f.sort,
                                ),
                              ),
                            ),
                            SortMenu(
                              orderBy: filter.orderBy,
                              sort: filter.sort,
                              options: SortOptions.mergeRequests(context.l10n),
                              onSelect: (o) => _setFilter(
                                (f) => (
                                  scope: f.scope,
                                  state: f.state,
                                  search: f.search,
                                  wip: f.wip,
                                  myReactionEmoji: f.myReactionEmoji,
                                  updatedDays: f.updatedDays,
                                  orderBy: o.orderBy,
                                  sort: o.sort,
                                ),
                              ),
                            ),
                          ],
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
          empty: EmptyState(
            icon: Icons.merge,
            title: context.l10n.noMrsMatchFilter,
          ),
          itemBuilder: (context, index) {
            final mr = data.items[index];
            return MrTile(
              mr: mr,
              onTap: () => unawaited(
                context.push(Routes.projectMr(mr.projectId, mr.iid)),
              ),
            );
          },
        ),
      ),
    );
  }
}

const _reactions = ['thumbsup', 'thumbsdown', 'smile', 'tada', 'heart'];
Map<String, String> _reactionLabels(AppLocalizations l10n) => {
  'thumbsup': l10n.reactionThumbsup,
  'thumbsdown': l10n.reactionThumbsdown,
  'smile': l10n.reactionSmile,
  'tada': l10n.reactionTada,
  'heart': l10n.reactionHeart,
};

/// MRs tab inside project detail: state chips + new MR button.
class ProjectMrsTab extends ConsumerStatefulWidget {
  const ProjectMrsTab({required this.projectId, super.key});

  final Object projectId;

  @override
  ConsumerState<ProjectMrsTab> createState() => _ProjectMrsTabState();
}

class _ProjectMrsTabState extends ConsumerState<ProjectMrsTab> {
  String? _state = 'opened';
  MrScope _scope = MrScope.all;
  String? _search;
  String? _label;
  String? _milestone;
  String? _targetBranch;
  int? _assigneeId;
  int? _authorId;
  String? _wip;
  String? _myReaction;
  int? _updatedDays;
  String? _orderBy;
  String? _sort;

  static Map<MrScope, String> _scopes(AppLocalizations l10n) => {
    MrScope.all: l10n.stateAll,
    MrScope.assigned: l10n.mrScopeAssigned,
    MrScope.created: l10n.mrScopeCreated,
    MrScope.review: l10n.mrScopeReview,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filter = (
      project: widget.projectId,
      scope: _scope,
      state: _state,
      search: _search,
      label: _label,
      milestone: _milestone,
      targetBranch: _targetBranch,
      assigneeId: _assigneeId,
      authorId: _authorId,
      wip: _wip,
      myReactionEmoji: _myReaction,
      updatedDays: _updatedDays,
      orderBy: _orderBy,
      sort: _sort,
    );
    final list = ref.watch(projectMrsProvider(filter));
    final notifier = ref.read(projectMrsProvider(filter).notifier);
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
    final branches =
        ref
            .watch(branchesProvider((project: widget.projectId, search: null)))
            .value
            ?.items ??
        const <Branch>[];
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
    final states = {
      'opened': context.l10n.stateOpen,
      'merged': context.l10n.stateMerged,
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
            hint: context.l10n.searchMrs,
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
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
              FilterMenu(
                title: context.l10n.scopeFilter,
                current: _scope == MrScope.all
                    ? null
                    : _scopes(context.l10n)[_scope],
                options: [
                  for (final e in _scopes(context.l10n).entries)
                    if (e.key != MrScope.all) e.value,
                ],
                onSelect: (v) => setState(
                  () => _scope = _scopes(context.l10n).entries
                      .firstWhere(
                        (e) => e.value == v,
                        orElse: () => const MapEntry(MrScope.all, ''),
                      )
                      .key,
                ),
              ),
              FilterMenu(
                title: context.l10n.assignee,
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
                title: context.l10n.author,
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
                title: context.l10n.labelFilter,
                current: _label,
                options: [for (final l in labels) l.name],
                onSelect: (v) => setState(() => _label = v),
              ),
              FilterMenu(
                title: context.l10n.milestone,
                current: _milestone,
                options: [for (final m in milestones) m.title],
                onSelect: (v) => setState(() => _milestone = v),
              ),
              FilterMenu(
                title: context.l10n.branchFilter,
                current: _targetBranch,
                options: [for (final b in branches) b.name],
                onSelect: (v) => setState(() => _targetBranch = v),
              ),
              FilterMenu(
                title: context.l10n.draft,
                current: _wip,
                options: const ['yes', 'no'],
                labels: {
                  'yes': context.l10n.draftsOnly,
                  'no': context.l10n.noDrafts,
                },
                onSelect: (v) => setState(() => _wip = v),
              ),
              FilterMenu(
                title: context.l10n.reactedFilter,
                current: _myReaction,
                options: _reactions,
                labels: _reactionLabels(context.l10n),
                onSelect: (v) => setState(() => _myReaction = v),
              ),
              FilterMenu(
                title: context.l10n.activityTitle,
                current: _updatedDays == null ? null : '$_updatedDays',
                options: const ['1', '7', '30'],
                labels: {
                  '1': context.l10n.last24h,
                  '7': context.l10n.lastWeek,
                  '30': context.l10n.lastMonth,
                },
                onSelect: (v) => setState(
                  () => _updatedDays = v == null ? null : int.parse(v),
                ),
              ),
              SortMenu(
                orderBy: _orderBy,
                sort: _sort,
                options: SortOptions.mergeRequests(context.l10n),
                onSelect: (o) => setState(() {
                  _orderBy = o.orderBy;
                  _sort = o.sort;
                }),
              ),
              IconButton(
                tooltip: context.l10n.newMr,
                icon: const Icon(Icons.add),
                onPressed: () => unawaited(
                  MrFormScreen.show(context, projectId: widget.projectId),
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
                icon: Icons.merge,
                title: context.l10n.noMergeRequests,
                actionLabel: context.l10n.newMr,
                onAction: () => unawaited(
                  MrFormScreen.show(context, projectId: widget.projectId),
                ),
              ),
              itemBuilder: (context, index) {
                final mr = data.items[index];
                return MrTile(
                  mr: mr,
                  onTap: () => unawaited(
                    context.push(Routes.projectMr(mr.projectId, mr.iid)),
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
