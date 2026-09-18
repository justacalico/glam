import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/presentation/admin_helpers.dart';
import 'package:glam/src/core/utils/l10n.dart';

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
        SectionLabel(context.l10n.mrsTitle),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.borderMd,
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              _ChoiceTile(
                label: context.l10n.mergeMethod,
                value: project.mergeMethod ?? 'merge',
                options: {
                  'merge': context.l10n.mergeMethodCommit,
                  'rebase_merge': context.l10n.mergeMethodRebase,
                  'ff': context.l10n.mergeMethodFf,
                },
                onChanged: (v) => _set(context, ref, mergeMethod: v),
              ),
              _divider(colors),
              _ChoiceTile(
                label: context.l10n.squashCommits,
                value: project.squashOption ?? 'default_off',
                options: {
                  'never': context.l10n.squashNever,
                  'always': context.l10n.squashAlways,
                  'default_on': context.l10n.squashDefaultOn,
                  'default_off': context.l10n.squashDefaultOff,
                },
                onChanged: (v) => _set(context, ref, squashOption: v),
              ),
              _divider(colors),
              _GateSwitch(
                label: context.l10n.pipelinesMustSucceed,
                value: project.onlyAllowMergeIfPipelineSucceeds ?? false,
                onChanged: (v) =>
                    _set(context, ref, onlyAllowMergeIfPipelineSucceeds: v),
              ),
              _divider(colors),
              _GateSwitch(
                label: context.l10n.allowMergeOnSkippedPipelines,
                value: project.allowMergeOnSkippedPipeline ?? false,
                onChanged: (v) =>
                    _set(context, ref, allowMergeOnSkippedPipeline: v),
              ),
              _divider(colors),
              _GateSwitch(
                label: context.l10n.allThreadsMustBeResolved,
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
                label: context.l10n.deleteSourceBranchAfterMerge,
                value: project.removeSourceBranchAfterMerge ?? false,
                onChanged: (v) =>
                    _set(context, ref, removeSourceBranchAfterMerge: v),
              ),
              _divider(colors),
              _TemplateTile(
                label: context.l10n.mergeCommitTemplate,
                value: project.mergeCommitTemplate,
                onEdit: () => _editTemplate(
                  context,
                  ref,
                  label: context.l10n.mergeCommitTemplate,
                  initial: project.mergeCommitTemplate,
                  onSubmit: (v) => _set(context, ref, mergeCommitTemplate: v),
                ),
              ),
              _divider(colors),
              _TemplateTile(
                label: context.l10n.squashCommitTemplate,
                value: project.squashCommitTemplate,
                onEdit: () => _editTemplate(
                  context,
                  ref,
                  label: context.l10n.squashCommitTemplate,
                  initial: project.squashCommitTemplate,
                  onSubmit: (v) => _set(context, ref, squashCommitTemplate: v),
                ),
              ),
              _divider(colors),
              _TemplateTile(
                label: context.l10n.suggestionCommitMessage,
                value: project.suggestionCommitMessage,
                onEdit: () => _editTemplate(
                  context,
                  ref,
                  label: context.l10n.suggestionCommitMessage,
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
            decoration: InputDecoration(
              hintText: context.l10n.leaveEmptyToUseTheDefault,
              border: OutlineInputBorder(),
            ),
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
        value == null || value!.isEmpty ? context.l10n.templateDefault : value!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(Icons.edit_outlined, size: 16, color: colors.inkMuted),
      onTap: onEdit,
    );
  }
}
