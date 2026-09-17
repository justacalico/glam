import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/features/pipelines/application/pipelines_providers.dart';
import 'package:glam/src/features/pipelines/domain/artifact_entry.dart';
import 'package:share_plus/share_plus.dart';
import 'package:glam/src/app/theme/app_typography.dart';

/// Browses a job's artifact archive. Newer GitLab versions list
/// entries from metadata; older ones fall back to unpacking the zip.
class JobArtifactsScreen extends ConsumerWidget {
  const JobArtifactsScreen({
    required this.projectId,
    required this.jobId,
    super.key,
  });

  final Object projectId;
  final int jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = (project: projectId, id: jobId);
    final entries = ref.watch(jobArtifactsProvider(loc));
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: Text('Artifacts · job #$jobId')),
      body: AsyncValueWidget<List<ArtifactEntry>>(
        value: entries,
        onRetry: () => ref.invalidate(jobArtifactsProvider(loc)),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.archive_outlined,
              title: 'Archive is empty',
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) =>
                Divider(color: colors.border, height: 1),
            itemBuilder: (context, index) {
              final e = items[index];
              return ListTile(
                dense: true,
                leading: const Icon(Icons.insert_drive_file_outlined, size: 18),
                title: Text(
                  e.path,
                  style: const TextStyle(
                    fontFamily: GlamFonts.mono,
                    fontSize: 12.5,
                  ),
                ),
                trailing: Text(
                  Format.bytes(e.size),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: () => unawaited(
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    useSafeArea: true,
                    builder: (context) => _ArtifactSheet(loc: loc, entry: e),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Shows a single artifact: text in place, anything else via share.
class _ArtifactSheet extends ConsumerWidget {
  const _ArtifactSheet({required this.loc, required this.entry});

  final JobRef loc;
  final ArtifactEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = ref.watch(
      jobArtifactFileProvider((job: loc, path: entry.path)),
    );
    final colors = context.colors;
    final name = entry.path.split('/').last;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entry.path,
                    style: const TextStyle(
                      fontFamily: GlamFonts.mono,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                file.maybeWhen(
                  data: (bytes) => Builder(
                    builder: (buttonContext) => IconButton(
                      tooltip: 'Share',
                      icon: const Icon(Icons.ios_share, size: 18),
                      onPressed: () {
                        // iPad requires an anchor rect for the share sheet.
                        final box =
                            buttonContext.findRenderObject()! as RenderBox;
                        unawaited(
                          SharePlus.instance.share(
                            ShareParams(
                              files: [XFile.fromData(bytes, name: name)],
                              sharePositionOrigin:
                                  box.localToGlobal(Offset.zero) & box.size,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.sm),
          Expanded(
            child: AsyncValueWidget<Uint8List>(
              value: file,
              onRetry: () => ref.invalidate(
                jobArtifactFileProvider((job: loc, path: entry.path)),
              ),
              data: (bytes) {
                final text = _asText(bytes);
                if (text == null) {
                  return Center(
                    child: Text(
                      'Binary file — use Share to save it.',
                      style: TextStyle(color: colors.inkMuted),
                    ),
                  );
                }
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: Insets.lg),
                  decoration: BoxDecoration(
                    color: colors.codeBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(Insets.md),
                    child: SelectableText(
                      text,
                      style: const TextStyle(
                        fontFamily: GlamFonts.mono,
                        fontSize: 11.5,
                        height: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: Insets.lg),
        ],
      ),
    );
  }

  /// Decodes the first 256 KB as text, or null for binary files.
  /// Large logs stay truncated instead of stalling the UI.
  static String? _asText(Uint8List bytes) {
    const cap = 256 * 1024;
    final truncated = bytes.length > cap;
    final chunk = truncated ? bytes.sublist(0, cap) : bytes;
    if (chunk.contains(0)) {
      return null;
    }
    try {
      final text = utf8.decode(chunk, allowMalformed: truncated);
      return truncated
          ? '$text\n\n[truncated — use Share for the full file]'
          : text;
    } on FormatException {
      return null;
    }
  }
}
