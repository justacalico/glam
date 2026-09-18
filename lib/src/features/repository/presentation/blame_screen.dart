import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/features/repository/application/repository_providers.dart';
import 'package:glam/src/features/repository/domain/repo_models.dart';
import 'package:glam/src/app/theme/app_typography.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// `git blame` for one file: each hunk gets a commit banner followed by
/// its numbered lines.
class BlameScreen extends ConsumerWidget {
  const BlameScreen({
    required this.projectId,
    required this.path,
    this.ref,
    super.key,
  });

  final String projectId;
  final String path;
  final String? ref;

  @override
  Widget build(BuildContext context, WidgetRef refScope) {
    final loc = (project: projectId as Object, path: path, ref: ref);
    final blame = refScope.watch(blameProvider(loc));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              path.split('/').last,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              path,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontFamily: GlamFonts.mono),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: AsyncValueWidget<List<BlameHunk>>(
        value: blame,
        onRetry: () => refScope.invalidate(blameProvider(loc)),
        data: (hunks) => _BlameList(hunks: hunks, projectId: projectId),
      ),
    );
  }
}

class _BlameList extends StatelessWidget {
  const _BlameList({required this.hunks, required this.projectId});

  final List<BlameHunk> hunks;
  final String projectId;

  @override
  Widget build(BuildContext context) {
    if (hunks.isEmpty) {
      return Center(child: Text(context.l10n.nothingToBlame));
    }
    // Line numbers run continuously across hunks.
    final starts = <int>[];
    var line = 1;
    for (final hunk in hunks) {
      starts.add(line);
      line += hunk.lines.length;
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: Insets.lg),
      itemCount: hunks.length,
      itemBuilder: (context, index) => _HunkView(
        hunk: hunks[index],
        projectId: projectId,
        firstLine: starts[index],
      ),
    );
  }
}

/// One hunk: a banner for the commit, then its lines. The line-number
/// gutter stays put while the code scrolls horizontally as one block.
class _HunkView extends StatelessWidget {
  const _HunkView({
    required this.hunk,
    required this.projectId,
    required this.firstLine,
  });

  final BlameHunk hunk;
  final String projectId;
  final int firstLine;

  static const _rowHeight = 20.0;
  static const _gutterWidth = 52.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const codeStyle = TextStyle(
      fontFamily: GlamFonts.mono,
      fontSize: 11.5,
      height: 1.5,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CommitBanner(commit: hunk.commit, projectId: projectId),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: _gutterWidth,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: colors.border)),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < hunk.lines.length; i++)
                    SizedBox(
                      height: _rowHeight,
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.only(right: Insets.sm),
                        child: Text(
                          '${firstLine + i}',
                          textAlign: TextAlign.right,
                          style: codeStyle.copyWith(
                            color: colors.inkMuted,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: Insets.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final line in hunk.lines)
                      SizedBox(
                        height: _rowHeight,
                        child: Text(
                          line.isEmpty ? ' ' : line,
                          style: codeStyle,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CommitBanner extends StatelessWidget {
  const _CommitBanner({required this.commit, required this.projectId});

  final Commit commit;
  final String projectId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final meta = [
      commit.authorName ?? 'unknown',
      Format.relative(commit.committedAt),
      commit.title,
    ].where((s) => s.isNotEmpty).join(' · ');
    return Material(
      color: colors.surface,
      child: InkWell(
        onTap: commit.id.isEmpty
            ? null
            : () => unawaited(
                context.push(Routes.projectCommit(projectId, commit.id)),
              ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.lg,
            vertical: Insets.sm,
          ),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: colors.border),
              bottom: BorderSide(color: colors.border),
            ),
          ),
          child: Row(
            children: [
              Text(
                commit.shortId.isEmpty ? '—' : commit.shortId,
                style: const TextStyle(
                  fontFamily: GlamFonts.mono,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: Text(
                  meta,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.inkMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
