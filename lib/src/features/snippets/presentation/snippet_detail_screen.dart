import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/utils/url_launcher.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/code_viewer.dart';
import 'package:glam/src/core/widgets/comment_composer.dart';
import 'package:glam/src/core/widgets/error_view.dart';
import 'package:glam/src/core/widgets/markdown_viewer.dart';
import 'package:glam/src/core/widgets/note_card.dart';
import 'package:glam/src/core/widgets/user_avatar.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/engagement/presentation/reactions_row.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/snippets/application/snippets_providers.dart';
import 'package:glam/src/features/snippets/domain/snippet.dart';
import 'package:glam/src/features/snippets/presentation/snippet_form_screen.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// One snippet: metadata header plus the highlighted file contents.
class SnippetDetailScreen extends ConsumerWidget {
  const SnippetDetailScreen({required this.loc, super.key});

  final SnippetRef loc;

  String _language(Snippet snippet) {
    final name = snippet.fileName ?? snippet.files.firstOrNull?.path ?? '';
    final ext = name.contains('.') ? name.split('.').last : '';
    return ext;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snippet = ref.watch(snippetProvider(loc));
    final raw = ref.watch(snippetRawProvider(loc));

    return Scaffold(
      appBar: AppBar(
        title: Text(snippet.value?.title ?? context.l10n.snippet),
        actions: [
          if (snippet.value?.webUrl != null)
            IconButton(
              tooltip: context.l10n.actionOpenBrowser,
              icon: const Icon(Icons.open_in_new, size: 20),
              onPressed: () =>
                  unawaited(launchExternal(snippet.value!.webUrl!)),
            ),
          IconButton(
            tooltip: context.l10n.actionEdit,
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => unawaited(
              SnippetFormScreen.show(
                context,
                snippet: snippet.value,
                projectId: loc.projectId,
                rawContent: raw.value,
              ).then((saved) {
                if (saved) {
                  ref
                    ..invalidate(snippetProvider(loc))
                    ..invalidate(snippetRawProvider(loc))
                    ..invalidate(snippetsProvider);
                }
              }),
            ),
          ),
          IconButton(
            tooltip: context.l10n.actionDelete,
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => unawaited(_confirmDelete(context, ref)),
          ),
        ],
      ),
      body: AsyncValueWidget(
        value: snippet,
        data: (s) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(Insets.lg),
                children: [
                  _Header(snippet: s),
                  const SizedBox(height: Insets.sm),
                  ReactionsRow(
                    loc: (
                      kind: 'snippet',
                      project: loc.projectId,
                      iid: loc.id,
                      noteId: null,
                    ),
                  ),
                  if (s.description != null && s.description!.isNotEmpty) ...[
                    const SizedBox(height: Insets.md),
                    MarkdownViewer(data: s.description!),
                  ],
                  if (s.files.length > 1) ...[
                    const SizedBox(height: Insets.md),
                    Wrap(
                      spacing: Insets.sm,
                      runSpacing: Insets.xs,
                      children: [
                        for (final f in s.files) Chip(label: Text(f.path)),
                      ],
                    ),
                  ],
                  const SizedBox(height: Insets.md),
                  ClipRRect(
                    borderRadius: Radii.borderMd,
                    child: AsyncValueWidget(
                      value: raw,
                      data: (code) => CodeViewer(
                        code: code,
                        language: _language(s),
                        wrap: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: Insets.lg),
                  Text(
                    context.l10n.hookComments,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: Insets.sm),
                  _SnippetNotes(loc: loc),
                  const SizedBox(height: Insets.xl),
                ],
              ),
            ),
            CommentComposer(
              onSend: (body) async {
                await ref
                    .read(snippetNotesProvider(loc).notifier)
                    .addComment(body);
              },
              onUpload: loc.projectId == null
                  ? null
                  : (bytes, name) => ref
                        .read(projectsRepositoryProvider)
                        .uploadFile(loc.projectId!, bytes, name),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteSnippet),
        content: Text(context.l10n.thisCannotBeUndone),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await ref
        .read(snippetsRepositoryProvider)
        .delete(loc.id, projectId: loc.projectId);
    ref.invalidate(snippetsProvider);
    if (context.mounted) {
      context.pop();
    }
  }
}

class _SnippetNotes extends ConsumerWidget {
  const _SnippetNotes({required this.loc});

  final SnippetRef loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(snippetNotesProvider(loc));
    final myId = ref.watch(sessionProvider).value?.user.id;
    return notes.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(Insets.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => ErrorView(error: e),
      data: (state) {
        final visible = state.items.where((n) => !n.system).toList();
        if (visible.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(Insets.lg),
            child: Text(
              context.l10n.noCommentsYet,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }
        return Column(
          children: [
            for (final note in visible)
              NoteCard(
                note: note,
                onEdit: note.author?.id == myId
                    ? (body) => ref
                          .read(snippetNotesProvider(loc).notifier)
                          .editComment(note.id, body)
                    : null,
                onDelete: note.author?.id == myId
                    ? () => ref
                          .read(snippetNotesProvider(loc).notifier)
                          .deleteComment(note.id)
                    : null,
                footer: ReactionsRow(
                  loc: (
                    kind: 'snippet',
                    project: loc.projectId,
                    iid: loc.id,
                    noteId: note.id,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.snippet});

  final Snippet snippet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final author = snippet.author;
    return Row(
      children: [
        if (author != null) ...[
          UserAvatar(
            name: author.name,
            avatarUrl: author.avatarUrl,
            radius: 12,
          ),
          const SizedBox(width: Insets.sm),
        ],
        Expanded(
          child: Text(
            [
              if (author != null) '@${author.username}',
              if (snippet.fileName != null) snippet.fileName!,
              Format.relative(snippet.updatedAt),
            ].join(' · '),
            style: theme.textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          tooltip: context.l10n.copyLink,
          icon: Icon(Icons.link, size: 18, color: colors.inkMuted),
          onPressed: () {
            final url = snippet.webUrl;
            if (url != null) {
              unawaited(Clipboard.setData(ClipboardData(text: url)));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(context.l10n.linkCopied)));
            }
          },
        ),
      ],
    );
  }
}
