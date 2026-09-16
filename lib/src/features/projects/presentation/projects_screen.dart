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
import 'package:glam/src/features/projects/presentation/project_tile.dart';

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
                decoration: const InputDecoration(
                  hintText: 'Search projects',
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: _onSearchChanged,
              )
            : const Text('Projects'),
        actions: [
          IconButton(
            tooltip: _searching ? 'Close search' : 'Search',
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
            tooltip: 'Sort',
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
                      Text(sort.label),
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
                      label: Text(scope.label),
                      selected: filter.scope == scope,
                      onSelected: (_) => ref
                          .read(projectFilterProvider.notifier)
                          .setScope(scope),
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
            title: 'No projects',
            message: filter.search.isNotEmpty
                ? 'Nothing matches "${filter.search}"'
                : 'Projects you have access to will show up here',
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
