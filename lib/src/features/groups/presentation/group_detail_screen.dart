import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/models/iteration.dart';
import 'package:glam/src/core/utils/url_launcher.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/core/widgets/user_avatar.dart';
import 'package:glam/src/features/groups/application/groups_providers.dart';
import 'package:glam/src/features/groups/domain/group.dart';
import 'package:glam/src/features/groups/presentation/groups_screen.dart';
import 'package:glam/src/features/groups/presentation/members_screen.dart';
import 'package:glam/src/features/labels/presentation/labels_screen.dart';
import 'package:glam/src/features/milestones/presentation/milestones_screen.dart';
import 'package:glam/src/features/projects/presentation/project_tile.dart';

/// Group home: header plus tabs for projects, subgroups, members.
class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({required this.groupId, super.key});

  final Object groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupProvider(groupId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group'),
        actions: [
          IconButton(
            tooltip: 'Search this group',
            icon: const Icon(Icons.search, size: 20),
            onPressed: () =>
                unawaited(context.push(Routes.groupSearch(groupId))),
          ),
        ],
      ),
      body: AsyncValueWidget<Group>(
        value: group,
        onRetry: () => ref.invalidate(groupProvider(groupId)),
        data: (g) => DefaultTabController(
          length: 6,
          child: Column(
            children: [
              _GroupHeader(group: g),
              const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Projects'),
                  Tab(text: 'Subgroups'),
                  Tab(text: 'Members'),
                  Tab(text: 'Milestones'),
                  Tab(text: 'Labels'),
                  Tab(text: 'Iterations'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _ProjectsTab(groupId: groupId),
                    _SubgroupsTab(groupId: groupId),
                    MembersList(id: groupId, isProject: false),
                    MilestonesTab(scope: (id: groupId, isProject: false)),
                    LabelsTab(scope: (id: groupId, isProject: false)),
                    _IterationsTab(groupId: groupId),
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

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});

  final Group group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return Padding(
      padding: Insets.pagePadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(name: group.name, avatarUrl: group.avatarUrl, radius: 26),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group.name, style: theme.textTheme.headlineSmall),
                Text(
                  group.fullPath,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
                if (group.description?.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.only(top: Insets.xs),
                    child: Text(
                      group.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.inkMuted,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectsTab extends ConsumerWidget {
  const _ProjectsTab({required this.groupId});

  final Object groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(groupProjectsProvider(groupId));
    final notifier = ref.read(groupProjectsProvider(groupId).notifier);

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
          icon: Icons.folder_outlined,
          title: 'No projects in this group',
        ),
        itemBuilder: (context, index) {
          final p = data.items[index];
          return ProjectTile(
            project: p,
            onTap: () => unawaited(context.push(Routes.project(p.id))),
          );
        },
      ),
    );
  }
}

class _IterationsTab extends ConsumerWidget {
  const _IterationsTab({required this.groupId});

  final Object groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final iterations = ref.watch(groupIterationsProvider(groupId));

    return AsyncValueWidget<List<Iteration>>(
      value: iterations,
      onRetry: () => ref.invalidate(groupIterationsProvider(groupId)),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.event_repeat_outlined,
            title: 'No iterations',
            message: 'Iterations need a Premium group with a cadence.',
          );
        }
        return ListView.separated(
          padding: Insets.pagePadding,
          itemCount: items.length,
          separatorBuilder: (_, _) => Divider(color: colors.border, height: 1),
          itemBuilder: (context, index) {
            final it = items[index];
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_repeat_outlined, size: 18),
              title: Text(it.label),
              subtitle: it.state.isEmpty
                  ? null
                  : Text(
                      it.state,
                      style: TextStyle(
                        color: it.state == 'current'
                            ? colors.success
                            : colors.inkMuted,
                      ),
                    ),
              trailing: it.webUrl == null
                  ? null
                  : IconButton(
                      tooltip: 'Open in browser',
                      icon: const Icon(Icons.open_in_new, size: 16),
                      onPressed: () => unawaited(launchExternal(it.webUrl!)),
                    ),
            );
          },
        );
      },
    );
  }
}

class _SubgroupsTab extends ConsumerWidget {
  const _SubgroupsTab({required this.groupId});

  final Object groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(subgroupsProvider(groupId));
    final notifier = ref.read(subgroupsProvider(groupId).notifier);

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
          icon: Icons.workspaces_outlined,
          title: 'No subgroups',
        ),
        itemBuilder: (context, index) => GroupTile(group: data.items[index]),
      ),
    );
  }
}
