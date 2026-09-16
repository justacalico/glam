import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/features/repository/application/repository_providers.dart';

/// Create or edit a repository file. Commits straight to [branch].
class FileEditorScreen extends ConsumerStatefulWidget {
  const FileEditorScreen({
    required this.projectId,
    required this.branch,
    this.path,
    this.pathPrefix = '',
    this.initialContent = '',
    super.key,
  });

  /// Pushes the editor and returns `true` when a commit was made.
  static Future<bool?> show(
    BuildContext context, {
    required Object projectId,
    required String branch,
    String? path,
    String pathPrefix = '',
    String initialContent = '',
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FileEditorScreen(
          projectId: projectId,
          branch: branch,
          path: path,
          pathPrefix: pathPrefix,
          initialContent: initialContent,
        ),
      ),
    );
  }

  final Object projectId;
  final String branch;

  /// Existing path in edit mode; `null` means create.
  final String? path;

  /// Directory prefix pre-filled on the path field when creating.
  final String pathPrefix;
  final String initialContent;

  @override
  ConsumerState<FileEditorScreen> createState() => _FileEditorScreenState();
}

class _FileEditorScreenState extends ConsumerState<FileEditorScreen> {
  late final TextEditingController _path;
  late final TextEditingController _content;
  late final TextEditingController _message;
  bool _saving = false;

  bool get _creating => widget.path == null;

  @override
  void initState() {
    super.initState();
    _path = TextEditingController(text: widget.path ?? widget.pathPrefix);
    _content = TextEditingController(text: widget.initialContent);
    _message = TextEditingController(
      text: widget.path == null ? '' : 'Update ${widget.path}',
    );
  }

  @override
  void dispose() {
    _path.dispose();
    _content.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final path = _path.text.trim();
    if (path.isEmpty || _message.text.trim().isEmpty) {
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(repositoryRepositoryProvider);
      if (_creating) {
        await repo.createFile(
          widget.projectId,
          path,
          branch: widget.branch,
          content: _content.text,
          commitMessage: _message.text.trim(),
        );
      } else {
        await repo.updateFile(
          widget.projectId,
          path,
          branch: widget.branch,
          content: _content.text,
          commitMessage: _message.text.trim(),
        );
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: Text(_creating ? 'New file' : 'Edit ${widget.path}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Insets.sm),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Commit'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: Insets.pagePadding,
        children: [
          TextField(
            controller: _path,
            enabled: _creating,
            decoration: const InputDecoration(labelText: 'File path'),
            style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
          ),
          const SizedBox(height: Insets.md),
          TextField(
            controller: _message,
            decoration: const InputDecoration(labelText: 'Commit message'),
          ),
          const SizedBox(height: Insets.md),
          Container(
            constraints: const BoxConstraints(minHeight: 280),
            decoration: BoxDecoration(
              color: colors.surfaceMuted,
              borderRadius: Radii.borderMd,
              border: Border.all(color: colors.border),
            ),
            padding: const EdgeInsets.all(Insets.md),
            child: TextField(
              controller: _content,
              maxLines: null,
              decoration: const InputDecoration.collapsed(
                hintText: 'File contents',
              ),
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: Insets.sm),
          Text(
            'Commits to ${widget.branch}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
