import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/core/widgets/user_avatar.dart';
import 'package:glam/src/features/groups/application/groups_providers.dart';
import 'package:glam/src/features/groups/domain/group.dart';
import 'package:glam/src/features/groups/presentation/groups_screen.dart';
import 'package:glam/src/features/groups/presentation/members_screen.dart';
import 'package:glam/src/features/projects/presentation/project_tile.dart';

/// Group home: header plus tabs for projects, subgroups, members.
class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({required this.groupId, super.key});

  final Object groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupProvider(groupId));

    return Scaffold(
      appBar: AppBar(title: const Text('Group')),
      body: AsyncValueWidget<Group>(
        value: group,
        onRetry: () => ref.invalidate(groupProvider(groupId)),
        data: (g) => DefaultTabController(
          length: 3,
          child: Column(
            children: [
              _GroupHeader(group: g),
              const TabBar(
                tabs: [
                  Tab(text: 'Projects'),
                  Tab(text: 'Subgroups'),
                  Tab(text: 'Members'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _ProjectsTab(groupId: groupId),
                    _SubgroupsTab(groupId: groupId),
                    MembersList(id: groupId, isProject: false),
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
