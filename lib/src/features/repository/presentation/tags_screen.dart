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

/// Tag list; tags with attached releases show the release name.
class TagsScreen extends ConsumerWidget {
  const TagsScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(tagsProvider(projectId));
    final notifier = ref.read(tagsProvider(projectId).notifier);

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.md,
              Insets.sm,
              Insets.md,
              0,
            ),
            child: TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New tag'),
              onPressed: () => _showCreate(context, ref),
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
              empty: const EmptyState(
                icon: Icons.sell_outlined,
                title: 'No tags',
              ),
              itemBuilder: (context, index) =>
                  _TagTile(tag: data.items[index], projectId: projectId),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showCreate(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final source = TextEditingController();
    final message = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New tag'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Tag name'),
            ),
            const SizedBox(height: Insets.md),
            TextField(
              controller: source,
              decoration: const InputDecoration(
                labelText: 'Source ref (branch or sha)',
              ),
            ),
            const SizedBox(height: Insets.md),
            TextField(
              controller: message,
              decoration: const InputDecoration(
                labelText: 'Message (optional)',
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
          .read(repositoryRepositoryProvider)
          .createTag(
            projectId,
            name: name.text.trim(),
            ref: source.text.trim().isEmpty ? 'HEAD' : source.text.trim(),
            message: message.text.trim().isEmpty ? null : message.text.trim(),
          );
      ref.invalidate(tagsProvider);
    }
  }
}

class _TagTile extends ConsumerWidget {
  const _TagTile({required this.tag, required this.projectId});

  final Tag tag;
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
          Icon(Icons.sell_outlined, size: 18, color: colors.brand),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tag.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                    if (tag.hasRelease) ...[
                      const SizedBox(width: Insets.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Insets.sm,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: colors.successSoft,
                          borderRadius: Radii.borderPill,
                        ),
                        child: Text(
                          'release',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: colors.success,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  tag.commitTitle ?? tag.message ?? '',
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            Format.relative(tag.committedAt),
            style: theme.textTheme.labelSmall,
          ),
          PopupMenuButton<String>(
            iconSize: 18,
            onSelected: (action) async {
              if (action == 'delete') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Delete tag ${tag.name}?'),
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
                if (confirmed == true) {
                  await ref
                      .read(repositoryRepositoryProvider)
                      .deleteTag(projectId, tag.name);
                  ref.invalidate(tagsProvider);
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'delete', child: Text('Delete tag')),
            ],
          ),
        ],
      ),
    );
  }
}
