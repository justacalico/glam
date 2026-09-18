import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/core/widgets/search_field.dart';
import 'package:glam/src/features/repository/application/repository_providers.dart';
import 'package:glam/src/features/repository/domain/repo_models.dart';
import 'package:glam/src/app/theme/app_typography.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// Branch list with default/protected indicators.
class BranchesScreen extends ConsumerStatefulWidget {
  const BranchesScreen({required this.projectId, super.key});

  final String projectId;

  @override
  ConsumerState<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends ConsumerState<BranchesScreen> {
  String? _search;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final projectId = widget.projectId;
    final filter = (project: projectId, search: _search);
    final state = ref.watch(branchesProvider(filter));
    final notifier = ref.read(branchesProvider(filter).notifier);

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
            hint: context.l10n.searchBranches,
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.md,
              Insets.sm,
              Insets.md,
              0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.compare_arrows, size: 16),
                  label: Text(context.l10n.compare),
                  onPressed: () =>
                      context.push(Routes.projectCompare(projectId)),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.cleaning_services_outlined, size: 16),
                  label: Text(context.l10n.deleteMerged),
                  onPressed: () => _deleteMerged(context, ref),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(context.l10n.newBranch),
                  onPressed: () => _showCreate(context, ref),
                ),
              ],
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
              separator: Divider(
                height: 1,
                color: colors.border,
                indent: Insets.lg,
                endIndent: Insets.lg,
              ),
              padding: const EdgeInsets.symmetric(vertical: Insets.sm),
              empty: EmptyState(
                icon: Icons.account_tree_outlined,
                title: context.l10n.noBranches,
              ),
              itemBuilder: (context, index) =>
                  _BranchTile(branch: data.items[index], projectId: projectId),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showCreate(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final source = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.newBranch),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: InputDecoration(labelText: context.l10n.branchName),
            ),
            const SizedBox(height: Insets.md),
            TextField(
              controller: source,
              decoration: InputDecoration(
                labelText: context.l10n.sourceRefBranchTagOrSha,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.actionCreate),
          ),
        ],
      ),
    );
    if (saved == true && name.text.trim().isNotEmpty) {
      await ref
          .read(repositoryRepositoryProvider)
          .createBranch(
            widget.projectId,
            branch: name.text.trim(),
            ref: source.text.trim().isEmpty ? 'HEAD' : source.text.trim(),
          );
      ref.invalidate(branchesProvider);
    }
  }

  Future<void> _deleteMerged(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteMergedBranches),
        content: Text(context.l10n.deleteMergedBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(repositoryRepositoryProvider)
          .deleteMergedBranches(widget.projectId);
      ref.invalidate(branchesProvider);
    }
  }
}

class _BranchTile extends ConsumerWidget {
  const _BranchTile({required this.branch, required this.projectId});

  final Branch branch;
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  fontFamily: GlamFonts.mono,
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
          PopupMenuButton<String>(
            iconSize: 18,
            onSelected: (action) async {
              switch (action) {
                case 'compare':
                  unawaited(
                    context.push(
                      Routes.projectCompare(projectId, to: branch.name),
                    ),
                  );
                case 'delete':
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(context.l10n.deleteNamedConfirm(branch.name)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(context.l10n.actionCancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(context.l10n.actionDelete),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref
                        .read(repositoryRepositoryProvider)
                        .deleteBranch(projectId, branch.name);
                    ref.invalidate(branchesProvider);
                  }
              }
            },
            itemBuilder: (context) => [
              if (!branch.isDefault)
                PopupMenuItem(
                  value: 'compare',
                  child: Text(context.l10n.compare),
                ),
              if (!branch.isDefault && !branch.protected)
                PopupMenuItem(
                  value: 'delete',
                  child: Text(context.l10n.deleteBranch),
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
