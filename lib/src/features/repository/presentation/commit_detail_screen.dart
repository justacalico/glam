import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/features/repository/application/repository_providers.dart';
import 'package:glam/src/features/repository/presentation/changes_list.dart';
import 'package:glam/src/features/repository/domain/repo_models.dart';

/// Commit detail: message, author, stats, and the per-file diffs.
class CommitDetailScreen extends ConsumerWidget {
  const CommitDetailScreen({
    required this.projectId,
    required this.sha,
    super.key,
  });

  final String projectId;
  final String sha;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commit = ref.watch(commitProvider((project: projectId, sha: sha)));
    final diffs = ref.watch(commitDiffProvider((project: projectId, sha: sha)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commit'),
        actions: [_CommitActions(projectId: projectId, sha: sha)],
      ),
      body: AsyncValueWidget<Commit>(
        value: commit,
        onRetry: () => ref
          ..invalidate(commitProvider((project: projectId, sha: sha)))
          ..invalidate(commitDiffProvider((project: projectId, sha: sha))),
        data: (c) => ListView(
          padding: Insets.pagePadding,
          children: [
            Text(c.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: Insets.sm),
            _Meta(commit: c),
            const SizedBox(height: Insets.lg),
            diffs.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(Insets.xl),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(Insets.lg),
                child: Text('Could not load the diff: $e'),
              ),
              data: (changes) => ChangesList(changes: changes),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommitActions extends ConsumerWidget {
  const _CommitActions({required this.projectId, required this.sha});

  final String projectId;
  final String sha;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (action) async {
        final repo = ref.read(repositoryRepositoryProvider);
        switch (action) {
          case 'cherry' || 'revert':
            final branch = await _pickBranch(context, ref);
            if (branch == null) {
              return;
            }
            final commit = action == 'cherry'
                ? await repo.cherryPick(projectId, sha, branch: branch)
                : await repo.revert(projectId, sha, branch: branch);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${action == 'cherry' ? 'Cherry-picked' : 'Reverted'} '
                    'as ${commit.shortId}',
                  ),
                ),
              );
            }
          case 'copy':
            unawaited(Clipboard.setData(ClipboardData(text: sha)));
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'cherry',
          child: Text('Cherry-pick to branch'),
        ),
        const PopupMenuItem(value: 'revert', child: Text('Revert on branch')),
        const PopupMenuItem(value: 'copy', child: Text('Copy SHA')),
      ],
    );
  }

  Future<String?> _pickBranch(BuildContext context, WidgetRef ref) {
    final branches =
        ref.read(branchesProvider(projectId)).value?.items ?? const [];
    final names = [for (final b in branches) b.name];
    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Target branch'),
        children: [
          for (final name in names)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, name),
              child: Text(name),
            ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.commit});

  final Commit commit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Insets.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Radii.borderMd,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (commit.message != null && commit.message!.trim() != commit.title)
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.md),
              child: Text(
                commit.message!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Text(
                  commit.authorName ?? 'unknown',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Text(
                Format.dateTime(commit.committedAt),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          InkWell(
            onTap: () => Clipboard.setData(ClipboardData(text: commit.id)),
            borderRadius: Radii.borderSm,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  commit.id,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: Insets.xs),
                Icon(Icons.copy_outlined, size: 14, color: colors.inkFaint),
              ],
            ),
          ),
          if (commit.parentIds.isNotEmpty) ...[
            const SizedBox(height: Insets.xs),
            Text(
              'Parents: ${commit.parentIds.map(shortSha).join(', ')}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

String shortSha(String sha) => sha.length > 8 ? sha.substring(0, 8) : sha;
