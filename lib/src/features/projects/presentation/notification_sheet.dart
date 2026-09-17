import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/widgets/error_view.dart';
import 'package:glam/src/features/account/application/account_providers.dart';
import 'package:glam/src/features/account/domain/account_models.dart';
import 'package:glam/src/features/projects/presentation/admin_helpers.dart';

/// Project-scoped notification preferences shown as a bottom sheet.
class ProjectNotificationSheet extends ConsumerWidget {
  const ProjectNotificationSheet({required this.projectId, super.key});

  final Object projectId;

  static Future<void> show(BuildContext context, Object projectId) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ProjectNotificationSheet(projectId: projectId),
        ),
      ),
    );
  }

  static const _eventLabels = {
    'new_note': 'New comments',
    'new_issue': 'New issues',
    'reopen_issue': 'Reopened issues',
    'close_issue': 'Closed issues',
    'reassign_issue': 'Reassigned issues',
    'issue_due': 'Issue due dates',
    'new_merge_request': 'New merge requests',
    'push_to_merge_request': 'Pushes to merge requests',
    'reopen_merge_request': 'Reopened merge requests',
    'close_merge_request': 'Closed merge requests',
    'reassign_merge_request': 'Reassigned merge requests',
    'merge_merge_request': 'Merged merge requests',
    'failed_pipeline': 'Failed pipelines',
    'fixed_pipeline': 'Fixed pipelines',
    'success_pipeline': 'Successful pipelines',
    'moved_project': 'Moved project',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(projectNotificationProvider(projectId));
    final theme = Theme.of(context);

    return settings.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: ErrorView(error: e),
      ),
      data: (s) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
              child: Text('Notifications', style: theme.textTheme.titleMedium),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
              child: Row(
                children: [
                  const Expanded(child: Text('Level')),
                  DropdownButton<String>(
                    value: NotificationSettings.levelLabels.containsKey(s.level)
                        ? s.level
                        : 'global',
                    underline: const SizedBox.shrink(),
                    style: theme.textTheme.bodyMedium,
                    items: [
                      for (final e in NotificationSettings.levelLabels.entries)
                        DropdownMenuItem(value: e.key, child: Text(e.value)),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        unawaited(_setLevel(context, ref, v));
                      }
                    },
                  ),
                ],
              ),
            ),
            if (s.level == 'custom')
              for (final e in _eventLabels.entries)
                SwitchListTile(
                  dense: true,
                  title: Text(e.value),
                  value: s.events[e.key] ?? false,
                  onChanged: (v) =>
                      unawaited(_toggleEvent(context, ref, e.key, v)),
                ),
            const SizedBox(height: Insets.md),
          ],
        ),
      ),
    );
  }

  Future<void> _setLevel(
    BuildContext context,
    WidgetRef ref,
    String level,
  ) async {
    try {
      await ref
          .read(accountActionsProvider)
          .setProjectNotificationLevel(projectId, level);
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }

  Future<void> _toggleEvent(
    BuildContext context,
    WidgetRef ref,
    String event,
    bool on,
  ) async {
    try {
      await ref
          .read(accountActionsProvider)
          .toggleProjectNotificationEvent(projectId, event, on);
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }
}
