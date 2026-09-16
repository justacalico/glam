import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/features/repository/application/repository_providers.dart';
import 'package:glam/src/features/repository/domain/repo_models.dart';

/// Branch list with default/protected indicators.
class BranchesScreen extends ConsumerWidget {
  const BranchesScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(branchesProvider(projectId));
    final notifier = ref.read(branchesProvider(projectId).notifier);

    return AsyncValueWidget(
      value: state,
      onRetry: notifier.refresh,
      data: (data) => PagedListView(
        state: data,
        onLoadMore: notifier.loadMore,
        onRefresh: notifier.refresh,
        separator: Divider(
          height: 1,
          color: colors.border,
          indent: Insets.lg,
          endIndent: Insets.lg,
        ),
        padding: const EdgeInsets.symmetric(vertical: Insets.sm),
        empty: const EmptyState(
          icon: Icons.account_tree_outlined,
          title: 'No branches',
        ),
        itemBuilder: (context, index) => _BranchTile(branch: data.items[index]),
      ),
    );
  }
}

class _BranchTile extends StatelessWidget {
  const _BranchTile({required this.branch});

  final Branch branch;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.lg,
        vertical: Insets.md,
      ),
      child: Row(
        children: [
          Icon(Icons.account_tree_outlined, size: 18, color: colors.inkMuted),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        branch.name,
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (branch.isDefault) ...[
                      const SizedBox(width: Insets.sm),
                      _Pill(text: 'default', color: colors.accent),
                    ],
                    if (branch.protected) ...[
                      const SizedBox(width: Insets.sm),
                      _Pill(text: 'protected', color: colors.warning),
                    ],
                    if (branch.merged) ...[
                      const SizedBox(width: Insets.sm),
                      _Pill(text: 'merged', color: colors.inkMuted),
                    ],
                  ],
                ),
                if (branch.commitTitle != null)
                  Text(
                    branch.commitTitle!,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: Insets.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                branch.shortSha,
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11.5,
                ),
              ),
              if (branch.authoredAt != null)
                Text(
                  Format.relative(branch.authoredAt),
                  style: theme.textTheme.labelSmall,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Insets.sm, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: Radii.borderPill,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
