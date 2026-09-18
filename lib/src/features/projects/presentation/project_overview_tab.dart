import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/markdown_viewer.dart';
import 'package:glam/src/core/widgets/section_header.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/repository/application/repository_providers.dart';

/// The Overview tab: metadata, language breakdown, rendered README.
class ProjectOverviewTab extends ConsumerWidget {
  const ProjectOverviewTab({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final readme = ref.watch(
      readmeProvider((project: project.id, ref: project.defaultBranch)),
    );
    final languages = ref.watch(languagesProvider(project.id));

    return ListView(
      padding: Insets.pagePadding,
      children: [
        _InfoCard(project: project),
        if (project.topics.isNotEmpty) ...[
          const SizedBox(height: Insets.lg),
          Wrap(
            spacing: Insets.sm,
            runSpacing: Insets.sm,
            children: [
              for (final topic in project.topics)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Insets.sm + 2,
                    vertical: Insets.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.accentSoft,
                    borderRadius: Radii.borderPill,
                  ),
                  child: Text(
                    topic,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.accent,
                    ),
                  ),
                ),
            ],
          ),
        ],
        languages.whenData((langs) {
              if (langs.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Languages'),
                  _LanguageBar(languages: langs),
                ],
              );
            }).value ??
            const SizedBox.shrink(),
        readme.whenData((file) {
              if (file == null) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: file.name),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(Insets.lg),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: Radii.borderMd,
                      border: Border.all(color: colors.border),
                    ),
                    child:
                        file.name.toLowerCase().endsWith('.md') ||
                            file.name.toLowerCase().endsWith('.markdown')
                        ? MarkdownViewer(data: file.decodedContent)
                        : Text(
                            file.decodedContent,
                            style: theme.textTheme.bodySmall,
                          ),
                  ),
                ],
              );
            }).value ??
            const SizedBox.shrink(),
        const SizedBox(height: Insets.xl),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final rows = <(IconData, String, String)>[
      (Icons.folder_outlined, 'Path', project.pathWithNamespace),
      if (project.defaultBranch != null)
        (Icons.account_tree_outlined, 'Default branch', project.defaultBranch!),
      if (project.createdAt != null)
        (
          Icons.calendar_today_outlined,
          'Created',
          Format.date(project.createdAt),
        ),
      if (project.lastActivityAt != null)
        (
          Icons.schedule,
          'Last activity',
          Format.relative(project.lastActivityAt),
        ),
      if (project.owner != null)
        (Icons.person_outline, 'Owner', project.owner!.name),
      if (project.forkedFromId != null)
        (Icons.fork_right, 'Forked from', '#${project.forkedFromId}'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Radii.borderMd,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: colors.border),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Insets.lg,
                vertical: Insets.md,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 160,
                    child: Row(
                      children: [
                        Icon(rows[i].$1, size: 16, color: colors.inkMuted),
                        const SizedBox(width: Insets.md),
                        Flexible(
                          child: Text(
                            rows[i].$2,
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rows[i].$3,
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LanguageBar extends StatelessWidget {
  const _LanguageBar({required this.languages});

  final Map<String, double> languages;

  static const _palette = [
    Color(0xFF5B3EC4),
    Color(0xFFFC6D26),
    Color(0xFF217645),
    Color(0xFF1F65C0),
    Color(0xFFC72E2E),
    Color(0xFF9E6A03),
    Color(0xFF6E6E82),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final entries = languages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final shown = entries.take(6).toList();
    final total = entries.fold<double>(0, (a, e) => a + e.value);

    return Container(
      padding: const EdgeInsets.all(Insets.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Radii.borderMd,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: Radii.borderSm,
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  for (var i = 0; i < shown.length; i++)
                    Expanded(
                      flex: (shown[i].value / total * 1000).round(),
                      child: ColoredBox(color: _palette[i % _palette.length]),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Insets.md),
          Wrap(
            spacing: Insets.lg,
            runSpacing: Insets.sm,
            children: [
              for (var i = 0; i < shown.length; i++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _palette[i % _palette.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: Insets.xs + 2),
                    Text(
                      '${shown[i].key} ${Format.percent(shown[i].value)}',
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
