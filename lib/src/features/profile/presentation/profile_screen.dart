import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/utils/url_launcher.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/user_avatar.dart';
import 'package:glam/src/features/activity/presentation/activity_screen.dart';
import 'package:glam/src/features/auth/domain/user.dart';
import 'package:glam/src/features/profile/application/profile_providers.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/presentation/project_tile.dart';

/// Profile page for the current user or any user (`/users/:id`).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({required this.userId, super.key});

  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (user.value?.webUrl != null)
            IconButton(
              tooltip: 'Open in browser',
              icon: const Icon(Icons.open_in_new, size: 20),
              onPressed: () => unawaited(launchExternal(user.value!.webUrl!)),
            ),
        ],
      ),
      body: AsyncValueWidget(
        value: user,
        onRetry: () => ref.invalidate(userProvider(userId)),
        data: (u) => DefaultTabController(
          length: 3,
          child: Column(
            children: [
              _ProfileHeader(user: u),
              const TabBar(
                tabs: [
                  Tab(text: 'Projects'),
                  Tab(text: 'Starred'),
                  Tab(text: 'Activity'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _UserProjects(provider: userProjectsProvider(userId)),
                    _UserProjects(provider: userStarredProvider(userId)),
                    EventList(feed: (kind: 'user', id: userId)),
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final GitLabUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return Padding(
      padding: Insets.pagePadding,
      child: Column(
        children: [
          Row(
            children: [
              UserAvatar(
                name: user.name,
                avatarUrl: user.avatarUrl,
                radius: 30,
              ),
              const SizedBox(width: Insets.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: theme.textTheme.headlineSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.statusEmoji != null)
                          Padding(
                            padding: const EdgeInsets.only(left: Insets.sm),
                            child: Text(user.statusEmoji!),
                          ),
                      ],
                    ),
                    Text(
                      '@${user.username}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.inkMuted,
                      ),
                    ),
                    if (user.statusMessage != null)
                      Text(
                        user.statusMessage!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (user.bio?.isNotEmpty ?? false) ...[
            const SizedBox(height: Insets.md),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(user.bio!, style: theme.textTheme.bodyMedium),
            ),
          ],
          const SizedBox(height: Insets.md),
          Wrap(
            spacing: Insets.lg,
            runSpacing: Insets.sm,
            children: [
              if (user.location != null)
                _Meta(icon: Icons.place_outlined, text: user.location!),
              if (user.publicEmail != null)
                _Meta(icon: Icons.mail_outline, text: user.publicEmail!),
              if (user.createdAt != null)
                _Meta(
                  icon: Icons.cake_outlined,
                  text: 'Joined ${Format.date(user.createdAt)}',
                ),
              if (user.followers != null)
                _Meta(
                  icon: Icons.people_outline,
                  text: '${user.followers} followers',
                ),
              if (user.following != null)
                _Meta(
                  icon: Icons.person_add_outlined,
                  text: '${user.following} following',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colors.inkFaint),
        const SizedBox(width: Insets.xs),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _UserProjects extends ConsumerWidget {
  const _UserProjects({required this.provider});

  final FutureProvider<List<Project>> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final projects = ref.watch(provider);
    return AsyncValueWidget(
      value: projects,
      onRetry: () => ref.invalidate(provider),
      data: (items) => items.isEmpty
          ? const EmptyState(icon: Icons.folder_outlined, title: 'No projects')
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: Insets.sm),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: colors.border, indent: Insets.lg),
              itemBuilder: (context, index) => ProjectTile(
                project: items[index],
                onTap: () =>
                    unawaited(context.push(Routes.project(items[index].id))),
              ),
            ),
    );
  }
}
