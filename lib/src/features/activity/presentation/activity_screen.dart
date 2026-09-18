import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/core/widgets/user_avatar.dart';
import 'package:glam/src/features/activity/application/activity_providers.dart';
import 'package:glam/src/features/activity/domain/event.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// The user's activity feed.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.activityTitle)),
      body: const EventList(feed: ownFeed),
    );
  }
}

/// Paged event list. Reused on the activity tab, project activity, and
/// user profiles.
class EventList extends ConsumerWidget {
  const EventList({required this.feed, super.key});

  final EventFeed feed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(activityProvider(feed));
    final notifier = ref.read(activityProvider(feed).notifier);

    return AsyncValueWidget(
      value: state,
      onRetry: notifier.refresh,
      data: (data) => PagedListView(
        state: data,
        onLoadMore: notifier.loadMore,
        onRefresh: notifier.refresh,
        padding: const EdgeInsets.symmetric(vertical: Insets.sm),
        separator: Divider(height: 1, color: colors.border, indent: Insets.lg),
        empty: EmptyState(
          icon: Icons.bolt_outlined,
          title: context.l10n.noActivityYet,
        ),
        itemBuilder: (context, index) => EventTile(event: data.items[index]),
      ),
    );
  }
}

/// One feed row: avatar, "who did what", and time.
class EventTile extends StatelessWidget {
  const EventTile({required this.event, super.key});

  final ActivityEvent event;

  IconData get _icon => switch (event.actionName) {
    'pushed to' || 'pushed new' => Icons.commit,
    'created' => Icons.add_circle_outline,
    'closed' => Icons.check_circle_outline,
    'merged' => Icons.merge,
    'commented on' => Icons.mode_comment_outlined,
    'opened' => Icons.radio_button_unchecked,
    'accepted' => Icons.check,
    'deleted' => Icons.delete_outline,
    _ => Icons.bolt_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final route = event.route;
    return InkWell(
      onTap: route == null ? null : () => unawaited(context.push(route)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.lg,
          vertical: Insets.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAvatar(
              name: event.author?.name ?? '?',
              avatarUrl: event.author?.avatarUrl,
              radius: 14,
            ),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_icon, size: 14, color: colors.inkMuted),
                      const SizedBox(width: Insets.xs),
                      Expanded(
                        child: Text(
                          event.describe(),
                          style: theme.textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (event.note?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: Insets.xs),
                      child: Text(
                        event.note!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      Format.relative(event.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.inkFaint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
