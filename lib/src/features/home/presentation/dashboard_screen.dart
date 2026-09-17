import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/widgets/user_avatar.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/profile/application/profile_providers.dart';

/// Landing screen: greeting, quick stats, and shortcuts into the main
/// sections.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value;
    final counts = ref.watch(myCountsProvider).value;
    final colors = context.colors;
    final theme = Theme.of(context);
    final user = session?.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined, size: 20),
            onPressed: () => context.push(Routes.notifications),
          ),
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: Insets.md),
              child: InkWell(
                borderRadius: Radii.borderPill,
                onTap: () => context.push(Routes.profile),
                child: UserAvatar(
                  name: user.name,
                  avatarUrl: user.avatarUrl,
                  radius: 16,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: Insets.pagePadding,
        children: [
          const _BroadcastBanner(),
          if (user != null) ...[
            Text(
              _greeting(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.inkMuted,
              ),
            ),
            Text(user.name, style: theme.textTheme.displaySmall),
            const SizedBox(height: Insets.xl),
          ],
          _ShortcutGrid(
            items: [
              _Shortcut(
                icon: Icons.folder_outlined,
                label: 'Projects',
                subtitle: 'Browse your work',
                onTap: () => context.go(Routes.projects),
              ),
              _Shortcut(
                icon: Icons.merge,
                label: 'Merge requests',
                subtitle: 'Review and merge',
                count: counts?.mrBadge,
                onTap: () => context.go(Routes.mergeRequests),
              ),
              _Shortcut(
                icon: Icons.adjust,
                label: 'Issues',
                subtitle: 'Assigned to you',
                count: counts?.assignedIssues,
                onTap: () => context.go(Routes.issues),
              ),
              _Shortcut(
                icon: Icons.checklist,
                label: 'To-dos',
                subtitle: 'Your task list',
                count: counts?.todos,
                onTap: () => context.go(Routes.todos),
              ),
              _Shortcut(
                icon: Icons.search,
                label: 'Search',
                subtitle: 'Across the instance',
                onTap: () => context.go(Routes.search),
              ),
              _Shortcut(
                icon: Icons.history,
                label: 'Activity',
                subtitle: 'What happened lately',
                onTap: () => context.go(Routes.activity),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = clock.now().hour;
    if (hour < 12) {
      return 'Good morning,';
    }
    if (hour < 18) {
      return 'Good afternoon,';
    }
    return 'Good evening,';
  }
}

/// Instance announcements (`/broadcast_messages`) above the greeting.
class _BroadcastBanner extends ConsumerStatefulWidget {
  const _BroadcastBanner();

  @override
  ConsumerState<_BroadcastBanner> createState() => _BroadcastBannerState();
}

class _BroadcastBannerState extends ConsumerState<_BroadcastBanner> {
  final _dismissed = <int>{};

  void _dismiss(int id) {
    setState(() => _dismissed.add(id));
    unawaited(
      ref
          .read(authRepositoryProvider)
          .dismissBroadcastMessage(id)
          .onError((_, _) {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(broadcastMessagesProvider).value ?? [];
    final colors = context.colors;
    final theme = Theme.of(context);
    final visible = messages
        .where(
          (m) =>
              m.active && !_dismissed.contains(m.id) && m.plainText.isNotEmpty,
        )
        .toList();
    if (visible.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        for (final m in visible)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: Insets.md),
            padding: const EdgeInsets.all(Insets.md),
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.12),
              borderRadius: Radii.borderMd,
              border: Border.all(color: colors.accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.campaign_outlined, size: 18, color: colors.accent),
                const SizedBox(width: Insets.sm),
                Expanded(
                  child: Text(m.plainText, style: theme.textTheme.bodySmall),
                ),
                if (m.dismissable)
                  GestureDetector(
                    onTap: () => _dismiss(m.id),
                    child: Icon(Icons.close, size: 16, color: colors.inkMuted),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Shortcut {
  const _Shortcut({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.count,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  /// Badge count from `/user/counts`; hidden when zero or unset.
  final int? count;
}

class _ShortcutGrid extends StatelessWidget {
  const _ShortcutGrid({required this.items});

  final List<_Shortcut> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 720
            ? 3
            : constraints.maxWidth > 460
            ? 2
            : 1;
        return Wrap(
          spacing: Insets.md,
          runSpacing: Insets.md,
          children: [
            for (final item in items)
              SizedBox(
                width:
                    (constraints.maxWidth - (columns - 1) * Insets.md) /
                    columns,
                child: Material(
                  color: colors.surface,
                  borderRadius: Radii.borderMd,
                  child: InkWell(
                    onTap: item.onTap,
                    borderRadius: Radii.borderMd,
                    child: Container(
                      padding: const EdgeInsets.all(Insets.lg),
                      decoration: BoxDecoration(
                        borderRadius: Radii.borderMd,
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colors.accentSoft,
                              borderRadius: Radii.borderMd,
                            ),
                            child: Icon(
                              item.icon,
                              color: colors.accent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: Insets.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.label,
                                  style: theme.textTheme.titleMedium,
                                ),
                                Text(
                                  item.subtitle,
                                  style: theme.textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (item.count != null && item.count! > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Insets.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colors.accentSoft,
                                borderRadius: Radii.borderPill,
                              ),
                              child: Text(
                                '${item.count}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colors.accent,
                                ),
                              ),
                            ),
                          const SizedBox(width: Insets.xs),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: colors.inkFaint,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
