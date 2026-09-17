import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/presentation/admin_helpers.dart';

/// Merge-request workflow settings: merge method, squash policy, merge
/// gates, source-branch cleanup and commit templates.
class MergeSettingsSection extends ConsumerWidget {
  const MergeSettingsSection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Merge requests'),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.borderMd,
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              _ChoiceTile(
                label: 'Merge method',
                value: project.mergeMethod ?? 'merge',
                options: const {
                  'merge': 'Merge commit',
                  'rebase_merge': 'Rebase and merge',
                  'ff': 'Fast-forward merge',
                },
                onChanged: (v) => _set(context, ref, mergeMethod: v),
              ),
              _divider(colors),
              _ChoiceTile(
                label: 'Squash commits',
                value: project.squashOption ?? 'default_off',
                options: const {
                  'never': 'Do not allow',
                  'always': 'Require',
                  'default_on': 'Allow, on by default',
                  'default_off': 'Allow, off by default',
                },
                onChanged: (v) => _set(context, ref, squashOption: v),
              ),
              _divider(colors),
              _GateSwitch(
                label: 'Pipelines must succeed',
                value: project.onlyAllowMergeIfPipelineSucceeds ?? false,
                onChanged: (v) =>
                    _set(context, ref, onlyAllowMergeIfPipelineSucceeds: v),
              ),
              _divider(colors),
              _GateSwitch(
                label: 'Allow merge on skipped pipelines',
                value: project.allowMergeOnSkippedPipeline ?? false,
                onChanged: (v) =>
                    _set(context, ref, allowMergeOnSkippedPipeline: v),
              ),
              _divider(colors),
              _GateSwitch(
                label: 'All threads must be resolved',
                value:
                    project.onlyAllowMergeIfAllDiscussionsAreResolved ?? false,
                onChanged: (v) => _set(
                  context,
                  ref,
                  onlyAllowMergeIfAllDiscussionsAreResolved: v,
                ),
              ),
              _divider(colors),
              _GateSwitch(
                label: 'Delete source branch after merge',
                value: project.removeSourceBranchAfterMerge ?? false,
                onChanged: (v) =>
                    _set(context, ref, removeSourceBranchAfterMerge: v),
              ),
              _divider(colors),
              _TemplateTile(
                label: 'Merge commit template',
                value: project.mergeCommitTemplate,
                onEdit: () => _editTemplate(
                  context,
                  ref,
                  label: 'Merge commit template',
                  initial: project.mergeCommitTemplate,
                  onSubmit: (v) => _set(context, ref, mergeCommitTemplate: v),
                ),
              ),
              _divider(colors),
              _TemplateTile(
                label: 'Squash commit template',
                value: project.squashCommitTemplate,
                onEdit: () => _editTemplate(
                  context,
                  ref,
                  label: 'Squash commit template',
                  initial: project.squashCommitTemplate,
                  onSubmit: (v) => _set(context, ref, squashCommitTemplate: v),
                ),
              ),
              _divider(colors),
              _TemplateTile(
                label: 'Suggestion commit message',
                value: project.suggestionCommitMessage,
                onEdit: () => _editTemplate(
                  context,
                  ref,
                  label: 'Suggestion commit message',
                  initial: project.suggestionCommitMessage,
                  onSubmit: (v) =>
                      _set(context, ref, suggestionCommitMessage: v),
                ),
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
    String? mergeMethod,
    String? squashOption,
    bool? onlyAllowMergeIfPipelineSucceeds,
    bool? allowMergeOnSkippedPipeline,
    bool? onlyAllowMergeIfAllDiscussionsAreResolved,
    bool? removeSourceBranchAfterMerge,
    String? mergeCommitTemplate,
    String? squashCommitTemplate,
    String? suggestionCommitMessage,
  }) async {
    try {
      await ref
          .read(projectsRepositoryProvider)
          .updateProject(
            project.id,
            mergeMethod: mergeMethod,
            squashOption: squashOption,
            onlyAllowMergeIfPipelineSucceeds: onlyAllowMergeIfPipelineSucceeds,
            allowMergeOnSkippedPipeline: allowMergeOnSkippedPipeline,
            onlyAllowMergeIfAllDiscussionsAreResolved:
                onlyAllowMergeIfAllDiscussionsAreResolved,
            removeSourceBranchAfterMerge: removeSourceBranchAfterMerge,
            mergeCommitTemplate: mergeCommitTemplate,
            squashCommitTemplate: squashCommitTemplate,
            suggestionCommitMessage: suggestionCommitMessage,
          );
      ref.invalidate(projectProvider(project.id.toString()));
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }

  Future<void> _editTemplate(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required String? initial,
    required Future<void> Function(String) onSubmit,
  }) async {
    final controller = TextEditingController(text: initial ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Leave empty to use the default',
              border: OutlineInputBorder(),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final text = controller.text.trim();
    controller.dispose();
    if (ok != true || !context.mounted) {
      return;
    }
    await onSubmit(text);
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

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.label,
    required this.value,
    required this.onEdit,
  });

  final String label;
  final String? value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      dense: true,
      title: Text(label),
      subtitle: Text(
        value == null || value!.isEmpty ? 'Default' : value!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(Icons.edit_outlined, size: 16, color: colors.inkMuted),
      onTap: onEdit,
    );
  }
}
