import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/markdown_viewer.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/features/wiki/application/wiki_providers.dart';
import 'package:glam/src/features/wiki/domain/wiki_page.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// Wiki pages tab inside project detail.
class ProjectWikiTab extends ConsumerWidget {
  const ProjectWikiTab({required this.projectId, super.key});

  final Object projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final list = ref.watch(wikiPagesProvider(projectId));
    final notifier = ref.read(wikiPagesProvider(projectId).notifier);

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.lg,
              Insets.sm,
              Insets.lg,
              Insets.xs,
            ),
            child: IconButton(
              tooltip: context.l10n.newPage,
              icon: const Icon(Icons.add),
              onPressed: () => unawaited(
                WikiFormScreen.show(context, projectId: projectId).then((
                  saved,
                ) {
                  if (saved) {
                    ref.invalidate(wikiPagesProvider);
                  }
                }),
              ),
            ),
          ),
        ),
        Expanded(
          child: AsyncValueWidget(
            value: list,
            onRetry: notifier.refresh,
            data: (data) => PagedListView(
              state: data,
              onLoadMore: notifier.loadMore,
              onRefresh: notifier.refresh,
              padding: const EdgeInsets.symmetric(vertical: Insets.sm),
              separator: Divider(
                height: 1,
                color: colors.border,
                indent: Insets.lg,
              ),
              empty: EmptyState(
                icon: Icons.menu_book_outlined,
                title: context.l10n.noWikiPages,
              ),
              itemBuilder: (context, index) {
                final page = data.items[index];
                return ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.article_outlined,
                    size: 18,
                    color: colors.inkMuted,
                  ),
                  title: Text(page.title),
                  subtitle: Text(page.slug),
                  onTap: () => unawaited(
                    context.push(
                      '/projects/${Uri.encodeComponent('$projectId')}'
                      '/wiki/${Uri.encodeComponent(page.slug)}',
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// One rendered wiki page.
class WikiPageScreen extends ConsumerWidget {
  const WikiPageScreen({required this.loc, super.key});

  final WikiPageRef loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(wikiPageProvider(loc));

    return Scaffold(
      appBar: AppBar(
        title: Text(page.value?.title ?? context.l10n.tabWiki),
        actions: [
          IconButton(
            tooltip: context.l10n.actionEdit,
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: page.value == null
                ? null
                : () => unawaited(
                    WikiFormScreen.show(
                      context,
                      projectId: loc.projectId,
                      page: page.value,
                    ).then((saved) {
                      if (saved) {
                        ref
                          ..invalidate(wikiPageProvider)
                          ..invalidate(wikiPagesProvider);
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
        value: page,
        onRetry: () => ref.invalidate(wikiPageProvider(loc)),
        data: (p) => SingleChildScrollView(
          padding: Insets.pagePadding,
          child: MarkdownViewer(data: p.content ?? ''),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deletePage),
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
    await ref.read(wikiRepositoryProvider).delete(loc.projectId, loc.slug);
    ref.invalidate(wikiPagesProvider);
    if (context.mounted) {
      context.pop();
    }
  }
}

/// Create/edit form for a wiki page.
class WikiFormScreen extends ConsumerStatefulWidget {
  const WikiFormScreen({required this.projectId, this.page, super.key});

  final Object projectId;

  /// Non-null = edit mode.
  final WikiPage? page;

  static Future<bool> show(
    BuildContext context, {
    required Object projectId,
    WikiPage? page,
  }) async {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final child = WikiFormScreen(projectId: projectId, page: page);
    final result = wide
        ? await showDialog<bool>(
            context: context,
            builder: (_) => Dialog(
              clipBehavior: Clip.antiAlias,
              insetPadding: const EdgeInsets.all(Insets.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
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
  ConsumerState<WikiFormScreen> createState() => _WikiFormScreenState();
}

class _WikiFormScreenState extends ConsumerState<WikiFormScreen> {
  late final TextEditingController _title;
  late final TextEditingController _content;
  var _saving = false;
  var _uploading = false;
  String? _error;

  bool get _editing => widget.page != null;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.page?.title ?? '');
    _content = TextEditingController(text: widget.page?.content ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty || _content.text.trim().isEmpty || _saving) {
      setState(
        () => _error = title.isEmpty
            ? context.l10n.titleRequired
            : context.l10n.contentRequired,
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(wikiRepositoryProvider);
    try {
      if (_editing) {
        await repo.update(
          widget.projectId,
          widget.page!.slug,
          title: title,
          content: _content.text,
        );
      } else {
        await repo.create(
          widget.projectId,
          title: title,
          content: _content.text,
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
        _error = context.l10n.pageSaveFailed;
      });
    }
  }

  Future<void> _attach() async {
    final file = await FilePicker.pickFile();
    if (file == null || !mounted) {
      return;
    }
    final bytes = await file.readAsBytes();
    setState(() => _uploading = true);
    try {
      final markdown = await ref
          .read(wikiRepositoryProvider)
          .uploadAttachment(widget.projectId, bytes, file.name);
      final text = _content.text;
      final sel = _content.selection;
      final at = sel.isValid ? sel.start : text.length;
      _content
        ..text = '${text.substring(0, at)}$markdown${text.substring(at)}'
        ..selection = TextSelection.collapsed(offset: at + markdown.length);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.composerUploadFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
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
            _editing ? context.l10n.editPage : context.l10n.newWikiPage,
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
            controller: _content,
            minLines: 10,
            maxLines: 18,
            decoration: InputDecoration(
              labelText: context.l10n.content,
              hintText: context.l10n.markdown,
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _uploading ? null : _attach,
              icon: _uploading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.attach_file, size: 16),
              label: Text(context.l10n.attachFile),
            ),
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
                            : context.l10n.createPage,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
