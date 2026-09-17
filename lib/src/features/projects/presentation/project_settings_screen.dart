import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/ci_variables_section.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/projects/domain/namespace.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/presentation/access_tokens_section.dart';
import 'package:glam/src/features/projects/presentation/approval_rules_section.dart';
import 'package:glam/src/features/projects/presentation/ci_settings_section.dart';
import 'package:glam/src/features/projects/presentation/deploy_keys_section.dart';
import 'package:glam/src/features/projects/presentation/deploy_tokens_section.dart';
import 'package:glam/src/features/projects/presentation/integrations_section.dart';
import 'package:glam/src/features/projects/presentation/merge_settings_section.dart';
import 'package:glam/src/features/projects/presentation/protected_refs_section.dart';
import 'package:glam/src/features/projects/presentation/runners_section.dart';
import 'package:glam/src/features/projects/presentation/sharing_section.dart';
import 'package:glam/src/features/projects/presentation/triggers_section.dart';
import 'package:glam/src/features/projects/presentation/webhooks_section.dart';

/// Project settings: general info, feature toggles, archive, and CI/CD
/// variables.
class ProjectSettingsScreen extends ConsumerWidget {
  const ProjectSettingsScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectProvider(projectId));

    return Scaffold(
      appBar: AppBar(title: const Text('Project settings')),
      body: AsyncValueWidget<Project>(
        value: project,
        onRetry: () => ref.invalidate(projectProvider(projectId)),
        data: (p) => ListView(
          padding: Insets.pagePadding,
          children: [
            _GeneralSection(project: p),
            const SizedBox(height: Insets.xl),
            _FeaturesSection(project: p),
            const SizedBox(height: Insets.xl),
            _VariablesSection(project: p),
            const SizedBox(height: Insets.xl),
            WebhooksSection(project: p),
            const SizedBox(height: Insets.xl),
            IntegrationsSection(project: p),
            const SizedBox(height: Insets.xl),
            DeployTokensSection(project: p),
            const SizedBox(height: Insets.xl),
            DeployKeysSection(project: p),
            const SizedBox(height: Insets.xl),
            ProtectedBranchesSection(project: p),
            const SizedBox(height: Insets.xl),
            ProtectedTagsSection(project: p),
            const SizedBox(height: Insets.xl),
            ProtectedEnvironmentsSection(project: p),
            const SizedBox(height: Insets.xl),
            FreezePeriodsSection(project: p),
            const SizedBox(height: Insets.xl),
            RunnersSection(project: p),
            const SizedBox(height: Insets.xl),
            CiSettingsSection(project: p),
            const SizedBox(height: Insets.xl),
            ApprovalRulesSection(project: p),
            const SizedBox(height: Insets.xl),
            MergeSettingsSection(project: p),
            const SizedBox(height: Insets.xl),
            SharingSection(project: p),
            const SizedBox(height: Insets.xl),
            AccessTokensSection(project: p),
            const SizedBox(height: Insets.xl),
            TriggersSection(project: p),
            const SizedBox(height: Insets.xl),
            _DangerSection(project: p),
            const SizedBox(height: Insets.xl),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.sm),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _GeneralSection extends ConsumerStatefulWidget {
  const _GeneralSection({required this.project});

  final Project project;

  @override
  ConsumerState<_GeneralSection> createState() => _GeneralSectionState();
}

class _GeneralSectionState extends ConsumerState<_GeneralSection> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _topics;
  late String _visibility;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.project.name);
    _description = TextEditingController(text: widget.project.description);
    _topics = TextEditingController(text: widget.project.topics.join(', '));
    _visibility = widget.project.visibility ?? 'private';
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _topics.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(projectsRepositoryProvider)
          .updateProject(
            widget.project.id,
            name: _name.text.trim(),
            description: _description.text.trim(),
            visibility: _visibility,
            topics: _topics.text
                .split(',')
                .map((t) => t.trim())
                .where((t) => t.isNotEmpty)
                .toList(),
          );
      ref.invalidate(projectProvider(widget.project.id.toString()));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Settings saved')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('General'),
        Container(
          padding: const EdgeInsets.all(Insets.lg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.borderMd,
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Project name'),
              ),
              const SizedBox(height: Insets.md),
              TextField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: Insets.md),
              DropdownButtonFormField<String>(
                initialValue: _visibility,
                decoration: const InputDecoration(labelText: 'Visibility'),
                items: const [
                  DropdownMenuItem(value: 'private', child: Text('Private')),
                  DropdownMenuItem(value: 'internal', child: Text('Internal')),
                  DropdownMenuItem(value: 'public', child: Text('Public')),
                ],
                onChanged: (v) => setState(() => _visibility = v!),
              ),
              const SizedBox(height: Insets.md),
              TextField(
                controller: _topics,
                decoration: const InputDecoration(
                  labelText: 'Topics (comma separated)',
                ),
              ),
              const SizedBox(height: Insets.lg),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeaturesSection extends ConsumerWidget {
  const _FeaturesSection({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Features'),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.borderMd,
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              _FeatureSwitch(
                label: 'Issues',
                value: project.issuesEnabled,
                onChanged: (v) => _set(ref, issuesEnabled: v),
              ),
              _divider(colors),
              _FeatureSwitch(
                label: 'Merge requests',
                value: project.mergeRequestsEnabled,
                onChanged: (v) => _set(ref, mergeRequestsEnabled: v),
              ),
              _divider(colors),
              _FeatureSwitch(
                label: 'Wiki',
                value: project.wikiEnabled,
                onChanged: (v) => _set(ref, wikiEnabled: v),
              ),
              _divider(colors),
              _FeatureSwitch(
                label: 'Snippets',
                value: project.snippetsEnabled,
                onChanged: (v) => _set(ref, snippetsEnabled: v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _set(
    WidgetRef ref, {
    bool? issuesEnabled,
    bool? mergeRequestsEnabled,
    bool? wikiEnabled,
    bool? snippetsEnabled,
  }) async {
    await ref
        .read(projectsRepositoryProvider)
        .updateProject(
          project.id,
          issuesEnabled: issuesEnabled,
          mergeRequestsEnabled: mergeRequestsEnabled,
          wikiEnabled: wikiEnabled,
          snippetsEnabled: snippetsEnabled,
        );
    ref.invalidate(projectProvider(project.id.toString()));
  }

  Widget _divider(GlamColors colors) =>
      Divider(height: 1, color: colors.border, indent: Insets.lg);
}

class _FeatureSwitch extends StatelessWidget {
  const _FeatureSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      dense: true,
    );
  }
}

class _VariablesSection extends ConsumerWidget {
  const _VariablesSection({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CiVariablesSection(
      variables: ref.watch(projectVariablesProvider(project.id)),
      onSave: (existing, fields) async {
        final repo = ref.read(projectsRepositoryProvider);
        if (existing == null) {
          await repo.createVariable(
            project.id,
            key: fields.key,
            value: fields.value,
            protected_: fields.protected_,
            masked: fields.masked,
            environmentScope: fields.environmentScope,
          );
        } else {
          await repo.updateVariable(
            project.id,
            existing.key,
            value: fields.value,
            protected_: fields.protected_,
            masked: fields.masked,
            environmentScope: fields.environmentScope,
          );
        }
        ref.invalidate(projectVariablesProvider(project.id));
      },
      onDelete: (v) async {
        await ref
            .read(projectsRepositoryProvider)
            .deleteVariable(project.id, v.key);
        ref.invalidate(projectVariablesProvider(project.id));
      },
    );
  }
}

class _DangerSection extends ConsumerWidget {
  const _DangerSection({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Danger zone'),
        Container(
          padding: const EdgeInsets.all(Insets.lg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.borderMd,
            border: Border.all(color: colors.danger.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.archived
                          ? 'This project is archived.'
                          : 'Archiving makes the project read-only.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      final repo = ref.read(projectsRepositoryProvider);
                      if (project.archived) {
                        await repo.unarchive(project.id);
                      } else {
                        await repo.archive(project.id);
                      }
                      ref.invalidate(projectProvider(project.id.toString()));
                    },
                    child: Text(project.archived ? 'Unarchive' : 'Archive'),
                  ),
                ],
              ),
              const SizedBox(height: Insets.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Move the project to another namespace.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => _transfer(context, ref),
                    child: const Text('Transfer'),
                  ),
                ],
              ),
              const SizedBox(height: Insets.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Deleting removes the project and its repository.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => _deleteProject(context, ref),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _transfer(BuildContext context, WidgetRef ref) async {
    GitlabNamespace? picked;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final namespaces = ref.watch(namespacesProvider);
          return AlertDialog(
            title: Text('Transfer ${project.name}?'),
            content: SizedBox(
              width: 360,
              child: namespaces.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(Insets.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('$e'),
                data: (items) => DropdownButtonFormField<GitlabNamespace>(
                  decoration: const InputDecoration(
                    labelText: 'New namespace',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final n in items)
                      DropdownMenuItem(
                        value: n,
                        child: Text(n.fullPath ?? n.path),
                      ),
                  ],
                  onChanged: (v) => picked = v,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Transfer'),
              ),
            ],
          );
        },
      ),
    );
    final target = picked;
    if (confirmed != true || target == null || !context.mounted) {
      return;
    }
    try {
      final moved = await ref
          .read(projectsRepositoryProvider)
          .transfer(project.id, namespace: target.id);
      ref
        ..invalidate(projectsListProvider)
        ..invalidate(projectProvider);
      if (context.mounted) {
        context.go(Routes.project(moved.id));
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _deleteProject(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${project.pathWithNamespace}?'),
        content: const Text(
          'This deletes the project and its repository. On gitlab.com '
          'deletion is delayed; on self-managed it may be immediate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete project'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref.read(projectsRepositoryProvider).deleteProject(project.id);
      ref.invalidate(projectsListProvider);
      if (context.mounted) {
        context.go(Routes.projects);
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}
