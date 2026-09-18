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
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/projects/domain/project_filter.dart';
import 'package:glam/src/features/projects/presentation/new_project_dialog.dart';
import 'package:glam/src/features/projects/presentation/project_tile.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// Projects list: yours / starred / explore / all, with search and sort.
class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  final _searchController = TextEditingController();
  final _debouncer = Debouncer();
  bool _searching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debouncer(
      () => ref.read(projectFilterProvider.notifier).setSearch(value.trim()),
    );
  }

  Future<void> _newProject() async {
    final project = await NewProjectDialog.show(context);
    if (project != null && mounted) {
      unawaited(context.push(Routes.project(project.id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filter = ref.watch(projectFilterProvider);
    final state = ref.watch(projectsListProvider);
    final notifier = ref.read(projectsListProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: context.l10n.projectsSearchHint,
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: _onSearchChanged,
              )
            : Text(context.l10n.projectsTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.projectNew,
            icon: const Icon(Icons.add),
            onPressed: () => unawaited(_newProject()),
          ),
          IconButton(
            tooltip: _searching
                ? context.l10n.searchClose
                : context.l10n.searchTitle,
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _searching = !_searching;
                if (!_searching) {
                  _searchController.clear();
                  _onSearchChanged('');
                }
              });
            },
          ),
          PopupMenuButton<ProjectSort>(
            tooltip: context.l10n.sortTitle,
            icon: const Icon(Icons.sort),
            initialValue: filter.sort,
            onSelected: (sort) =>
                ref.read(projectFilterProvider.notifier).setSort(sort),
            itemBuilder: (context) => [
              for (final sort in ProjectSort.values)
                PopupMenuItem(
                  value: sort,
                  child: Row(
                    children: [
                      if (sort == filter.sort)
                        Icon(Icons.check, size: 16, color: colors.accent)
                      else
                        const SizedBox(width: 16),
                      const SizedBox(width: Insets.sm),
                      Text(context.l10n.projectSort(sort.name)),
                    ],
                  ),
                ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
              children: [
                for (final scope in ProjectScope.values)
                  Padding(
                    padding: const EdgeInsets.only(right: Insets.sm),
                    child: ChoiceChip(
                      label: Text(context.l10n.projectScope(scope.name)),
                      selected: filter.scope == scope,
                      onSelected: (_) => ref
                          .read(projectFilterProvider.notifier)
                          .setScope(scope),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
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
          separator: Divider(
            height: 1,
            color: colors.border,
            indent: Insets.lg,
            endIndent: Insets.lg,
          ),
          padding: const EdgeInsets.symmetric(vertical: Insets.sm),
          empty: EmptyState(
            icon: Icons.folder_open,
            title: context.l10n.projectsEmpty,
            message: filter.search.isNotEmpty
                ? context.l10n.projectsEmptyMatch(filter.search)
                : context.l10n.projectsEmptyHint,
          ),
          itemBuilder: (context, index) => ProjectTile(
            project: data.items[index],
            onTap: () => context.push(Routes.project(data.items[index].id)),
          ),
        ),
      ),
    );
  }
}
