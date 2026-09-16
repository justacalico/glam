import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/models/note.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/utils/url_launcher.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/avatar_stack.dart';
import 'package:glam/src/core/widgets/error_view.dart';
import 'package:glam/src/core/widgets/label_chip.dart';
import 'package:glam/src/core/widgets/markdown_viewer.dart';
import 'package:glam/src/core/widgets/state_chip.dart';
import 'package:glam/src/core/widgets/user_avatar.dart';
import 'package:glam/src/features/issues/application/issues_providers.dart';
import 'package:glam/src/features/issues/domain/issue.dart';
import 'package:glam/src/features/issues/presentation/issue_form_screen.dart';

/// Issue detail: metadata, description, and the comment thread with a
/// composer docked at the bottom.
class IssueDetailScreen extends ConsumerWidget {
  const IssueDetailScreen({
    required this.projectId,
    required this.iid,
    super.key,
  });

  final Object projectId;
  final int iid;

  IssueRef get _loc => (project: projectId, iid: iid);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issue = ref.watch(issueProvider(_loc));
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: Text('#$iid'),
        actions: [
          issue.maybeWhen(
            data: (i) => _IssueActions(issue: i, loc: _loc),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: AsyncValueWidget<Issue>(
        value: issue,
        onRetry: () => ref.invalidate(issueProvider(_loc)),
        data: (issue) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: Insets.pagePadding,
                children: [
                  _Header(issue: issue),
                  if (issue.description?.isNotEmpty ?? false) ...[
                    const SizedBox(height: Insets.lg),
                    Container(
                      padding: const EdgeInsets.all(Insets.lg),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: Radii.borderMd,
                        border: Border.all(color: colors.border),
                      ),
                      child: MarkdownViewer(data: issue.description!),
                    ),
                  ],
                  const SizedBox(height: Insets.xl),
                  Text(
                    'Activity',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: Insets.sm),
                  _NotesList(loc: _loc),
                  const SizedBox(height: Insets.xl),
                ],
              ),
            ),
            _Composer(loc: _loc),
          ],
        ),
      ),
    );
  }
}

class _IssueActions extends ConsumerWidget {
  const _IssueActions({required this.issue, required this.loc});

  final Issue issue;
  final IssueRef loc;

  Future<void> _toggleState(WidgetRef ref) {
    return ref
        .read(issuesRepositoryProvider)
        .updateIssue(
          loc.project,
          loc.iid,
          stateEvent: issue.isOpen ? 'close' : 'reopen',
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (action) async {
        switch (action) {
          case 'toggle':
            await _toggleState(ref);
            ref.invalidate(issueProvider(loc));
          case 'edit':
            unawaited(
              IssueFormScreen.show(
                context,
                projectId: loc.project,
                issue: issue,
              ),
            );
          case 'copy':
            if (issue.webUrl != null) {
              unawaited(Clipboard.setData(ClipboardData(text: issue.webUrl!)));
            }
          case 'open':
            if (issue.webUrl != null) {
              unawaited(launchExternal(issue.webUrl!));
            }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'toggle',
          child: Text(issue.isOpen ? 'Close issue' : 'Reopen issue'),
        ),
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        const PopupMenuItem(value: 'copy', child: Text('Copy link')),
        const PopupMenuItem(value: 'open', child: Text('Open in browser')),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.issue});

  final Issue issue;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StateChip.issueState(issue.state),
            if (issue.confidential) ...[
              const SizedBox(width: Insets.sm),
              StateChip(
                label: 'Confidential',
                tone: ChipTone.warning,
                icon: Icons.lock_outline,
              ),
            ],
          ],
        ),
        const SizedBox(height: Insets.sm),
        Text(issue.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: Insets.sm),
        Wrap(
          spacing: Insets.lg,
          runSpacing: Insets.xs,
          children: [
            if (issue.author != null)
              _AuthorLine(issue: issue, theme: theme, colors: colors),
            if (issue.milestone != null)
              _MetaRow(
                icon: Icons.flag_outlined,
                label: issue.milestone!.title,
                colors: colors,
                theme: theme,
              ),
            if (issue.dueDate != null)
              _MetaRow(
                icon: Icons.event_outlined,
                label: 'Due ${Format.date(issue.dueDate)}',
                colors: colors,
                theme: theme,
              ),
            if (issue.weight != null)
              _MetaRow(
                icon: Icons.scale_outlined,
                label: 'Weight ${issue.weight}',
                colors: colors,
                theme: theme,
              ),
          ],
        ),
        if (issue.labels.isNotEmpty) ...[
          const SizedBox(height: Insets.sm),
          Wrap(
            spacing: Insets.xs,
            runSpacing: Insets.xs,
            children: [for (final l in issue.labels) LabelChip(name: l)],
          ),
        ],
        if (issue.assignees.isNotEmpty) ...[
          const SizedBox(height: Insets.md),
          Row(
            children: [
              AvatarStack(users: issue.assignees),
              const SizedBox(width: Insets.sm),
              Text(
                issue.assignees.map((a) => a.name).join(', '),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
        if (issue.closedBy != null || issue.taskStatus != null)
          Padding(
            padding: const EdgeInsets.only(top: Insets.sm),
            child: Text(
              [
                if (issue.closedBy != null) 'Closed by ${issue.closedBy!.name}',
                if (issue.taskStatus != null) 'Tasks ${issue.taskStatus}',
              ].join(' · '),
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

class _AuthorLine extends StatelessWidget {
  const _AuthorLine({
    required this.issue,
    required this.theme,
    required this.colors,
  });

  final Issue issue;
  final ThemeData theme;
  final GlamColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UserAvatar(
          name: issue.author!.name,
          avatarUrl: issue.author!.avatarUrl,
          radius: 10,
        ),
        const SizedBox(width: Insets.xs),
        Text(
          '${issue.author!.name} opened '
          '${Format.relative(issue.createdAt)}',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.colors,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final GlamColors colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: colors.inkMuted),
        const SizedBox(width: Insets.xs),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _NotesList extends ConsumerWidget {
  const _NotesList({required this.loc});

  final IssueRef loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(issueNotesProvider(loc));
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
              'No comments yet',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }
        return Column(
          children: [for (final note in visible) _NoteCard(note: note)],
        );
      },
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});

  final Note note;

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
                if (note.author != null)
                  UserAvatar(
                    name: note.author!.name,
                    avatarUrl: note.author!.avatarUrl,
                    radius: 9,
                  ),
                const SizedBox(width: Insets.sm),
                Text(
                  note.author?.name ?? 'deleted user',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(width: Insets.sm),
                Text(
                  Format.relative(note.createdAt),
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Insets.md),
            child: MarkdownViewer(data: note.body),
          ),
        ],
      ),
    );
  }
}

class _Composer extends ConsumerStatefulWidget {
  const _Composer({required this.loc});

  final IssueRef loc;

  @override
  ConsumerState<_Composer> createState() => _ComposerState();
}

class _ComposerState extends ConsumerState<_Composer> {
  final _controller = TextEditingController();
  var _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending) {
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(issueNotesProvider(widget.loc).notifier).addComment(body);
      _controller.clear();
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to post comment')));
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.only(
        left: Insets.lg,
        right: Insets.sm,
        top: Insets.sm,
        bottom: Insets.sm + MediaQuery.viewPaddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Write a comment',
                isDense: true,
                filled: true,
                fillColor: colors.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: Radii.borderMd,
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Insets.md,
                  vertical: Insets.sm + 2,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.send, color: colors.accent, size: 20),
          ),
        ],
      ),
    );
  }
}
