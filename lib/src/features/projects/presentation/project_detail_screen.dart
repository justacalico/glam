import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/utils/url_launcher.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/notification_sheet.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/core/widgets/state_chip.dart';
import 'package:glam/src/core/widgets/users_sheet.dart';
import 'package:glam/src/features/activity/presentation/activity_screen.dart';
import 'package:glam/src/features/groups/presentation/members_screen.dart';
import 'package:glam/src/features/boards/presentation/boards_screen.dart';
import 'package:glam/src/features/alerts/presentation/alerts_tab.dart';
import 'package:glam/src/features/environments/presentation/environments_screen.dart';
import 'package:glam/src/features/environments/presentation/feature_flags_tab.dart';
import 'package:glam/src/features/issues/presentation/issues_screen.dart';
import 'package:glam/src/features/labels/presentation/labels_screen.dart';
import 'package:glam/src/features/milestones/presentation/milestones_screen.dart';
import 'package:glam/src/features/merge_requests/presentation/merge_requests_screen.dart';
import 'package:glam/src/features/pipelines/application/pipelines_providers.dart';
import 'package:glam/src/features/pipelines/presentation/pipelines_screen.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/registry/presentation/packages_tab.dart';
import 'package:glam/src/features/registry/presentation/registry_tab.dart';
import 'package:glam/src/features/snippets/presentation/snippets_screen.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/presentation/project_overview_tab.dart';
import 'package:glam/src/features/projects/presentation/project_tile.dart';
import 'package:glam/src/features/repository/application/repository_providers.dart';
import 'package:glam/src/features/repository/presentation/branches_screen.dart';
import 'package:glam/src/features/repository/presentation/commits_screen.dart';
import 'package:glam/src/features/repository/presentation/files_screen.dart';
import 'package:glam/src/features/repository/presentation/releases_screen.dart';
import 'package:glam/src/features/repository/presentation/tags_screen.dart';
import 'package:glam/src/features/wiki/presentation/wiki_screen.dart';

/// Project home: header card + tabbed content.
class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectProvider(projectId));

    return Scaffold(
      body: AsyncValueWidget<Project>(
        value: project,
        onRetry: () => ref.invalidate(projectProvider(projectId)),
        data: (p) => _ProjectBody(project: p),
      ),
    );
  }
}

class _ProjectBody extends ConsumerWidget {
  const _ProjectBody({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = _tabsFor(project);
    return DefaultTabController(
      length: tabs.length,
      child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            title: Text(
              project.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SliverToBoxAdapter(child: _ProjectHeader(project: project)),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [for (final t in tabs) Tab(text: t.label)],
              ),
            ),
          ),
        ],
        body: TabBarView(children: [for (final t in tabs) t.builder()]),
      ),
    );
  }

  List<({String label, Widget Function() builder})> _tabsFor(Project project) {
    return [
      (label: 'Overview', builder: () => ProjectOverviewTab(project: project)),
      (label: 'Issues', builder: () => ProjectIssuesTab(projectId: project.id)),
      (label: 'MRs', builder: () => ProjectMrsTab(projectId: project.id)),
      (
        label: 'Pipelines',
        builder: () => PipelinesScreen(projectId: project.id),
      ),
      (
        label: 'Environments',
        builder: () => EnvironmentsScreen(projectId: project.id),
      ),
      (label: 'Flags', builder: () => FeatureFlagsTab(projectId: project.id)),
      (label: 'Alerts', builder: () => AlertsTab(projectId: project.id)),
      (
        label: 'Members',
        builder: () => MembersList(id: project.id, isProject: true),
      ),
      (
        label: 'Activity',
        builder: () => EventList(feed: (kind: 'project', id: project.id)),
      ),
      if (project.forksCount > 0)
        (label: 'Forks', builder: () => _ForksTab(projectId: project.id)),
      if (!project.emptyRepo)
        (
          label: 'Contributors',
          builder: () => _ContributorsTab(projectId: project.id),
        ),
      (
        label: 'Packages',
        builder: () => ProjectPackagesTab(projectId: project.id),
      ),
      (
        label: 'Registry',
        builder: () => ProjectRegistryTab(projectId: project.id),
      ),
      (
        label: 'Snippets',
        builder: () => ProjectSnippetsTab(projectId: project.id),
      ),
      (label: 'Wiki', builder: () => ProjectWikiTab(projectId: project.id)),
      (
        label: 'Boards',
        builder: () => BoardsTab(scope: (id: project.id, isProject: true)),
      ),
      (
        label: 'Milestones',
        builder: () => MilestonesTab(scope: (id: project.id, isProject: true)),
      ),
      (
        label: 'Labels',
        builder: () => LabelsTab(scope: (id: project.id, isProject: true)),
      ),
      if (!project.emptyRepo)
        (
          label: 'Files',
          builder: () => FilesScreen(
            projectId: project.id.toString(),
            defaultRef: project.defaultBranch,
          ),
        ),
      if (!project.emptyRepo)
        (
          label: 'Commits',
          builder: () => CommitsScreen(projectId: project.id.toString()),
        ),
      if (!project.emptyRepo)
        (
          label: 'Branches',
          builder: () => BranchesScreen(projectId: project.id.toString()),
        ),
      (
        label: 'Tags',
        builder: () => TagsScreen(projectId: project.id.toString()),
      ),
      (
        label: 'Releases',
        builder: () => ReleasesScreen(projectId: project.id.toString()),
      ),
    ];
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height + 1;

  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: context.colors.canvas,
      child: Column(
        children: [
          tabBar,
          Divider(height: 1, color: context.colors.border),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}

class _ProjectHeader extends ConsumerWidget {
  const _ProjectHeader({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Insets.lg,
        Insets.xs,
        Insets.lg,
        Insets.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Hero(tag: 'project-avatar-${project.id}', child: _avatar(colors)),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (project.namespacePath != null)
                      Text(
                        project.namespacePath!,
                        style: theme.textTheme.bodySmall,
                      ),
                    Text(
                      project.name,
                      style: theme.textTheme.headlineMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (project.description?.isNotEmpty ?? false) ...[
            const SizedBox(height: Insets.sm),
            Text(
              project.description!,
              style: theme.textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: Insets.md),
          Wrap(
            spacing: Insets.lg,
            runSpacing: Insets.sm,
            children: [
              _Stat(
                icon: Icons.star_outline,
                value: Format.compact(project.starCount),
                label: 'stars',
                onTap: () => unawaited(
                  UsersSheet.show(
                    context,
                    title: 'Starrers',
                    provider: projectStarrersProvider(project.id),
                  ),
                ),
              ),
              _Stat(
                icon: Icons.fork_right,
                value: Format.compact(project.forksCount),
                label: 'forks',
              ),
              _Stat(
                icon: Icons.adjust,
                value: Format.compact(project.openIssuesCount),
                label: 'issues',
              ),
              if (project.visibility != null)
                _Stat(
                  icon: project.visibility == 'private'
                      ? Icons.lock_outline
                      : Icons.public,
                  value: project.visibility!.toUpperCase(),
                  label: '',
                ),
              _LatestPipelineStat(projectId: project.id),
            ],
          ),
          const SizedBox(height: Insets.md),
          Wrap(
            spacing: Insets.sm,
            children: [
              _ActionChip(
                icon: Icons.search,
                label: 'Search',
                onTap: () =>
                    unawaited(context.push(Routes.projectSearch(project.id))),
              ),
              _ActionChip(
                icon: Icons.star_outline,
                label: 'Star',
                onTap: () => _toggleStar(ref, context),
              ),
              _ActionChip(
                icon: Icons.fork_right,
                label: 'Fork',
                onTap: () => _fork(ref, context),
              ),
              _ActionChip(
                icon: Icons.link,
                label: 'Copy clone URL',
                onTap: () => _copyClone(context),
              ),
              _ActionChip(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: () => unawaited(
                  ScopedNotificationSheet.show(context, (
                    id: project.id,
                    isProject: true,
                  )),
                ),
              ),
              if (project.webUrl != null)
                _ActionChip(
                  icon: Icons.open_in_new,
                  label: 'Open in browser',
                  onTap: () => launchExternal(project.webUrl!),
                ),
              _ActionChip(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () =>
                    unawaited(context.push(Routes.projectSettings(project.id))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatar(GlamColors colors) {
    final url = project.avatarUrl;
    Widget fallback() => Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: Radii.borderMd,
      ),
      alignment: Alignment.center,
      child: Text(
        project.name.isNotEmpty ? project.name[0].toUpperCase() : '?',
        style: TextStyle(
          color: colors.accent,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
      ),
    );
    if (url == null || url.isEmpty) {
      return fallback();
    }
    return ClipRRect(
      borderRadius: Radii.borderMd,
      child: Image.network(
        url,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      ),
    );
  }

  Future<void> _toggleStar(WidgetRef ref, BuildContext context) async {
    // The detail response does not carry a starred flag; star first, and
    // unstar on the projects list.
    await ref.read(projectActionsProvider).toggleStar(project, starred: false);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Starred')));
    }
  }

  Future<void> _fork(WidgetRef ref, BuildContext context) async {
    try {
      final forked = await ref
          .read(projectsRepositoryProvider)
          .fork(project.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Forked to ${forked.pathWithNamespace}')),
        );
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not fork the project')),
        );
      }
    }
  }

  Future<void> _copyClone(BuildContext context) async {
    final url = project.httpUrl ?? project.sshUrl;
    if (url == null) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Clone URL copied')));
    }
  }
}

/// Commit authors ranked by commit count (`/repository/contributors`).
class _ContributorsTab extends ConsumerWidget {
  const _ContributorsTab({required this.projectId});

  final Object projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final contributors = ref.watch(projectContributorsProvider(projectId));
    final theme = Theme.of(context);

    return AsyncValueWidget(
      value: contributors,
      onRetry: () => ref.invalidate(projectContributorsProvider(projectId)),
      data: (items) => items.isEmpty
          ? const EmptyState(
              icon: Icons.people_outline,
              title: 'No contributors',
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: Insets.sm),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: colors.border, indent: Insets.lg),
              itemBuilder: (context, i) {
                final c = items[i];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 14,
                    child: Text(
                      c.name.isEmpty ? '?' : c.name.characters.first,
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                  title: Text(c.name, style: theme.textTheme.bodyMedium),
                  subtitle: c.email.isEmpty
                      ? null
                      : Text(c.email, style: theme.textTheme.bodySmall),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${c.commits} commits',
                        style: theme.textTheme.labelSmall,
                      ),
                      Text(
                        '+${c.additions} -${c.deletions}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.inkFaint,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: colors.inkMuted),
        const SizedBox(width: Insets.xs),
        Text(
          '$value${label.isEmpty ? '' : ' $label'}',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: colors.inkMuted),
        ),
      ],
    );
    if (onTap == null) {
      return row;
    }
    return Tooltip(
      message: label.isEmpty ? value : label,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.borderSm,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.xs,
            vertical: Insets.xxs,
          ),
          child: row,
        ),
      ),
    );
  }
}

/// Latest default-branch pipeline as a header stat; hidden until it
/// loads and invisible when the project never ran one.
class _LatestPipelineStat extends ConsumerWidget {
  const _LatestPipelineStat({required this.projectId});

  final Object projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipeline = ref.watch(latestPipelineProvider(projectId)).value;
    if (pipeline == null) {
      return const SizedBox.shrink();
    }
    return Tooltip(
      message: 'Latest pipeline',
      child: InkWell(
        onTap: () => unawaited(
          context.push(Routes.projectPipeline(projectId, pipeline.id)),
        ),
        borderRadius: Radii.borderSm,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.xs,
            vertical: Insets.xxs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_tree_outlined,
                size: 15,
                color: context.colors.inkMuted,
              ),
              const SizedBox(width: Insets.xs),
              StateChip.pipeline(pipeline.status),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 36),
        foregroundColor: colors.ink,
        side: BorderSide(color: colors.border),
        padding: const EdgeInsets.symmetric(horizontal: Insets.md),
        textStyle: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

/// Paginated list of the project's visible forks.
class _ForksTab extends ConsumerWidget {
  const _ForksTab({required this.projectId});

  final Object projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(projectForksProvider(projectId));
    final notifier = ref.read(projectForksProvider(projectId).notifier);

    return AsyncValueWidget(
      value: state,
      onRetry: notifier.refresh,
      data: (data) => PagedListView(
        state: data,
        onLoadMore: notifier.loadMore,
        onRefresh: notifier.refresh,
        padding: const EdgeInsets.symmetric(vertical: Insets.sm),
        separator: Divider(height: 1, color: colors.border, indent: Insets.lg),
        empty: const EmptyState(icon: Icons.fork_right, title: 'No forks yet'),
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
