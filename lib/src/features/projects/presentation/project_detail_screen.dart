import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/utils/url_launcher.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/features/issues/presentation/issues_screen.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/presentation/project_overview_tab.dart';
import 'package:glam/src/features/repository/presentation/branches_screen.dart';
import 'package:glam/src/features/repository/presentation/commits_screen.dart';
import 'package:glam/src/features/repository/presentation/files_screen.dart';
import 'package:glam/src/features/repository/presentation/releases_screen.dart';
import 'package:glam/src/features/repository/presentation/tags_screen.dart';

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
      padding: Insets.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatar(colors),
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
                    Text(project.name, style: theme.textTheme.headlineMedium),
                  ],
                ),
              ),
            ],
          ),
          if (project.description?.isNotEmpty ?? false) ...[
            const SizedBox(height: Insets.md),
            Text(project.description!, style: theme.textTheme.bodyMedium),
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
            ],
          ),
          const SizedBox(height: Insets.md),
          Wrap(
            spacing: Insets.sm,
            children: [
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
              if (project.webUrl != null)
                _ActionChip(
                  icon: Icons.open_in_new,
                  label: 'Open in browser',
                  onTap: () => launchExternal(project.webUrl!),
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

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
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
