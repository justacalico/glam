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
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/core/widgets/search_field.dart';
import 'package:glam/src/core/widgets/state_chip.dart';
import 'package:glam/src/features/environments/application/environments_providers.dart';
import 'package:glam/src/features/environments/domain/environment.dart';

/// Environments tab on the project page.
class EnvironmentsScreen extends ConsumerStatefulWidget {
  const EnvironmentsScreen({required this.projectId, super.key});

  final Object projectId;

  @override
  ConsumerState<EnvironmentsScreen> createState() => _EnvironmentsScreenState();
}

class _EnvironmentsScreenState extends ConsumerState<EnvironmentsScreen> {
  String? _states;
  String? _search;

  static const _stateOptions = [
    (null, 'All'),
    ('available', 'Available'),
    ('stopped', 'Stopped'),
  ];

  @override
  Widget build(BuildContext context) {
    final filter = (
      project: widget.projectId,
      states: _states,
      search: _search,
    );
    final list = ref.watch(environmentsProvider(filter));
    final notifier = ref.read(environmentsProvider(filter).notifier);
    final colors = context.colors;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Insets.lg,
            Insets.sm,
            Insets.lg,
            0,
          ),
          child: SearchField(
            hint: 'Search environments',
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Insets.md,
            Insets.sm,
            Insets.md,
            0,
          ),
          child: Row(
            children: [
              const Spacer(),
              PopupMenuButton<String?>(
                tooltip: 'Filter environments',
                onSelected: (v) => setState(() => _states = v),
                itemBuilder: (context) => [
                  for (final (value, label) in _stateOptions)
                    CheckedPopupMenuItem(
                      value: value,
                      checked: _states == value,
                      child: Text(label),
                    ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Insets.sm,
                    vertical: Insets.sm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _stateOptions
                                .where((e) => e.$1 == _states)
                                .firstOrNull
                                ?.$2 ??
                            'All',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Icon(Icons.arrow_drop_down, color: colors.inkMuted),
                    ],
                  ),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New environment'),
                onPressed: () => _showCreate(context, ref),
              ),
            ],
          ),
        ),
        Expanded(
          child: AsyncValueWidget(
            value: list,
            onRetry: notifier.refresh,
            data: (data) => PagedListView(
              state: data,
              onLoadMore: notifier.loadMore,
              onRefresh: notifier.refresh,
              padding: const EdgeInsets.symmetric(vertical: Insets.sm),
              separator: Divider(height: 1, color: colors.border),
              empty: const EmptyState(
                icon: Icons.cloud_outlined,
                title: 'No environments',
                message: 'Deployments to staging, production, etc.',
              ),
              itemBuilder: (context, index) => _EnvironmentTile(
                env: data.items[index],
                projectId: widget.projectId,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showCreate(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final url = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New environment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: Insets.md),
            TextField(
              controller: url,
              decoration: const InputDecoration(
                labelText: 'External URL (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (saved == true && name.text.trim().isNotEmpty) {
      await ref
          .read(environmentsRepositoryProvider)
          .createEnvironment(
            widget.projectId,
            name: name.text.trim(),
            externalUrl: url.text.trim().isEmpty ? null : url.text.trim(),
          );
      ref.invalidate(environmentsProvider);
    }
  }
}

class _EnvironmentTile extends ConsumerWidget {
  const _EnvironmentTile({required this.env, required this.projectId});

  final GlEnvironment env;
  final Object projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final last = env.lastDeployment;

    return ListTile(
      leading: Icon(
        env.isAvailable ? Icons.cloud_outlined : Icons.cloud_off_outlined,
        color: env.isAvailable ? colors.success : colors.inkMuted,
      ),
      title: Text(env.name, style: theme.textTheme.titleSmall),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (last != null)
            Text(
              '#${last.iid} ${last.ref ?? ''} · '
              '${Format.relative(last.createdAt)}',
              style: theme.textTheme.bodySmall,
            ),
          Row(
            children: [
              StateChip(
                label: env.state,
                tone: env.isAvailable ? ChipTone.success : ChipTone.neutral,
              ),
              if (last?.status != null) ...[
                const SizedBox(width: Insets.sm),
                StateChip.pipeline(last!.status!),
              ],
            ],
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (env.externalUrl != null)
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 18),
              tooltip: 'Open live environment',
              onPressed: () => unawaited(launchExternal(env.externalUrl!)),
            ),
          PopupMenuButton<String>(
            onSelected: (action) async {
              final repo = ref.read(environmentsRepositoryProvider);
              switch (action) {
                case 'stop':
                  await repo.stop(projectId, env.id);
                  ref.invalidate(environmentsProvider);
                case 'delete':
                  final confirm = await _confirmDelete(context);
                  if (confirm == true) {
                    await repo.destroy(projectId, env.id);
                    ref.invalidate(environmentsProvider);
                  }
              }
            },
            itemBuilder: (context) => [
              if (env.isAvailable)
                const PopupMenuItem(value: 'stop', child: Text('Stop')),
              if (!env.isAvailable)
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete environment'),
                ),
            ],
          ),
        ],
      ),
      onTap: () =>
          unawaited(context.push(Routes.projectEnvironment(projectId, env.id))),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${env.name}?'),
        content: const Text('Stopped environments can be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
