import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/code_viewer.dart';
import 'package:glam/src/core/widgets/markdown_viewer.dart';
import 'package:glam/src/features/repository/application/repository_providers.dart';
import 'package:glam/src/features/repository/domain/repo_models.dart';

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
              ).textTheme.labelSmall?.copyWith(fontFamily: 'JetBrains Mono'),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Copy contents',
            icon: const Icon(Icons.copy_outlined),
            onPressed: () => _copy(context, file.value),
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
      ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
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
            '${Format.bytes(file.size)} · ${file.encoding}',
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
