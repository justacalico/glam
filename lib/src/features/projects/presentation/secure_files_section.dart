import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/domain/secure_file.dart';
import 'package:glam/src/features/projects/presentation/admin_helpers.dart';
import 'package:share_plus/share_plus.dart';

/// CI/CD secure files: list, upload, download, delete.
class SecureFilesSection extends ConsumerWidget {
  const SecureFilesSection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final files = ref.watch(projectSecureFilesProvider(project.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: SectionLabel('Secure files')),
            TextButton.icon(
              icon: const Icon(Icons.upload_file, size: 16),
              label: const Text('Upload'),
              onPressed: () => _upload(context, ref),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.borderMd,
            border: Border.all(color: colors.border),
          ),
          child: AsyncValueWidget(
            value: files,
            onRetry: () =>
                ref.invalidate(projectSecureFilesProvider(project.id)),
            data: (items) => items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(Insets.lg),
                    child: EmptyState(
                      icon: Icons.insert_drive_file_outlined,
                      title: 'No secure files',
                    ),
                  )
                : Column(
                    children: [
                      for (final f in items)
                        _SecureFileTile(
                          file: f,
                          onDownload: () => _download(context, ref, f),
                          onDelete: () => _delete(context, ref, f),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _upload(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.pickFile();
    if (picked == null || !context.mounted) {
      return;
    }
    final bytes = await picked.readAsBytes();
    try {
      await ref
          .read(projectsRepositoryProvider)
          .uploadSecureFile(project.id, bytes, picked.name);
      ref.invalidate(projectSecureFilesProvider(project.id));
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }

  Future<void> _download(
    BuildContext context,
    WidgetRef ref,
    SecureFile file,
  ) async {
    try {
      final bytes = await ref
          .read(projectsRepositoryProvider)
          .downloadSecureFile(project.id, file.id);
      if (!context.mounted) {
        return;
      }
      final box = context.findRenderObject()! as RenderBox;
      unawaited(
        SharePlus.instance.share(
          ShareParams(
            files: [XFile.fromData(bytes, name: file.name)],
            sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    SecureFile file,
  ) async {
    final ok = await confirmAdminAction(
      context,
      title: 'Delete ${file.name}?',
      body: 'Pipelines referencing it will fail.',
    );
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(projectsRepositoryProvider)
          .deleteSecureFile(project.id, file.id);
      ref.invalidate(projectSecureFilesProvider(project.id));
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }
}

class _SecureFileTile extends StatelessWidget {
  const _SecureFileTile({
    required this.file,
    required this.onDownload,
    required this.onDelete,
  });

  final SecureFile file;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final expired =
        file.expiresAt != null && file.expiresAt!.isBefore(DateTime.now());
    final checksum = file.checksum;
    final shortChecksum = checksum?.substring(0, checksum.length.clamp(0, 12));
    return ListTile(
      dense: true,
      leading: Icon(
        Icons.insert_drive_file_outlined,
        size: 18,
        color: expired ? colors.danger : colors.inkMuted,
      ),
      title: Text(file.name),
      subtitle: Text(
        [
          if (file.expiresAt != null)
            '${expired ? 'expired' : 'expires'} ${Format.date(file.expiresAt)}',
          if (shortChecksum != null)
            '${file.checksumAlgorithm ?? 'sha256'} $shortChecksum',
        ].join(' · '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.download_outlined, size: 18),
            tooltip: 'Download',
            onPressed: onDownload,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: 'Delete',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
