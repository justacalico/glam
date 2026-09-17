import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/models/iteration.dart';
import 'package:glam/src/core/utils/url_launcher.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/ci_variables_section.dart';
import 'package:glam/src/features/activity/presentation/activity_screen.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/notification_sheet.dart';
import 'package:glam/src/core/widgets/webhooks_section.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/core/widgets/user_avatar.dart';
import 'package:glam/src/features/groups/application/groups_providers.dart';
import 'package:glam/src/features/groups/domain/group.dart';
import 'package:glam/src/features/groups/presentation/edit_group_dialog.dart';
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
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined, size: 20),
            onPressed: () => unawaited(
              ScopedNotificationSheet.show(context, (
                id: groupId,
                isProject: false,
              )),
            ),
          ),
          IconButton(
            tooltip: 'Search this group',
            icon: const Icon(Icons.search, size: 20),
            onPressed: () =>
                unawaited(context.push(Routes.groupSearch(groupId))),
          ),
          PopupMenuButton<String>(
            tooltip: 'Group actions',
            iconSize: 20,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit group')),
              PopupMenuItem(value: 'delete', child: Text('Delete group')),
            ],
            onSelected: (v) {
              final g = group.value;
              if (v == 'edit' && g != null) {
                unawaited(EditGroupDialog.show(context, g));
              } else if (v == 'delete') {
                unawaited(_deleteGroup(context, ref, groupId));
              }
            },
          ),
        ],
      ),
      body: AsyncValueWidget<Group>(
        value: group,
        onRetry: () => ref.invalidate(groupProvider(groupId)),
        data: (g) => DefaultTabController(
          length: 10,
          child: Column(
            children: [
              _GroupHeader(group: g),
              const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Projects'),
                  Tab(text: 'Shared'),
                  Tab(text: 'Subgroups'),
                  Tab(text: 'Members'),
                  Tab(text: 'Milestones'),
                  Tab(text: 'Labels'),
                  Tab(text: 'Iterations'),
                  Tab(text: 'Variables'),
                  Tab(text: 'Webhooks'),
                  Tab(text: 'Activity'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _ProjectsTab(groupId: groupId),
                    _SharedProjectsTab(groupId: groupId),
                    _SubgroupsTab(groupId: groupId),
                    MembersList(id: groupId, isProject: false),
                    MilestonesTab(scope: (id: groupId, isProject: false)),
                    LabelsTab(scope: (id: groupId, isProject: false)),
                    _IterationsTab(groupId: groupId),
                    _VariablesTab(groupId: groupId),
                    _WebhooksTab(groupId: groupId),
                    EventList(feed: (kind: 'group', id: groupId)),
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

Future<void> _deleteGroup(
  BuildContext context,
  WidgetRef ref,
  Object groupId,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete group?'),
      content: const Text(
        'This deletes the group and all of its subgroups and content. '
        'This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete group'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) {
    return;
  }
  try {
    await ref.read(groupsRepositoryProvider).deleteGroup(groupId);
    ref.invalidate(groupsProvider(null));
    if (context.mounted) {
      context.go(Routes.groups);
    }
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
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

class _SharedProjectsTab extends ConsumerWidget {
  const _SharedProjectsTab({required this.groupId});

  final Object groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(sharedProjectsProvider(groupId));
    final notifier = ref.read(sharedProjectsProvider(groupId).notifier);

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
          icon: Icons.folder_shared_outlined,
          title: 'No projects shared with this group',
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

class _VariablesTab extends ConsumerWidget {
  const _VariablesTab({required this.groupId});

  final Object groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: Insets.pagePadding,
      children: [
        CiVariablesSection(
          variables: ref.watch(groupVariablesProvider(groupId)),
          onSave: (existing, fields) async {
            final repo = ref.read(groupsRepositoryProvider);
            if (existing == null) {
              await repo.createGroupVariable(
                groupId,
                key: fields.key,
                value: fields.value,
                protected_: fields.protected_,
                masked: fields.masked,
                environmentScope: fields.environmentScope,
              );
            } else {
              await repo.updateGroupVariable(
                groupId,
                existing.key,
                value: fields.value,
                protected_: fields.protected_,
                masked: fields.masked,
                environmentScope: fields.environmentScope,
              );
            }
            ref.invalidate(groupVariablesProvider(groupId));
          },
          onDelete: (v) async {
            await ref
                .read(groupsRepositoryProvider)
                .deleteGroupVariable(groupId, v.key);
            ref.invalidate(groupVariablesProvider(groupId));
          },
        ),
      ],
    );
  }
}

class _WebhooksTab extends ConsumerWidget {
  const _WebhooksTab({required this.groupId});

  final Object groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: Insets.pagePadding,
      children: [
        WebhooksSection(
          hooks: ref.watch(groupHooksProvider(groupId)),
          isGroup: true,
          onAdd: (draft) async {
            await ref
                .read(groupsRepositoryProvider)
                .createHook(
                  groupId,
                  url: draft.url,
                  token: draft.token,
                  events: draft.events,
                  enableSslVerification: draft.sslVerify,
                );
            ref.invalidate(groupHooksProvider(groupId));
          },
          onTest: (hook) async {
            await ref.read(groupsRepositoryProvider).testHook(groupId, hook.id);
          },
          onDelete: (hook) async {
            await ref
                .read(groupsRepositoryProvider)
                .deleteHook(groupId, hook.id);
            ref.invalidate(groupHooksProvider(groupId));
          },
        ),
      ],
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
