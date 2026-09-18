import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/utils/extensions.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/filter_menu.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/core/widgets/state_chip.dart';
import 'package:glam/src/features/alerts/application/alerts_providers.dart';
import 'package:glam/src/features/alerts/domain/alert.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// Monitor > Alerts for a project.
class AlertsTab extends ConsumerStatefulWidget {
  const AlertsTab({required this.projectId, super.key});

  final Object projectId;

  @override
  ConsumerState<AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends ConsumerState<AlertsTab> {
  String? _status;

  static const _statuses = ['triggered', 'acknowledged', 'resolved', 'ignored'];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filter = (project: widget.projectId, status: _status);
    final state = ref.watch(projectAlertsProvider(filter));
    final notifier = ref.read(projectAlertsProvider(filter).notifier);

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.lg,
              Insets.sm,
              Insets.lg,
              0,
            ),
            child: FilterMenu(
              title: context.l10n.status,
              current: _status,
              options: _statuses,
              onSelect: (v) => setState(() => _status = v),
            ),
          ),
        ),
        Expanded(
          child: AsyncValueWidget(
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
                title: context.l10n.noAlerts,
                message: context.l10n.alertsFromPrometheusAndOtherTools,
              ),
              itemBuilder: (context, index) =>
                  _AlertTile(alert: data.items[index], filter: filter),
            ),
          ),
        ),
      ],
    );
  }
}

class _AlertTile extends ConsumerWidget {
  const _AlertTile({required this.alert, required this.filter});

  final Alert alert;
  final AlertFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return ListTile(
      leading: Icon(
        _severityIcon(alert.severity),
        color: _severityColor(colors),
      ),
      title: Text(alert.title),
      subtitle: Text(
        [
          if (alert.monitoringTool != null) alert.monitoringTool!,
          if (alert.startedAt != null) Format.dateTime(alert.startedAt!),
          if (alert.eventCount > 0) '${alert.eventCount} events',
        ].join(' · '),
      ),
      trailing: PopupMenuButton<String>(
        tooltip: context.l10n.setStatus,
        onSelected: (v) => unawaited(
          ref
              .read(projectAlertsProvider(filter).notifier)
              .setStatus(alert.iid, v),
        ),
        itemBuilder: (context) => [
          for (final s in _AlertsTabState._statuses)
            CheckedPopupMenuItem(
              value: s,
              checked: alert.status == s,
              child: Text(s),
            ),
        ],
        child: _statusChip(alert.status),
      ),
      onTap: () => _showDetail(context, ref),
    );
  }

  IconData _severityIcon(String? severity) => switch (severity) {
    'critical' => Icons.error,
    'high' => Icons.warning_amber,
    'medium' || 'low' => Icons.warning_amber_outlined,
    _ => Icons.info_outline,
  };

  Color _severityColor(GlamColors colors) => switch (alert.severity) {
    'critical' || 'high' => colors.danger,
    'medium' => colors.warning,
    _ => colors.inkMuted,
  };

  StateChip _statusChip(String value) => StateChip(
    label: value.capitalized,
    tone: switch (value) {
      'triggered' || 'critical' || 'high' => ChipTone.danger,
      'acknowledged' || 'medium' => ChipTone.warning,
      'resolved' => ChipTone.success,
      _ => ChipTone.neutral,
    },
  );

  void _showDetail(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.lg,
              0,
              Insets.lg,
              Insets.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title, style: theme.textTheme.titleMedium),
                SizedBox(height: Insets.sm),
                Wrap(
                  spacing: Insets.sm,
                  runSpacing: Insets.xs,
                  children: [
                    _statusChip(alert.status),
                    if (alert.severity != null) _statusChip(alert.severity!),
                  ],
                ),
                SizedBox(height: Insets.md),
                for (final row in [
                  if (alert.monitoringTool != null)
                    (context.l10n.alertTool, alert.monitoringTool!),
                  if (alert.service != null)
                    (context.l10n.alertService, alert.service!),
                  if (alert.startedAt != null)
                    (
                      context.l10n.alertStarted,
                      Format.dateTime(alert.startedAt!),
                    ),
                  if (alert.endedAt != null)
                    (context.l10n.alertEnded, Format.dateTime(alert.endedAt!)),
                  if (alert.eventCount > 0)
                    (context.l10n.alertEvents, '${alert.eventCount}'),
                  if (alert.hosts.isNotEmpty)
                    (context.l10n.alertHosts, alert.hosts.join(', ')),
                  if (alert.assignees.isNotEmpty)
                    (
                      context.l10n.fieldAssignees,
                      alert.assignees.map((u) => u.name).join(', '),
                    ),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: Insets.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text(
                            row.$1,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: context.colors.inkMuted,
                            ),
                          ),
                        ),
                        Expanded(child: Text(row.$2)),
                      ],
                    ),
                  ),
                if (alert.issueIid != null) ...[
                  SizedBox(height: Insets.sm),
                  TextButton.icon(
                    icon: Icon(Icons.task_alt, size: 16),
                    label: Text(
                      context.l10n.linkedIssueP0('${alert.issueIid}'),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      unawaited(
                        context.push(
                          Routes.projectIssue(filter.project, alert.issueIid!),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
