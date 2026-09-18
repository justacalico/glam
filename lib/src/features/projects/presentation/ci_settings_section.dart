import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/presentation/admin_helpers.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// CI/CD project settings: pipeline visibility, job timeout, caching and
/// deployment options.
class CiSettingsSection extends ConsumerWidget {
  const CiSettingsSection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(context.l10n.ciCd),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.borderMd,
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              _GateSwitch(
                label: context.l10n.publicPipelines,
                value: project.publicJobs ?? false,
                onChanged: (v) => _set(context, ref, publicJobs: v),
              ),
              _divider(colors),
              _TimeoutTile(
                seconds: project.buildTimeout,
                onEdit: () => _editTimeout(context, ref),
              ),
              _divider(colors),
              _ChoiceTile(
                label: context.l10n.autoCancelRedundantPipelines,
                value: project.autoCancelPendingPipelines ?? 'enabled',
                options: const {'enabled': 'Enabled', 'disabled': 'Disabled'},
                onChanged: (v) =>
                    _set(context, ref, autoCancelPendingPipelines: v),
              ),
              _divider(colors),
              _GateSwitch(
                label: context.l10n.forwardDeploymentVariables,
                value: project.ciForwardDeploymentEnabled ?? false,
                onChanged: (v) =>
                    _set(context, ref, ciForwardDeploymentEnabled: v),
              ),
              _divider(colors),
              _GateSwitch(
                label: context.l10n.separateCachesPerBranch,
                value: project.ciSeparatedCaches ?? false,
                onChanged: (v) => _set(context, ref, ciSeparatedCaches: v),
              ),
              _divider(colors),
              _GateSwitch(
                label: context.l10n.keepLatestArtifacts,
                value: project.keepLatestArtifact ?? false,
                onChanged: (v) => _set(context, ref, keepLatestArtifact: v),
              ),
              _divider(colors),
              _PathTile(
                value: project.ciConfigPath,
                onEdit: () => _editPath(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _set(
    BuildContext context,
    WidgetRef ref, {
    bool? publicJobs,
    int? buildTimeout,
    String? autoCancelPendingPipelines,
    bool? ciForwardDeploymentEnabled,
    bool? ciSeparatedCaches,
    bool? keepLatestArtifact,
    String? ciConfigPath,
  }) async {
    try {
      await ref
          .read(projectsRepositoryProvider)
          .updateProject(
            project.id,
            publicJobs: publicJobs,
            buildTimeout: buildTimeout,
            autoCancelPendingPipelines: autoCancelPendingPipelines,
            ciForwardDeploymentEnabled: ciForwardDeploymentEnabled,
            ciSeparatedCaches: ciSeparatedCaches,
            keepLatestArtifact: keepLatestArtifact,
            ciConfigPath: ciConfigPath,
          );
      ref.invalidate(projectProvider(project.id.toString()));
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }

  Future<void> _editTimeout(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
      text: project.buildTimeout?.toString() ?? '',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.jobTimeout),
        content: SizedBox(
          width: 320,
          child: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: context.l10n.timeoutSeconds,
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => Navigator.pop(context, true),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.actionSave),
          ),
        ],
      ),
    );
    final parsed = int.tryParse(controller.text.trim());
    controller.dispose();
    if (ok != true || parsed == null || parsed < 0 || !context.mounted) {
      return;
    }
    await _set(context, ref, buildTimeout: parsed);
  }

  Future<void> _editPath(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: project.ciConfigPath ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.ciCdConfigPath),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '.gitlab-ci.yml',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => Navigator.pop(context, true),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.actionSave),
          ),
        ],
      ),
    );
    final text = controller.text.trim();
    controller.dispose();
    if (ok != true || !context.mounted) {
      return;
    }
    await _set(context, ref, ciConfigPath: text);
  }

  Widget _divider(GlamColors colors) =>
      Divider(height: 1, color: colors.border, indent: Insets.lg);
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox.shrink(),
        style: theme.textTheme.bodyMedium,
        items: [
          for (final e in options.entries)
            DropdownMenuItem(value: e.key, child: Text(e.value)),
        ],
        onChanged: (v) {
          if (v != null) {
            onChanged(v);
          }
        },
      ),
    );
  }
}

class _GateSwitch extends StatelessWidget {
  const _GateSwitch({
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
      dense: true,
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _TimeoutTile extends StatelessWidget {
  const _TimeoutTile({required this.seconds, required this.onEdit});

  final int? seconds;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      dense: true,
      title: Text(context.l10n.jobTimeout),
      subtitle: Text(
        seconds == null
            ? context.l10n.templateDefault
            : context.l10n.secondsValue('$seconds'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(Icons.edit_outlined, size: 16, color: colors.inkMuted),
      onTap: onEdit,
    );
  }
}

class _PathTile extends StatelessWidget {
  const _PathTile({required this.value, required this.onEdit});

  final String? value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      dense: true,
      title: Text(context.l10n.ciCdConfigPath),
      subtitle: Text(
        value == null || value!.isEmpty ? '.gitlab-ci.yml' : value!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(Icons.edit_outlined, size: 16, color: colors.inkMuted),
      onTap: onEdit,
    );
  }
}
