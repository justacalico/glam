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
import 'package:glam/src/core/utils/l10n.dart';

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
        title: Text(context.l10n.profile),
        actions: [
          if (isSelf && user.value != null)
            IconButton(
              tooltip: context.l10n.editProfile,
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => unawaited(
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (_) => _EditProfileSheet(user: user.value!),
                ),
              ),
            ),
          if (user.value?.webUrl != null)
            IconButton(
              tooltip: context.l10n.actionOpenBrowser,
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
              TabBar(
                tabs: [
                  Tab(text: context.l10n.projectsTitle),
                  Tab(text: context.l10n.snackStarred),
                  Tab(text: context.l10n.activityTitle),
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
                  text: context.l10n.joinedP0(Format.date(user.createdAt)),
                ),
              if (user.followers != null)
                _Meta(
                  icon: Icons.people_outline,
                  text: context.l10n.p0Followers('${user.followers}'),
                  onTap: () => _usersSheet(context, user.id, followers: true),
                ),
              if (user.following != null)
                _Meta(
                  icon: Icons.person_add_outlined,
                  text: context.l10n.p0Following('${user.following}'),
                  onTap: () => _usersSheet(context, user.id, followers: false),
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
            const SizedBox(height: Insets.lg),
            const _MembershipsSection(),
          ],
        ],
      ),
    );
  }

  void _usersSheet(
    BuildContext context,
    int userId, {
    required bool followers,
  }) {
    unawaited(
      UsersSheet.show(
        context,
        title: followers ? context.l10n.followers : context.l10n.following,
        provider: followers
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
      label: Text(following ? context.l10n.unfollow : context.l10n.follow),
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
              context.l10n.p0ContributionsInTheLastYear(total),
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
    for (final e in _entries(context.l10n))
      e.$1: TextEditingController(text: e.$2(widget.user) ?? ''),
  };
  late final TextEditingController _statusEmoji = TextEditingController(
    text: widget.user.statusEmoji ?? '',
  );
  late final TextEditingController _statusMessage = TextEditingController(
    text: widget.user.statusMessage ?? '',
  );
  bool _busy = false;

  static List<(String, String? Function(GitLabUser), String)> _entries(
    AppLocalizations l10n,
  ) => [
    ('name', _name, l10n.fieldName),
    ('pronouns', _pronouns, l10n.fieldPronouns),
    ('job_title', _jobTitle, l10n.fieldJobTitle),
    ('organization', _organization, l10n.fieldOrganization),
    ('location', _location, l10n.fieldLocation),
    ('public_email', _publicEmail, l10n.fieldPublicEmail),
    ('website_url', _websiteUrl, l10n.fieldWebsite),
    ('twitter', _twitter, l10n.fieldTwitter),
    ('linkedin', _linkedin, l10n.fieldLinkedin),
    ('bio', _bio, l10n.fieldBio),
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
                context.l10n.editProfile,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: Insets.md),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _statusEmoji,
                      decoration: InputDecoration(
                        labelText: context.l10n.statusEmoji,
                        hintText: context.l10n.eG,
                      ),
                    ),
                  ),
                  const SizedBox(width: Insets.sm),
                  Expanded(
                    flex: 5,
                    child: TextField(
                      controller: _statusMessage,
                      decoration: InputDecoration(
                        labelText: context.l10n.statusMessage,
                      ),
                    ),
                  ),
                ],
              ),
              for (final e in _entries(context.l10n))
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
                    child: Text(context.l10n.actionCancel),
                  ),
                  const SizedBox(width: Insets.sm),
                  FilledButton(
                    onPressed: _busy ? null : () => unawaited(_save()),
                    child: _busy
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.l10n.actionSave),
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
          ? EmptyState(
              icon: Icons.folder_outlined,
              title: context.l10n.projectsEmpty,
            )
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

/// Groups and projects the signed-in account belongs to
/// (`/user/memberships`). Shown on own profile only.
class _MembershipsSection extends ConsumerWidget {
  const _MembershipsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberships = ref.watch(myMembershipsProvider);
    final theme = Theme.of(context);
    final colors = context.colors;

    return memberships.maybeWhen(
      data: (items) {
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.memberships, style: theme.textTheme.titleMedium),
            const SizedBox(height: Insets.sm),
            for (final m in items)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  m.sourceType == 'Project'
                      ? Icons.folder_outlined
                      : Icons.group_outlined,
                  size: 18,
                  color: colors.inkFaint,
                ),
                title: Text(m.sourceName),
                subtitle: Text(
                  [
                    context.l10n.accessLevelName(m.accessLevel),
                    if (m.expiresAt != null)
                      context.l10n.expiresDate(Format.date(m.expiresAt!)),
                  ].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.inkFaint,
                  ),
                ),
                onTap: () => unawaited(
                  context.push(
                    m.sourceType == 'Project'
                        ? Routes.project(m.sourceId)
                        : Routes.group(m.sourceId),
                  ),
                ),
              ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
