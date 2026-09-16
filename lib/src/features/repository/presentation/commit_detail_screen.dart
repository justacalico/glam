import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/utils/diff_parser.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/diff_viewer.dart';
import 'package:glam/src/features/repository/application/repository_providers.dart';
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
      appBar: AppBar(title: const Text('Commit')),
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
              data: (changes) => _Changes(changes: changes),
            ),
          ],
        ),
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

class _Changes extends StatelessWidget {
  const _Changes({required this.changes});

  final List<ChangeEntry> changes;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    var additions = 0;
    var deletions = 0;
    final parsed = <(ChangeEntry, FileDiff)>[];
    for (final change in changes) {
      final diff = FileDiff(
        oldPath: change.oldPath,
        newPath: change.newPath,
        hunks: DiffParser.parse(change.diff),
        newFile: change.newFile,
        deletedFile: change.deletedFile,
        renamedFile: change.renamedFile,
      );
      additions += diff.additions;
      deletions += diff.deletions;
      parsed.add((change, diff));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${parsed.length} ${parsed.length == 1 ? 'file' : 'files'}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(width: Insets.md),
            Text('+$additions', style: TextStyle(color: colors.diffAdd)),
            const SizedBox(width: Insets.xs),
            Text('−$deletions', style: TextStyle(color: colors.diffRemove)),
          ],
        ),
        const SizedBox(height: Insets.md),
        for (final (change, diff) in parsed) ...[
          _FileChangeTile(change: change, diff: diff),
          const SizedBox(height: Insets.md),
        ],
      ],
    );
  }
}

class _FileChangeTile extends StatefulWidget {
  const _FileChangeTile({required this.change, required this.diff});

  final ChangeEntry change;
  final FileDiff diff;

  @override
  State<_FileChangeTile> createState() => _FileChangeTileState();
}

class _FileChangeTileState extends State<_FileChangeTile> {
  var _expanded = true;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final change = widget.change;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Radii.borderMd,
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(Insets.md),
              child: Row(
                children: [
                  Icon(
                    change.deletedFile
                        ? Icons.remove_circle_outline
                        : change.newFile
                        ? Icons.add_circle_outline
                        : Icons.edit_outlined,
                    size: 15,
                    color: change.deletedFile
                        ? colors.danger
                        : change.newFile
                        ? colors.success
                        : colors.inkMuted,
                  ),
                  const SizedBox(width: Insets.sm),
                  Expanded(
                    child: Text(
                      change.displayPath,
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '+${widget.diff.additions} −${widget.diff.deletions}',
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(width: Insets.sm),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: colors.inkFaint,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            if (widget.diff.hunks.isEmpty)
              Padding(
                padding: const EdgeInsets.all(Insets.lg),
                child: Text(
                  'Diff too large or binary. View it on the web',
                  style: theme.textTheme.bodySmall,
                ),
              )
            else
              ClipRect(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 1200,
                    child: DiffViewer(diff: widget.diff),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

String shortSha(String sha) => sha.length > 8 ? sha.substring(0, 8) : sha;
