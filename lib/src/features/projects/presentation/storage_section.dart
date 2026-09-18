import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/presentation/admin_helpers.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// Storage usage plus repository housekeeping. Statistics need
/// maintainer rights; other roles see the housekeeping action only
/// when their instance allows it.
class StorageSection extends ConsumerWidget {
  const StorageSection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final stats = ref.watch(projectStatisticsProvider(project.id)).value;

    final rows = <(String, int)>[
      (context.l10n.storageRepository, stats?.repositorySize ?? 0),
      (context.l10n.storageLfs, stats?.lfsObjectsSize ?? 0),
      (context.l10n.storageJobArtifacts, stats?.jobArtifactsSize ?? 0),
      (context.l10n.storagePackages, stats?.packagesSize ?? 0),
      (context.l10n.storageUploads, stats?.uploadsSize ?? 0),
      (context.l10n.storageWiki, stats?.wikiSize ?? 0),
      (context.l10n.storageSnippets, stats?.snippetsSize ?? 0),
      (context.l10n.storageRegistry, stats?.containerRegistrySize ?? 0),
    ].where((r) => r.$2 > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(context.l10n.storageMaintenance),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Insets.lg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.borderMd,
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (stats != null) ...[
                Row(
                  children: [
                    Text(
                      context.l10n.storageTotal(
                        Format.bytes(stats.storageSize),
                      ),
                      style: theme.textTheme.titleSmall,
                    ),
                    SizedBox(width: Insets.md),
                    Text(
                      context.l10n.commitCount(
                        Format.compact(stats.commitCount),
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                if (rows.isNotEmpty) ...[
                  SizedBox(height: Insets.sm),
                  Wrap(
                    spacing: Insets.lg,
                    runSpacing: Insets.xs,
                    children: [
                      for (final r in rows)
                        Text(
                          context.l10n.storageStatPair(
                            r.$1,
                            Format.bytes(r.$2),
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ],
                SizedBox(height: Insets.md),
              ] else
                Text(
                  context.l10n.storageStatisticsAreOnlyVisibleTo,
                  style: theme.textTheme.bodySmall,
                ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.housekeepingOptimizesTheRepositoryGcRepack,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => _housekeeping(context, ref),
                    child: Text(context.l10n.runHousekeeping),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _housekeeping(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(projectsRepositoryProvider).housekeeping(project.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.housekeepingStarted)),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }
}
