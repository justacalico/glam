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
import 'package:glam/src/features/repository/application/repository_providers.dart';
import 'package:glam/src/features/repository/domain/repo_models.dart';

/// Commit history for a project (optionally pinned to a ref).
class CommitsScreen extends ConsumerWidget {
  const CommitsScreen({required this.projectId, this.ref, super.key});

  final String projectId;
  final String? ref;

  @override
  Widget build(BuildContext context, WidgetRef refScope) {
    final colors = context.colors;
    final location = (project: projectId as Object, ref: ref);
    final state = refScope.watch(commitsProvider(location));
    final notifier = refScope.read(commitsProvider(location).notifier);

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
        empty: const EmptyState(icon: Icons.commit, title: 'No commits'),
        itemBuilder: (context, index) =>
            CommitTile(commit: data.items[index], projectId: projectId),
      ),
    );
  }
}

/// A single commit row: title, author, sha, age.
class CommitTile extends StatelessWidget {
  const CommitTile({required this.commit, required this.projectId, super.key});

  final Commit commit;
  final String projectId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => context.push(Routes.projectCommit(projectId, commit.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.lg,
          vertical: Insets.md,
        ),
        child: Row(
          children: [
            Icon(Icons.commit, size: 18, color: colors.inkMuted),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    commit.title,
                    style: theme.textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Insets.xs),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          commit.authorName ?? 'unknown',
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(' · ', style: theme.textTheme.bodySmall),
                      Text(
                        Format.relative(commit.committedAt),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: Insets.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Insets.sm,
                vertical: Insets.xxs + 1,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceMuted,
                borderRadius: Radii.borderSm,
                border: Border.all(color: colors.border),
              ),
              child: Text(
                commit.shortId,
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
