import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';

/// Bottom-docked comment input with a send button and an optional
/// file-attach affordance.
class CommentComposer extends StatefulWidget {
  const CommentComposer({
    required this.onSend,
    this.hint,
    this.onUpload,
    super.key,
  });

  /// Called with the trimmed body. Throw to surface a snackbar.
  final Future<void> Function(String body) onSend;
  final String? hint;

  /// Uploads a picked file and returns the markdown snippet to insert.
  /// When null the attach button is hidden.
  final Future<String> Function(Uint8List bytes, String name)? onUpload;

  @override
  State<CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<CommentComposer> {
  final _controller = TextEditingController();
  var _sending = false;
  var _uploading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _attach() async {
    final file = await FilePicker.pickFile();
    if (file == null || !mounted) {
      return;
    }
    final bytes = await file.readAsBytes();
    setState(() => _uploading = true);
    try {
      final markdown = await widget.onUpload!(bytes, file.name);
      final text = _controller.text;
      final sel = _controller.selection;
      final at = sel.isValid ? sel.start : text.length;
      _controller
        ..text = '${text.substring(0, at)}$markdown${text.substring(at)}'
        ..selection = TextSelection.collapsed(offset: at + markdown.length);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to upload file')));
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending) {
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.onSend(body);
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
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: widget.hint ?? 'Write a comment',
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
          if (widget.onUpload != null)
            IconButton(
              tooltip: 'Attach a file',
              onPressed: _uploading ? null : _attach,
              icon: _uploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.attach_file, color: colors.inkMuted, size: 20),
            ),
          IconButton(
            onPressed: _sending || _controller.text.trim().isEmpty
                ? null
                : _send,
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.send,
                    color: _controller.text.trim().isEmpty
                        ? colors.inkFaint
                        : colors.accent,
                    size: 20,
                  ),
          ),
        ],
      ),
    );
  }
}
