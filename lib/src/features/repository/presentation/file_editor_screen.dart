import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/features/repository/application/repository_providers.dart';
import 'package:glam/src/app/theme/app_typography.dart';
import 'package:glam/src/core/utils/l10n.dart';

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

  Future<void> _applyTemplate() async {
    final picked = await _TemplateSheet.show(
      context,
      projectId: widget.projectId,
    );
    if (picked == null || !mounted) {
      return;
    }
    _content.text = picked.content;
    // Only overwrite the path when it is still just the folder prefix.
    if (_path.text == widget.pathPrefix) {
      _path.text = '${widget.pathPrefix}${picked.filename}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _creating
              ? context.l10n.newFile
              : context.l10n.editP0('${widget.path}'),
        ),
        actions: [
          if (_creating)
            TextButton.icon(
              icon: const Icon(Icons.article_outlined, size: 16),
              label: Text(context.l10n.template),
              onPressed: _applyTemplate,
            ),
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
                  : Text(context.l10n.commit),
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
            decoration: InputDecoration(labelText: context.l10n.filePath),
            style: const TextStyle(fontFamily: GlamFonts.mono, fontSize: 13),
          ),
          const SizedBox(height: Insets.md),
          TextField(
            controller: _message,
            decoration: InputDecoration(labelText: context.l10n.commitMessage),
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
              decoration: InputDecoration.collapsed(
                hintText: context.l10n.fileContents,
              ),
              style: const TextStyle(
                fontFamily: GlamFonts.mono,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: Insets.sm),
          Text(
            context.l10n.commitsToP0(widget.branch),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

/// Picks a GitLab file template (gitignore / license / CI / Dockerfile)
/// and returns its content plus the conventional filename.
class _TemplateSheet extends ConsumerStatefulWidget {
  const _TemplateSheet({required this.projectId});

  final Object projectId;

  static Map<String, (String, String)> _types(AppLocalizations l10n) => {
    'gitignores': (l10n.templateGitignore, '.gitignore'),
    'licenses': (l10n.templateLicense, 'LICENSE'),
    'gitlab_ci_ymls': (l10n.templateGitlabCi, '.gitlab-ci.yml'),
    'dockerfiles': (l10n.templateDockerfile, 'Dockerfile'),
  };

  static Future<({String filename, String content})?> show(
    BuildContext context, {
    required Object projectId,
  }) {
    return showModalBottomSheet<({String filename, String content})>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _TemplateSheet(projectId: projectId),
    );
  }

  @override
  ConsumerState<_TemplateSheet> createState() => _TemplateSheetState();
}

class _TemplateSheetState extends ConsumerState<_TemplateSheet> {
  String _type = 'gitignores';
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final names = ref.watch(
      fileTemplateNamesProvider((project: widget.projectId, type: _type)),
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(Insets.lg),
            child: Wrap(
              spacing: Insets.sm,
              children: [
                for (final e in _TemplateSheet._types(context.l10n).entries)
                  ChoiceChip(
                    label: Text(e.value.$1),
                    selected: _type == e.key,
                    onSelected: (_) => setState(() => _type = e.key),
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
          Expanded(
            child: names.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (list) => list.isEmpty
                  ? EmptyState(
                      icon: Icons.article_outlined,
                      title: context.l10n.noTemplates,
                    )
                  : ListView.builder(
                      controller: controller,
                      itemCount: list.length,
                      itemBuilder: (context, i) => ListTile(
                        dense: true,
                        title: Text(
                          list[i],
                          style: TextStyle(
                            fontFamily: GlamFonts.mono,
                            fontSize: 13,
                            color: colors.ink,
                          ),
                        ),
                        onTap: _busy ? null : () => _pick(list[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pick(String key) async {
    setState(() => _busy = true);
    try {
      final content = await ref
          .read(repositoryRepositoryProvider)
          .fileTemplate(widget.projectId, _type, key);
      if (mounted) {
        Navigator.pop(context, (
          filename: _TemplateSheet._types(context.l10n)[_type]!.$2,
          content: content,
        ));
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}
