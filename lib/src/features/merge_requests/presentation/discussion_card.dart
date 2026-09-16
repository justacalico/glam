import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/models/discussion.dart';
import 'package:glam/src/core/widgets/note_card.dart';
import 'package:glam/src/features/engagement/presentation/reactions_row.dart';
import 'package:glam/src/features/merge_requests/application/mr_providers.dart';

/// One discussion thread: a stack of notes, an inline reply box, and a
/// resolve toggle when the thread is resolvable.
class DiscussionCard extends ConsumerStatefulWidget {
  const DiscussionCard({
    required this.discussion,
    required this.loc,
    super.key,
  });

  final Discussion discussion;
  final MrRef loc;

  @override
  ConsumerState<DiscussionCard> createState() => _DiscussionCardState();
}

class _DiscussionCardState extends ConsumerState<DiscussionCard> {
  final _reply = TextEditingController();
  var _replying = false;
  var _busy = false;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _reply.text.trim();
    if (body.isEmpty || _busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(mrDiscussionsProvider(widget.loc).notifier)
          .reply(widget.discussion.id, body);
      if (mounted) {
        _reply.clear();
        setState(() => _replying = false);
      }
    } on ApiException catch (e) {
      _error(e.message);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _toggleResolved() async {
    try {
      await ref
          .read(mrDiscussionsProvider(widget.loc).notifier)
          .toggleResolved(widget.discussion);
    } on ApiException catch (e) {
      _error(e.message);
    }
  }

  void _error(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final d = widget.discussion;
    final position = d.position?.label;

    return Container(
      margin: const EdgeInsets.only(bottom: Insets.md),
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: Radii.borderMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (position != null || d.resolvable)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Insets.md,
                vertical: Insets.xs,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceMuted,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(Radii.md - 1),
                ),
              ),
              child: Row(
                children: [
                  if (position != null)
                    Expanded(
                      child: Text(
                        position,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontFamily: 'JetBrains Mono',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else
                    const Spacer(),
                  if (d.resolvable)
                    TextButton.icon(
                      icon: Icon(
                        d.resolved
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                        size: 14,
                      ),
                      label: Text(d.resolved ? 'Resolved' : 'Resolve'),
                      style: TextButton.styleFrom(
                        foregroundColor: d.resolved
                            ? colors.success
                            : colors.inkMuted,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: _busy ? null : _toggleResolved,
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(Insets.sm),
            child: Column(
              children: [
                for (final note in d.notes.where((n) => !n.system))
                  NoteCard(
                    note: note,
                    footer: ReactionsRow(
                      loc: (
                        kind: 'mr',
                        project: widget.loc.project,
                        iid: widget.loc.iid,
                        noteId: note.id,
                      ),
                    ),
                  ),
                if (_replying)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _reply,
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: 'Reply…',
                            isDense: true,
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, size: 18),
                        onPressed: _send,
                      ),
                    ],
                  )
                else
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.reply, size: 14),
                      label: const Text('Reply'),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.inkMuted,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => setState(() => _replying = true),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
