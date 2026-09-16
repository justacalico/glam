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
import 'package:glam/src/features/repository/data/repository_repository.dart';
import 'package:glam/src/features/repository/domain/repo_models.dart';

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
              'blame',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontFamily: 'JetBrains Mono'),
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
    // Flatten to rows: one header per hunk, then a numbered line each.
    final rows = <_Row>[];
    var lineNo = 1;
    for (final h in hunks) {
      rows.add(_Header(h.commit));
      for (final line in h.lines) {
        rows.add(_Line(lineNo++, line));
      }
    }
    if (rows.isEmpty) {
      return const Center(child: Text('Nothing to blame'));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: Insets.lg),
      itemCount: rows.length,
      itemBuilder: (context, index) => switch (rows[index]) {
        _Header(:final commit) => _CommitBanner(
          commit: commit,
          projectId: projectId,
        ),
        _Line(:final no, :final text) => _CodeLine(no: no, text: text),
      },
    );
  }
}

sealed class _Row {}

final class _Header extends _Row {
  _Header(this.commit);
  final Commit commit;
}

final class _Line extends _Row {
  _Line(this.no, this.text);
  final int no;
  final String text;
}

class _CommitBanner extends StatelessWidget {
  const _CommitBanner({required this.commit, required this.projectId});

  final Commit commit;
  final String projectId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
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
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: Text(
                  '${commit.authorName ?? 'unknown'}'
                  ' · ${Format.relative(commit.committedAt)}'
                  '${commit.title.isEmpty ? '' : ' · ${commit.title}'}',
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

class _CodeLine extends StatelessWidget {
  const _CodeLine({required this.no, required this.text});

  final int no;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const style = TextStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: 11.5,
      height: 1.55,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          child: Text(
            '$no',
            textAlign: TextAlign.right,
            style: style.copyWith(color: colors.inkMuted, fontSize: 10.5),
          ),
        ),
        const SizedBox(width: Insets.sm),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(text.isEmpty ? ' ' : text, style: style),
          ),
        ),
      ],
    );
  }
}
