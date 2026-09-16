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
        empty: const EmptyState(icon: Icons.sell_outlined, title: 'No tags'),
        itemBuilder: (context, index) => _TagTile(tag: data.items[index]),
      ),
    );
  }
}

class _TagTile extends StatelessWidget {
  const _TagTile({required this.tag});

  final Tag tag;

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
        ],
      ),
    );
  }
}
