import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/presentation/admin_helpers.dart';

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
      ('Repository', stats?.repositorySize ?? 0),
      ('LFS objects', stats?.lfsObjectsSize ?? 0),
      ('Job artifacts', stats?.jobArtifactsSize ?? 0),
      ('Packages', stats?.packagesSize ?? 0),
      ('Uploads', stats?.uploadsSize ?? 0),
      ('Wiki', stats?.wikiSize ?? 0),
      ('Snippets', stats?.snippetsSize ?? 0),
      ('Container registry', stats?.containerRegistrySize ?? 0),
    ].where((r) => r.$2 > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Storage & maintenance'),
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
                      'Total ${Format.bytes(stats.storageSize)}',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(width: Insets.md),
                    Text(
                      '${Format.compact(stats.commitCount)} commits',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                if (rows.isNotEmpty) ...[
                  const SizedBox(height: Insets.sm),
                  Wrap(
                    spacing: Insets.lg,
                    runSpacing: Insets.xs,
                    children: [
                      for (final r in rows)
                        Text(
                          '${r.$1} ${Format.bytes(r.$2)}',
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: Insets.md),
              ] else
                Text(
                  'Storage statistics are only visible to maintainers.',
                  style: theme.textTheme.bodySmall,
                ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Housekeeping optimizes the repository (gc, repack).',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => _housekeeping(context, ref),
                    child: const Text('Run housekeeping'),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Housekeeping started')));
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }
}
