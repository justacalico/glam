import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/utils/url_launcher.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/user_avatar.dart';
import 'package:glam/src/core/widgets/users_sheet.dart';
import 'package:glam/src/features/activity/application/activity_providers.dart';
import 'package:glam/src/features/activity/presentation/activity_screen.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
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
    final isSelf = ref.watch(sessionProvider).value?.user.id == userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (isSelf && user.value != null)
            IconButton(
              tooltip: 'Edit profile',
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => unawaited(
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => _EditProfileSheet(user: user.value!),
                ),
              ),
            ),
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
              _ProfileHeader(user: u, isSelf: isSelf),
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
  const _ProfileHeader({required this.user, required this.isSelf});

  final GitLabUser user;
  final bool isSelf;

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
                    if (user.jobTitle != null || user.organization != null)
                      Text(
                        [?user.jobTitle, ?user.organization].join(' at '),
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
              if (user.pronouns != null)
                _Meta(icon: Icons.badge_outlined, text: user.pronouns!),
              if (user.publicEmail != null)
                _Meta(icon: Icons.mail_outline, text: user.publicEmail!),
              if (user.websiteUrl != null)
                _Meta(icon: Icons.link, text: user.websiteUrl!),
              if (user.createdAt != null)
                _Meta(
                  icon: Icons.cake_outlined,
                  text: 'Joined ${Format.date(user.createdAt)}',
                ),
              if (user.followers != null)
                _Meta(
                  icon: Icons.people_outline,
                  text: '${user.followers} followers',
                  onTap: () => _usersSheet(context, user.id, 'Followers'),
                ),
              if (user.following != null)
                _Meta(
                  icon: Icons.person_add_outlined,
                  text: '${user.following} following',
                  onTap: () => _usersSheet(context, user.id, 'Following'),
                ),
            ],
          ),
          if (!isSelf) ...[
            const SizedBox(height: Insets.md),
            Align(
              alignment: Alignment.centerLeft,
              child: _FollowButton(userId: user.id),
            ),
          ],
          if (isSelf) ...[
            const SizedBox(height: Insets.lg),
            const _ContributionHeatmap(),
          ],
        ],
      ),
    );
  }

  void _usersSheet(BuildContext context, int userId, String title) {
    unawaited(
      UsersSheet.show(
        context,
        title: title,
        provider: title == 'Followers'
            ? userFollowersProvider(userId)
            : userFollowingProvider(userId),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, this.onTap});

  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colors.inkFaint),
        const SizedBox(width: Insets.xs),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
    if (onTap == null) {
      return row;
    }
    return InkWell(onTap: onTap, child: row);
  }
}

/// Follows or unfollows [userId], based on `myFollowedProvider`.
class _FollowButton extends ConsumerWidget {
  const _FollowButton({required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followed = ref.watch(myFollowedProvider);
    final following = followed.value?.contains(userId) ?? false;
    return OutlinedButton.icon(
      icon: Icon(
        following ? Icons.person_remove_outlined : Icons.person_add_outlined,
        size: 16,
      ),
      label: Text(following ? 'Unfollow' : 'Follow'),
      onPressed: followed.value == null
          ? null
          : () => _toggle(context, ref, following),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    bool following,
  ) async {
    try {
      final repo = ref.read(authRepositoryProvider);
      if (following) {
        await repo.unfollowUser(userId);
      } else {
        await repo.followUser(userId);
      }
      ref
        ..invalidate(myFollowedProvider)
        ..invalidate(userProvider(userId));
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

/// GitHub-style contribution heatmap for the signed-in user
/// (`/user/activities` only covers the current account).
class _ContributionHeatmap extends ConsumerWidget {
  const _ContributionHeatmap();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(userActivitiesProvider);
    final colors = context.colors;
    final theme = Theme.of(context);

    return days.maybeWhen(
      data: (counts) {
        if (counts.isEmpty) {
          return const SizedBox.shrink();
        }
        final today = clock.now();
        final end = DateTime(today.year, today.month, today.day);
        // 53 columns: 52 full weeks plus the current partial week.
        // `weekday % 7` maps Sunday to 0 so the grid starts on a Sunday.
        final start = end.subtract(Duration(days: end.weekday % 7 + 52 * 7));
        final total = counts.values.fold(0, (a, b) => a + b);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$total contributions in the last year',
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: Insets.sm),
            SizedBox(
              height: 7 * 9,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                children: [
                  for (var w = 0; w < 53; w++)
                    Column(
                      children: [
                        for (var d = 0; d < 7; d++)
                          _Cell(
                            color: _cellColor(
                              colors,
                              counts[start.add(Duration(days: w * 7 + d))] ?? 0,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Color _cellColor(GlamColors colors, int count) {
    if (count <= 0) {
      return colors.surfaceMuted;
    }
    final opacity = switch (count) {
      < 3 => 0.35,
      < 6 => 0.6,
      < 10 => 0.8,
      _ => 1.0,
    };
    return colors.accent.withValues(alpha: opacity);
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}

/// Editable profile fields plus the emoji status. Lives in a bottom
/// sheet opened from the profile header's edit button.
class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.user});

  final GitLabUser user;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final Map<String, TextEditingController> _fields = {
    for (final e in _entries)
      e.$1: TextEditingController(text: e.$2(widget.user) ?? ''),
  };
  late final TextEditingController _statusEmoji = TextEditingController(
    text: widget.user.statusEmoji ?? '',
  );
  late final TextEditingController _statusMessage = TextEditingController(
    text: widget.user.statusMessage ?? '',
  );
  bool _busy = false;

  static const List<(String, String? Function(GitLabUser), String)> _entries = [
    ('name', _name, 'Name'),
    ('pronouns', _pronouns, 'Pronouns'),
    ('job_title', _jobTitle, 'Job title'),
    ('organization', _organization, 'Organization'),
    ('location', _location, 'Location'),
    ('public_email', _publicEmail, 'Public email'),
    ('website_url', _websiteUrl, 'Website'),
    ('twitter', _twitter, 'Twitter'),
    ('linkedin', _linkedin, 'LinkedIn'),
    ('bio', _bio, 'Bio'),
  ];

  static String? _name(GitLabUser u) => u.name;
  static String? _pronouns(GitLabUser u) => u.pronouns;
  static String? _jobTitle(GitLabUser u) => u.jobTitle;
  static String? _organization(GitLabUser u) => u.organization;
  static String? _location(GitLabUser u) => u.location;
  static String? _publicEmail(GitLabUser u) => u.publicEmail;
  static String? _websiteUrl(GitLabUser u) => u.websiteUrl;
  static String? _twitter(GitLabUser u) => u.twitter;
  static String? _linkedin(GitLabUser u) => u.linkedin;
  static String? _bio(GitLabUser u) => u.bio;

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    _statusEmoji.dispose();
    _statusMessage.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    String text(String key) => _fields[key]!.text.trim();
    try {
      final repo = ref.read(authRepositoryProvider);
      if (_statusEmoji.text.trim() != (widget.user.statusEmoji ?? '') ||
          _statusMessage.text.trim() != (widget.user.statusMessage ?? '')) {
        await repo.updateStatus(
          emoji: _statusEmoji.text.trim(),
          message: _statusMessage.text.trim(),
        );
      }
      final updated = await repo.updateProfile(
        name: text('name'),
        bio: text('bio'),
        location: text('location'),
        publicEmail: text('public_email'),
        websiteUrl: text('website_url'),
        pronouns: text('pronouns'),
        organization: text('organization'),
        jobTitle: text('job_title'),
        twitter: text('twitter'),
        linkedin: text('linkedin'),
      );
      ref.read(sessionProvider.notifier).updateUser(updated);
      ref.invalidate(userProvider(widget.user.id));
      if (mounted) {
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: Insets.lg,
          right: Insets.lg,
          top: Insets.lg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + Insets.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit profile',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: Insets.md),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _statusEmoji,
                      decoration: const InputDecoration(
                        labelText: 'Status emoji',
                        hintText: 'e.g. 🌴',
                      ),
                    ),
                  ),
                  const SizedBox(width: Insets.sm),
                  Expanded(
                    flex: 5,
                    child: TextField(
                      controller: _statusMessage,
                      decoration: const InputDecoration(
                        labelText: 'Status message',
                      ),
                    ),
                  ),
                ],
              ),
              for (final e in _entries)
                Padding(
                  padding: const EdgeInsets.only(top: Insets.sm),
                  child: TextField(
                    controller: _fields[e.$1],
                    decoration: InputDecoration(labelText: e.$3),
                  ),
                ),
              const SizedBox(height: Insets.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: Insets.sm),
                  FilledButton(
                    onPressed: _busy ? null : () => unawaited(_save()),
                    child: _busy
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
