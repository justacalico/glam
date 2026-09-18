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
import 'package:glam/src/features/activity/application/activity_providers.dart';
import 'package:glam/src/features/activity/domain/notification.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// Unread notifications with a mark-all-read action.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.notificationsTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.markAllRead,
            icon: const Icon(Icons.done_all, size: 20),
            onPressed: () => unawaited(notifier.markAllRead()),
          ),
        ],
      ),
      body: AsyncValueWidget(
        value: state,
        onRetry: notifier.refresh,
        data: (data) => PagedListView(
          state: data,
          onLoadMore: notifier.loadMore,
          onRefresh: notifier.refresh,
          padding: const EdgeInsets.symmetric(vertical: Insets.sm),
          separator: Divider(
            height: 1,
            color: colors.border,
            indent: Insets.lg,
          ),
          empty: EmptyState(
            icon: Icons.notifications_none,
            title: context.l10n.allCaughtUp,
          ),
          itemBuilder: (context, index) =>
              _NotificationTile(notification: data.items[index]),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final GlamNotification notification;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final route = notification.route;
    final icon = switch (notification.targetType) {
      'Issue' => Icons.radio_button_unchecked,
      'MergeRequest' => Icons.merge_type_outlined,
      _ => Icons.notifications_outlined,
    };
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 18, color: colors.inkMuted),
      title: Text(
        notification.targetTitle ?? '',
        style: theme.textTheme.titleSmall,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          notification.reasonLabel,
          if (notification.projectPath != null) notification.projectPath!,
          Format.relative(notification.createdAt),
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: route == null ? null : () => unawaited(context.push(route)),
    );
  }
}
