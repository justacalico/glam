import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/utils/diff_parser.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/utils/url_launcher.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/comment_composer.dart';
import 'package:glam/src/core/widgets/markdown_viewer.dart';
import 'package:glam/src/core/widgets/state_chip.dart';
import 'package:glam/src/core/widgets/user_avatar.dart';
import 'package:glam/src/features/merge_requests/domain/merge_request.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/repository/application/repository_providers.dart';
import 'package:glam/src/features/repository/presentation/changes_list.dart';
import 'package:glam/src/features/repository/domain/repo_models.dart';
import 'package:glam/src/app/theme/app_typography.dart';
import 'package:glam/src/core/utils/l10n.dart';

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
        title: Text(context.l10n.commit),
        actions: [_CommitActions(projectId: projectId, sha: sha)],
      ),
      body: AsyncValueWidget<Commit>(
        value: commit,
        onRetry: () => ref
          ..invalidate(commitProvider((project: projectId, sha: sha)))
          ..invalidate(commitDiffProvider((project: projectId, sha: sha)))
          ..invalidate(commitCommentsProvider((project: projectId, sha: sha))),
        data: (c) => ListView(
          padding: Insets.pagePadding,
          children: [
            Text(c.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: Insets.sm),
            _Meta(commit: c),
            const SizedBox(height: Insets.lg),
            _CommitStatuses(projectId: projectId, sha: sha),
            _RelatedMrs(projectId: projectId, sha: sha),
            _CommitRefs(projectId: projectId, sha: sha),
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
                child: Text(context.l10n.couldNotLoadTheDiffP0(e)),
              ),
              data: (changes) => ChangesList(
                changes: changes,
                onLineTap: (change, line) =>
                    _commentOnLine(context, ref, change, line),
              ),
            ),
            const SizedBox(height: Insets.xl),
            _CommitComments(projectId: projectId, sha: sha),
          ],
        ),
      ),
    );
  }

  /// Opens a composer anchored to the tapped diff line, then posts the
  /// comment with `path`/`line`/`line_type` for the commits API. Only
  /// added/removed lines can anchor; GitLab can't pin context lines.
  void _commentOnLine(
    BuildContext context,
    WidgetRef ref,
    ChangeEntry change,
    DiffLine line,
  ) {
    final isOld = line.kind == DiffLineKind.removed;
    final isNew = line.kind == DiffLineKind.added;
    final lineNo = isOld ? line.oldLine : line.newLine;
    if ((!isOld && !isNew) || lineNo == null) {
      return;
    }
    unawaited(() async {
      final controller = TextEditingController();
      // The API always wants new_path, even for old-side comments.
      final path = change.newPath;
      final body = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => Padding(
          padding: EdgeInsets.only(
            left: Insets.lg,
            right: Insets.lg,
            bottom: MediaQuery.viewInsetsOf(context).bottom + Insets.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.commentOnLine(path, lineNo),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: Insets.sm),
              TextField(
                controller: controller,
                autofocus: true,
                minLines: 2,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: context.l10n.writeAComment,
                ),
              ),
              const SizedBox(height: Insets.md),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, controller.text.trim()),
                  child: Text(context.l10n.comment),
                ),
              ),
            ],
          ),
        ),
      );
      controller.dispose();
      if (body == null || body.isEmpty || !context.mounted) {
        return;
      }
      try {
        await ref
            .read(repositoryRepositoryProvider)
            .addCommitComment(
              projectId,
              sha,
              note: body,
              anchor: (
                path: path,
                line: lineNo,
                lineType: isOld ? 'old' : 'new',
              ),
            );
        if (context.mounted) {
          ref.invalidate(
            commitCommentsProvider((project: projectId, sha: sha)),
          );
        }
      } on ApiException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.message)));
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.couldNotPostTheComment)),
          );
        }
      }
    }());
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
                    context.l10n.cherryRevertDone(
                      action == 'cherry'
                          ? context.l10n.cherryPicked
                          : context.l10n.reverted,
                      commit.shortId,
                    ),
                  ),
                ),
              );
            }
          case 'copy':
            unawaited(Clipboard.setData(ClipboardData(text: sha)));
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'cherry',
          child: Text(context.l10n.cherryPickToBranch),
        ),
        PopupMenuItem(
          value: 'revert',
          child: Text(context.l10n.revertOnBranch),
        ),
        PopupMenuItem(value: 'copy', child: Text(context.l10n.copySha)),
      ],
    );
  }

  Future<String?> _pickBranch(BuildContext context, WidgetRef ref) {
    final branches =
        ref
            .read(branchesProvider((project: projectId, search: null)))
            .value
            ?.items ??
        const [];
    final names = [for (final b in branches) b.name];
    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(context.l10n.targetBranch),
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
                  fontFamily: GlamFonts.mono,
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
                    fontFamily: GlamFonts.mono,
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
              context.l10n.parentsP0(commit.parentIds.map(shortSha).join(', ')),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

/// Pipeline and external checks reported on the commit. Hidden while
/// loading or when nothing was reported.
class _CommitStatuses extends ConsumerWidget {
  const _CommitStatuses({required this.projectId, required this.sha});

  final String projectId;
  final String sha;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = (project: projectId as Object, sha: sha);
    final statuses = ref.watch(commitStatusesProvider(loc));
    final theme = Theme.of(context);
    final colors = context.colors;

    return statuses.maybeWhen(
      data: (list) {
        if (list.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.checks, style: theme.textTheme.titleMedium),
            const SizedBox(height: Insets.sm),
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: Radii.borderMd,
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [for (final s in list) _StatusTile(status: s)],
              ),
            ),
            const SizedBox(height: Insets.lg),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// Merge requests this commit belongs to. Hidden while loading or
/// when the commit is in no MR.
class _RelatedMrs extends ConsumerWidget {
  const _RelatedMrs({required this.projectId, required this.sha});

  final String projectId;
  final String sha;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = (project: projectId as Object, sha: sha);
    final mrs = ref.watch(commitMergeRequestsProvider(loc));
    final theme = Theme.of(context);
    final colors = context.colors;

    return mrs.maybeWhen(
      data: (list) {
        if (list.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.mrsTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: Insets.sm),
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: Radii.borderMd,
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  for (final mr in list)
                    _RelatedMrTile(
                      mr: mr,
                      onTap: () => unawaited(
                        context.push(Routes.projectMr(mr.projectId, mr.iid)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: Insets.lg),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// Branches and tags containing this commit, e.g. "on main, v2.0".
class _CommitRefs extends ConsumerWidget {
  const _CommitRefs({required this.projectId, required this.sha});

  final String projectId;
  final String sha;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = (project: projectId as Object, sha: sha);
    final refs = ref.watch(commitRefsProvider(loc));
    final theme = Theme.of(context);
    final colors = context.colors;

    return refs.maybeWhen(
      data: (list) {
        if (list.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: Insets.md),
          child: Wrap(
            spacing: Insets.xs,
            runSpacing: Insets.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(context.l10n.on, style: theme.textTheme.bodySmall),
              for (final r in list)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Insets.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceMuted,
                    borderRadius: Radii.borderSm,
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        r.isTag
                            ? Icons.sell_outlined
                            : Icons.call_split_outlined,
                        size: 12,
                        color: colors.inkFaint,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        r.name,
                        style: const TextStyle(
                          fontFamily: GlamFonts.mono,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _RelatedMrTile extends StatelessWidget {
  const _RelatedMrTile({required this.mr, required this.onTap});

  final MergeRequest mr;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final (icon, color) = switch (mr.state) {
      'merged' => (Icons.merge, colors.info),
      'closed' => (Icons.cancel_outlined, colors.danger),
      _ => (Icons.merge_type_outlined, colors.success),
    };
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.md,
          vertical: Insets.sm + 2,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: Insets.sm),
            Expanded(
              child: Text(
                mr.title,
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(context.l10n.mrIid(mr.iid), style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.status});

  final CommitStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final url = status.targetUrl;
    return InkWell(
      onTap: url == null ? null : () => unawaited(launchExternal(url)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.md,
          vertical: Insets.sm + 2,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.name,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (status.ref != null || status.description != null)
                    Text(
                      [
                        status.ref,
                        status.description,
                      ].whereType<String>().join(' · '),
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: Insets.sm),
            StateChip.pipeline(status.status),
            if (url != null) ...[
              const SizedBox(width: Insets.xs),
              Icon(Icons.open_in_new, size: 14, color: colors.inkFaint),
            ],
          ],
        ),
      ),
    );
  }
}

/// The commit's comment thread plus a composer. Line-anchored comments
/// show their `path:line` next to the timestamp. The comments API never
/// returns ids, so comments can't be edited or deleted here.
class _CommitComments extends ConsumerWidget {
  const _CommitComments({required this.projectId, required this.sha});

  final String projectId;
  final String sha;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = (project: projectId as Object, sha: sha);
    final comments = ref.watch(commitCommentsProvider(loc));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.hookComments, style: theme.textTheme.titleMedium),
        const SizedBox(height: Insets.sm),
        comments.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(Insets.lg),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => TextButton.icon(
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(context.l10n.couldNotLoadCommentsP0(e)),
            onPressed: () => ref.invalidate(commitCommentsProvider(loc)),
          ),
          data: (list) => Column(
            children: [for (final c in list) _CommentTile(comment: c)],
          ),
        ),
        const SizedBox(height: Insets.sm),
        CommentComposer(
          hint: context.l10n.commentOnThisCommit,
          onSend: (body) async {
            await ref
                .read(repositoryRepositoryProvider)
                .addCommitComment(projectId, sha, note: body);
            if (context.mounted) {
              ref.invalidate(commitCommentsProvider(loc));
            }
          },
          onUpload: (bytes, name) => ref
              .read(projectsRepositoryProvider)
              .uploadFile(projectId, bytes, name),
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final CommitComment comment;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: Insets.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Radii.borderMd,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.md,
              vertical: Insets.sm,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceMuted,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(Radii.md - 1),
              ),
            ),
            child: Row(
              children: [
                if (comment.author != null)
                  UserAvatar(
                    name: comment.author!.name,
                    avatarUrl: comment.author!.avatarUrl,
                    radius: 9,
                  ),
                const SizedBox(width: Insets.sm),
                Flexible(
                  child: Text(
                    comment.author?.name ?? 'deleted user',
                    style: theme.textTheme.labelLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: Insets.sm),
                Text(
                  Format.relative(comment.createdAt),
                  style: theme.textTheme.labelSmall,
                ),
                if (comment.anchor != null) ...[
                  const SizedBox(width: Insets.sm),
                  Flexible(
                    child: Text(
                      comment.anchor!,
                      style: const TextStyle(
                        fontFamily: GlamFonts.mono,
                        fontSize: 10.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Insets.md),
            child: MarkdownViewer(data: comment.note),
          ),
        ],
      ),
    );
  }
}

String shortSha(String sha) => sha.length > 8 ? sha.substring(0, 8) : sha;
