import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/filter_menu.dart';
import 'package:glam/src/core/widgets/search_field.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/features/registry/application/registry_providers.dart';
import 'package:glam/src/features/registry/domain/registry_models.dart';
import 'package:glam/src/app/theme/app_typography.dart';
import 'package:glam/src/core/utils/l10n.dart';

String _label(GitLabPackage p) =>
    p.version.isEmpty ? p.name : '${p.name} ${p.version}';

/// Published packages for a project.
class ProjectPackagesTab extends ConsumerStatefulWidget {
  const ProjectPackagesTab({required this.projectId, super.key});

  final Object projectId;

  @override
  ConsumerState<ProjectPackagesTab> createState() => _ProjectPackagesTabState();
}

class _ProjectPackagesTabState extends ConsumerState<ProjectPackagesTab> {
  String? _type;
  String? _name;

  static const _types = [
    'composer',
    'conan',
    'debian',
    'generic',
    'golang',
    'helm',
    'maven',
    'npm',
    'nuget',
    'pypi',
    'rpm',
    'rubygems',
    'terraform_module',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filter = (project: widget.projectId, type: _type, name: _name);
    final state = ref.watch(projectPackagesProvider(filter));
    final notifier = ref.read(projectPackagesProvider(filter).notifier);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Insets.lg,
            Insets.sm,
            Insets.lg,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: SearchField(
                  hint: context.l10n.searchPackages,
                  onChanged: (v) => setState(() => _name = v),
                ),
              ),
              const SizedBox(width: Insets.sm),
              FilterMenu(
                title: context.l10n.type,
                current: _type,
                options: _types,
                onSelect: (v) => setState(() => _type = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: AsyncValueWidget(
            value: state,
            onRetry: notifier.refresh,
            data: (data) => PagedListView<GitLabPackage>(
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
                icon: Icons.inventory_2_outlined,
                title: context.l10n.noPackages,
              ),
              itemBuilder: (context, index) {
                final p = data.items[index];
                return ListTile(
                  leading: const Icon(Icons.inventory_2_outlined, size: 20),
                  title: Text(_label(p)),
                  subtitle: Text(
                    [
                      p.packageType,
                      if (p.status != 'default') p.status,
                      if (p.createdAt != null) Format.date(p.createdAt!),
                    ].join(' · '),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => _delete(context, ref, p),
                  ),
                  onTap: () => _files(context, p),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _files(BuildContext context, GitLabPackage p) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_label(p)),
        content: SizedBox(
          width: 460,
          child: _PackageFiles(projectId: widget.projectId, pkg: p),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.actionClose),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    GitLabPackage p,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deletePackage),
        content: Text(context.l10n.p0IsRemovedPermanently(_label(p))),
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
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(
            projectPackagesProvider((
              project: widget.projectId,
              type: _type,
              name: _name,
            )).notifier,
          )
          .deletePackage(p.id);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _PackageFiles extends ConsumerWidget {
  const _PackageFiles({required this.projectId, required this.pkg});

  final Object projectId;
  final GitLabPackage pkg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(packageFilesProvider((projectId, pkg.id)));

    return files.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('$e'),
      data: (list) => list.isEmpty
          ? Text(context.l10n.noFiles)
          : ListView(
              shrinkWrap: true,
              children: [
                for (final f in list)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.insert_drive_file_outlined,
                      size: 18,
                    ),
                    title: Text(
                      f.fileName,
                      style: const TextStyle(
                        fontFamily: GlamFonts.mono,
                        fontSize: 12,
                      ),
                    ),
                    trailing: f.size == null
                        ? null
                        : Text(Format.bytes(f.size!)),
                  ),
              ],
            ),
    );
  }
}
