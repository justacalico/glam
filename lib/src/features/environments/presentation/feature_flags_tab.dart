import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/features/environments/application/environments_providers.dart';
import 'package:glam/src/features/environments/domain/feature_flag.dart';

/// Feature flags tab on the project page: toggle or delete each flag.
class FeatureFlagsTab extends ConsumerWidget {
  const FeatureFlagsTab({required this.projectId, super.key});

  final Object projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(featureFlagsProvider(projectId));
    final colors = context.colors;

    return AsyncValueWidget<List<FeatureFlag>>(
      value: flags,
      onRetry: () => ref.invalidate(featureFlagsProvider(projectId)),
      data: (items) => items.isEmpty
          ? const EmptyState(
              icon: Icons.flag_outlined,
              title: 'No feature flags',
            )
          : RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(featureFlagsProvider(projectId)),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: Insets.sm),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: colors.border),
                itemBuilder: (context, i) => _FlagTile(
                  flag: items[i],
                  onToggle: (v) => _toggle(context, ref, items[i], v),
                  onDelete: () => _confirmDelete(context, ref, items[i]),
                ),
              ),
            ),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    FeatureFlag flag,
    bool active,
  ) async {
    try {
      await ref
          .read(environmentsRepositoryProvider)
          .updateFeatureFlag(projectId, flag.name, active: active);
      ref.invalidate(featureFlagsProvider(projectId));
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    FeatureFlag flag,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${flag.name}?'),
        content: const Text('The flag is removed from every environment.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(environmentsRepositoryProvider)
          .deleteFeatureFlag(projectId, flag.name);
      ref.invalidate(featureFlagsProvider(projectId));
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _FlagTile extends StatelessWidget {
  const _FlagTile({
    required this.flag,
    required this.onToggle,
    required this.onDelete,
  });

  final FeatureFlag flag;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final scopes = flag.scopes.map((s) => s.environmentScope).join(', ');
    return ListTile(
      leading: Icon(
        flag.active ? Icons.flag : Icons.outlined_flag,
        size: 20,
        color: flag.active ? colors.success : colors.inkFaint,
      ),
      title: Text(flag.name, style: theme.textTheme.bodyMedium),
      subtitle: Text(
        [
          if (flag.description.isNotEmpty) flag.description,
          if (scopes.isNotEmpty) scopes,
        ].join(' · '),
        style: theme.textTheme.bodySmall?.copyWith(color: colors.inkFaint),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(value: flag.active, onChanged: onToggle),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
