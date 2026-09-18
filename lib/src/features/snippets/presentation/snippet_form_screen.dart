import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/features/snippets/application/snippets_providers.dart';
import 'package:glam/src/features/snippets/domain/snippet.dart';
import 'package:glam/src/app/theme/app_typography.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// Create/edit form for a snippet. Dialog on wide screens, sheet on
/// phones.
class SnippetFormScreen extends ConsumerStatefulWidget {
  const SnippetFormScreen({
    this.snippet,
    this.projectId,
    this.rawContent,
    super.key,
  });

  /// Non-null = edit mode.
  final Snippet? snippet;
  final Object? projectId;

  /// Current file contents, passed in so the editor starts filled.
  final String? rawContent;

  static Future<bool> show(
    BuildContext context, {
    Snippet? snippet,
    Object? projectId,
    String? rawContent,
  }) async {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final child = SnippetFormScreen(
      snippet: snippet,
      projectId: projectId,
      rawContent: rawContent,
    );
    final result = wide
        ? await showDialog<bool>(
            context: context,
            builder: (_) => Dialog(
              clipBehavior: Clip.antiAlias,
              insetPadding: const EdgeInsets.all(Insets.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: child,
              ),
            ),
          )
        : await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            showDragHandle: true,
            builder: (_) => child,
          );
    return result ?? false;
  }

  @override
  ConsumerState<SnippetFormScreen> createState() => _SnippetFormScreenState();
}

class _SnippetFormScreenState extends ConsumerState<SnippetFormScreen> {
  late final TextEditingController _title;
  late final TextEditingController _fileName;
  late final TextEditingController _description;
  late final TextEditingController _content;
  String _visibility = 'private';
  var _saving = false;
  String? _error;

  bool get _editing => widget.snippet != null;

  @override
  void initState() {
    super.initState();
    final s = widget.snippet;
    _title = TextEditingController(text: s?.title ?? '');
    _fileName = TextEditingController(text: s?.fileName ?? '');
    _description = TextEditingController(text: s?.description ?? '');
    _content = TextEditingController(text: widget.rawContent ?? '');
    _visibility = s?.visibility ?? 'private';
  }

  @override
  void dispose() {
    _title.dispose();
    _fileName.dispose();
    _description.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final fileName = _fileName.text.trim();
    if (title.isEmpty || fileName.isEmpty || _saving) {
      setState(
        () => _error = title.isEmpty
            ? context.l10n.titleRequired
            : fileName.isEmpty
            ? context.l10n.fileNameRequired
            : null,
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(snippetsRepositoryProvider);
    try {
      if (_editing) {
        await repo.update(
          widget.snippet!.id,
          projectId: widget.projectId,
          title: title,
          fileName: fileName,
          content: _content.text,
          description: _description.text.trim(),
          visibility: _visibility,
        );
      } else {
        await repo.create(
          projectId: widget.projectId,
          title: title,
          fileName: fileName,
          content: _content.text,
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          visibility: _visibility,
        );
      }
      if (mounted) {
        context.pop(true);
      }
    } on ApiException catch (e) {
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } on Object {
      setState(() {
        _saving = false;
        _error = context.l10n.snippetSaveFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: Insets.lg,
        right: Insets.lg,
        top: Insets.lg,
        bottom: Insets.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _editing ? context.l10n.editSnippet : context.l10n.newSnippet,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: Insets.lg),
          TextField(
            controller: _title,
            autofocus: !_editing,
            decoration: InputDecoration(
              labelText: context.l10n.fieldTitle,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Insets.md),
          TextField(
            controller: _fileName,
            decoration: InputDecoration(
              labelText: context.l10n.fileName,
              hintText: 'main.dart',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Insets.md),
          TextField(
            controller: _description,
            decoration: InputDecoration(
              labelText: context.l10n.fieldDescription,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Insets.md),
          TextField(
            controller: _content,
            minLines: 8,
            maxLines: 16,
            style: const TextStyle(fontFamily: GlamFonts.mono),
            decoration: InputDecoration(
              labelText: context.l10n.content,
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Insets.md),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'private',
                label: Text(context.l10n.visibilityPrivate),
              ),
              ButtonSegment(
                value: 'internal',
                label: Text(context.l10n.visibilityInternal),
              ),
              ButtonSegment(
                value: 'public',
                label: Text(context.l10n.visibilityPublic),
              ),
            ],
            selected: {_visibility},
            onSelectionChanged: (s) => setState(() => _visibility = s.first),
            showSelectedIcon: false,
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: Insets.sm),
              child: Text(_error!, style: TextStyle(color: colors.danger)),
            ),
          const SizedBox(height: Insets.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _saving ? null : () => context.pop(false),
                child: Text(context.l10n.actionCancel),
              ),
              const SizedBox(width: Insets.sm),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _editing
                            ? context.l10n.actionSave
                            : context.l10n.createSnippet,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
