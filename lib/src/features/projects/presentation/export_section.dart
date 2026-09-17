import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/presentation/admin_helpers.dart';
import 'package:share_plus/share_plus.dart';

/// Project export: request a tarball export and download it once the
/// instance finishes building it.
class ExportSection extends ConsumerWidget {
  const ExportSection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final export = ref.watch(projectExportProvider(project.id));
    final status = export.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Export project'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Insets.lg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.borderMd,
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  status?.statusLabel ??
                      (export.hasError ? 'Could not load status' : 'Loading…'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (status != null && status.finished)
                TextButton.icon(
                  icon: const Icon(Icons.download_outlined, size: 16),
                  label: const Text('Download'),
                  onPressed: () => _download(context, ref),
                ),
              if (status != null && !status.running)
                TextButton.icon(
                  icon: const Icon(Icons.inventory_2_outlined, size: 16),
                  label: Text(status.finished ? 'Re-export' : 'Export'),
                  onPressed: () => _request(context, ref),
                ),
              if (status != null && status.running)
                IconButton(
                  tooltip: 'Refresh',
                  icon: Icon(Icons.refresh, size: 18, color: colors.inkMuted),
                  onPressed: () =>
                      ref.invalidate(projectExportProvider(project.id)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _request(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(projectsRepositoryProvider).requestExport(project.id);
      ref.invalidate(projectExportProvider(project.id));
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }

  Future<void> _download(BuildContext context, WidgetRef ref) async {
    try {
      final bytes = await ref
          .read(projectsRepositoryProvider)
          .exportDownload(project.id);
      if (!context.mounted) {
        return;
      }
      final box = context.findRenderObject()! as RenderBox;
      unawaited(
        SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                bytes,
                name: '${project.path}-export.tar.gz',
                mimeType: 'application/gzip',
              ),
            ],
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
}
