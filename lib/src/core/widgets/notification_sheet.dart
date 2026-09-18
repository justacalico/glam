import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/widgets/error_view.dart';
import 'package:glam/src/features/account/application/account_providers.dart';
import 'package:glam/src/features/account/domain/account_models.dart';
import 'package:glam/l10n/app_localizations.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// A project or group id for scoped notification settings.
typedef NotificationScope = ({Object id, bool isProject});

/// Notification preferences for a project or group, shown as a bottom sheet.
class ScopedNotificationSheet extends ConsumerWidget {
  const ScopedNotificationSheet({required this.scope, super.key});

  final NotificationScope scope;

  static Future<void> show(BuildContext context, NotificationScope scope) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ScopedNotificationSheet(scope: scope),
        ),
      ),
    );
  }

  static Map<String, String> _eventLabels(AppLocalizations l10n) => {
    'new_note': l10n.notifNewNote,
    'new_issue': l10n.notifNewIssue,
    'reopen_issue': l10n.notifReopenIssue,
    'close_issue': l10n.notifCloseIssue,
    'reassign_issue': l10n.notifReassignIssue,
    'issue_due': l10n.notifIssueDue,
    'new_merge_request': l10n.notifNewMr,
    'push_to_merge_request': l10n.notifPushMr,
    'reopen_merge_request': l10n.notifReopenMr,
    'close_merge_request': l10n.notifCloseMr,
    'reassign_merge_request': l10n.notifReassignMr,
    'merge_merge_request': l10n.notifMergeMr,
    'failed_pipeline': l10n.notifFailedPipeline,
    'fixed_pipeline': l10n.notifFixedPipeline,
    'success_pipeline': l10n.notifSuccessPipeline,
    'moved_project': l10n.notifMovedProject,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(
      scope.isProject
          ? projectNotificationProvider(scope.id)
          : groupNotificationProvider(scope.id),
    );
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
              child: Text(
                context.l10n.notificationsTitle,
                style: theme.textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
              child: Row(
                children: [
                  Expanded(child: Text(context.l10n.notificationsLevel)),
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
              for (final e in _eventLabels(context.l10n).entries)
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
      final actions = ref.read(accountActionsProvider);
      if (scope.isProject) {
        await actions.setProjectNotificationLevel(scope.id, level);
      } else {
        await actions.setGroupNotificationLevel(scope.id, level);
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        _error(context, e.message);
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
      final actions = ref.read(accountActionsProvider);
      if (scope.isProject) {
        await actions.toggleProjectNotificationEvent(scope.id, event, on);
      } else {
        await actions.toggleGroupNotificationEvent(scope.id, event, on);
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        _error(context, e.message);
      }
    }
  }

  void _error(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
