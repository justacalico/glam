import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/utils/debouncer.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/features/merge_requests/application/mr_providers.dart';
import 'package:glam/src/features/merge_requests/data/merge_requests_repository.dart';
import 'package:glam/src/features/merge_requests/presentation/mr_form_screen.dart';
import 'package:glam/src/features/merge_requests/presentation/mr_tile.dart';

/// Global MR list with scope/state/search filters.
class MergeRequestsScreen extends ConsumerStatefulWidget {
  const MergeRequestsScreen({super.key});

  @override
  ConsumerState<MergeRequestsScreen> createState() =>
      _MergeRequestsScreenState();
}

class _MergeRequestsScreenState extends ConsumerState<MergeRequestsScreen> {
  final _search = TextEditingController();
  final _debouncer = Debouncer();

  @override
  void dispose() {
    _search.dispose();
    _debouncer.dispose();
    super.dispose();
  }

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
        title: const Text('Merge requests'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
                child: SegmentedButton<MrScope>(
                  segments: [
                    for (final scope in MrScope.values)
                      ButtonSegment(value: scope, label: Text(scope.label)),
                  ],
                  selected: {filter.scope},
                  onSelectionChanged: (s) => _setFilter(
                    (f) => (scope: s.first, state: f.state, search: f.search),
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
                      child: SizedBox(
                        height: 38,
                        child: TextField(
                          controller: _search,
                          textInputAction: TextInputAction.search,
                          onChanged: (v) => _debouncer(
                            () => _setFilter(
                              (f) => (
                                scope: f.scope,
                                state: f.state,
                                search: v.isEmpty ? null : v,
                              ),
                            ),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search merge requests',
                            prefixIcon: const Icon(Icons.search, size: 18),
                            isDense: true,
                            filled: true,
                            fillColor: colors.surfaceMuted,
                            border: OutlineInputBorder(
                              borderRadius: Radii.borderMd,
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Insets.sm),
                    _StateMenu(
                      current: filter.state,
                      onSelect: (s) => _setFilter(
                        (f) => (scope: f.scope, state: s, search: f.search),
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
            icon: Icons.merge,
            title: 'No merge requests match this filter',
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

class _StateMenu extends StatelessWidget {
  const _StateMenu({required this.current, required this.onSelect});

  final String? current;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const options = {
      'opened': 'Open',
      'merged': 'Merged',
      'closed': 'Closed',
      null: 'All',
    };
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

/// MRs tab inside project detail: state chips + new MR button.
class ProjectMrsTab extends ConsumerStatefulWidget {
  const ProjectMrsTab({required this.projectId, super.key});

  final Object projectId;

  @override
  ConsumerState<ProjectMrsTab> createState() => _ProjectMrsTabState();
}

class _ProjectMrsTabState extends ConsumerState<ProjectMrsTab> {
  String? _state = 'opened';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filter = (project: widget.projectId, state: _state, search: null);
    final list = ref.watch(projectMrsProvider(filter));
    final notifier = ref.read(projectMrsProvider(filter).notifier);
    const states = {
      'opened': 'Open',
      'merged': 'Merged',
      'closed': 'Closed',
      null: 'All',
    };

    return Column(
      children: [
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
              IconButton(
                tooltip: 'New merge request',
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
              empty: const EmptyState(
                icon: Icons.merge,
                title: 'No merge requests',
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
