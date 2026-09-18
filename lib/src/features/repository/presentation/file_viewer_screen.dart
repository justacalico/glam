import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/code_viewer.dart';
import 'package:glam/src/core/widgets/markdown_viewer.dart';
import 'package:glam/src/features/repository/application/repository_providers.dart';
import 'package:glam/src/features/repository/domain/repo_models.dart';
import 'package:glam/src/features/repository/presentation/file_editor_screen.dart';
import 'package:glam/src/app/theme/app_typography.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// Full-screen file viewer: rendered markdown for docs, highlighted code
/// for everything else, with copy/raw actions.
class FileViewerScreen extends ConsumerWidget {
  const FileViewerScreen({
    required this.projectId,
    required this.path,
    this.ref,
    super.key,
  });

  final String projectId;
  final String path;
  final String? ref;

  bool get _isMarkdown => switch (path.split('.').last.toLowerCase()) {
    'md' || 'markdown' || 'mdown' => true,
    _ => false,
  };

  @override
  Widget build(BuildContext context, WidgetRef refScope) {
    final location = (project: projectId as Object, path: path, ref: ref);
    final file = refScope.watch(repoFileProvider(location));

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
              path,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontFamily: GlamFonts.mono),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: context.l10n.editFile,
            icon: const Icon(Icons.edit_outlined),
            onPressed: ref == null || file.value == null
                ? null
                : () async {
                    final committed = await FileEditorScreen.show(
                      context,
                      projectId: projectId,
                      branch: ref!,
                      path: path,
                      initialContent: file.value!.decodedContent,
                    );
                    if (committed == true) {
                      refScope.invalidate(repoFileProvider(location));
                    }
                  },
          ),
          IconButton(
            tooltip: context.l10n.copyContents,
            icon: const Icon(Icons.copy_outlined),
            onPressed: () => _copy(context, file.value),
          ),
          PopupMenuButton<String>(
            onSelected: (action) async {
              if (action == 'blame') {
                unawaited(
                  context.push(
                    Routes.projectBlame(projectId, ref: ref, path: path),
                  ),
                );
              }
              if (action == 'history') {
                unawaited(
                  context.push(
                    Routes.projectCommits(projectId, ref: ref, path: path),
                  ),
                );
              }
              if (action == 'delete' && ref != null) {
                await _delete(context, refScope);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'history',
                child: Text(context.l10n.fileHistory),
              ),
              PopupMenuItem(
                value: 'blame',
                child: Text(context.l10n.viewBlame),
              ),
              if (ref != null)
                PopupMenuItem(
                  value: 'delete',
                  child: Text(context.l10n.deleteFile),
                ),
            ],
          ),
        ],
      ),
      body: AsyncValueWidget(
        value: file,
        onRetry: () => refScope.invalidate(repoFileProvider(location)),
        data: (f) => _FileBody(file: f, renderMarkdown: _isMarkdown),
      ),
    );
  }

  Future<void> _copy(BuildContext context, RepoFile? file) async {
    if (file == null) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: file.decodedContent));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.copiedToClipboard)));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef refScope) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteNamedConfirm(path)),
        content: Text(context.l10n.aCommitRemovingThisFileWill),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await refScope
        .read(repositoryRepositoryProvider)
        .deleteFile(
          projectId,
          path,
          branch: ref!,
          commitMessage: 'Delete $path',
        );
    if (context.mounted) {
      Navigator.pop(context);
    }
  }
}

class _FileBody extends StatelessWidget {
  const _FileBody({required this.file, required this.renderMarkdown});

  final RepoFile file;
  final bool renderMarkdown;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = file.decodedContent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.lg,
            vertical: Insets.sm,
          ),
          color: colors.surfaceMuted,
          child: Text(
            context.l10n.linkSummary(Format.bytes(file.size), file.encoding),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.inkMuted),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: Insets.pagePadding,
            child: renderMarkdown
                ? MarkdownViewer(data: text)
                : CodeViewer(code: text, language: file.language),
          ),
        ),
      ],
    );
  }
}
