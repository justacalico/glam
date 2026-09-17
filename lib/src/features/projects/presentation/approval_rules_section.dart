import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/members_picker.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/projects/domain/approval_rule.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/presentation/admin_helpers.dart';

/// Merge-request approvals: the project-wide required count plus the
/// named approval rules with their eligible approvers.
class ApprovalRulesSection extends ConsumerWidget {
  const ApprovalRulesSection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final rules = ref.watch(projectApprovalRulesProvider(project.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: SectionLabel('Merge request approvals')),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              onPressed: () => _edit(context, ref, null),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.borderMd,
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              _RequiredRow(
                value: project.approvalsBeforeMerge,
                onEdit: () => _editRequired(context, ref),
              ),
              rules.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(Insets.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(Insets.lg),
                  child: Text('$e'),
                ),
                data: (list) => list.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(Insets.lg),
                        child: EmptyState(
                          icon: Icons.fact_check_outlined,
                          title: 'No approval rules',
                        ),
                      )
                    : Column(
                        children: [
                          for (final r in list)
                            _RuleTile(
                              rule: r,
                              onEdit: () => _edit(context, ref, r),
                              onDelete: () => _delete(context, ref, r),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _editRequired(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
      text: '${project.approvalsBeforeMerge ?? 0}',
    );
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Required approvals'),
        content: SizedBox(
          width: 360,
          child: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Approvals required to merge',
            ),
            onSubmitted: (_) =>
                Navigator.pop(context, int.tryParse(controller.text.trim())),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(controller.text.trim())),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(projectAdminActionsProvider)
          .setApprovalsBeforeMerge(project, value);
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    ApprovalRule? rule,
  ) async {
    final name = TextEditingController(text: rule?.name ?? '');
    final required = TextEditingController(
      text: '${rule?.approvalsRequired ?? 1}',
    );
    var userIds = rule?.users.map((u) => u.id).toSet() ?? <int>{};
    var nameError = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            rule == null ? 'Add approval rule' : 'Edit approval rule',
          ),
          content: SizedBox(
            width: 420,
            child: ListView(
              shrinkWrap: true,
              children: [
                TextField(
                  controller: name,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Rule name',
                    errorText: nameError ? 'Required' : null,
                  ),
                  onChanged: (_) {
                    if (nameError) {
                      setState(() => nameError = false);
                    }
                  },
                ),
                const SizedBox(height: Insets.sm),
                TextField(
                  controller: required,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Approvals required',
                  ),
                ),
                const SizedBox(height: Insets.md),
                MembersPickerField(
                  projectId: project.id,
                  label: 'Eligible approvers',
                  selected: userIds,
                  onChanged: (s) => setState(() => userIds = s),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isEmpty) {
                  setState(() => nameError = true);
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    final draft = (
      name: name.text.trim(),
      required: int.tryParse(required.text.trim()),
      userIds: userIds.toList(),
    );
    name.dispose();
    required.dispose();
    if (ok != true || draft.name.isEmpty || draft.required == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    try {
      await ref
          .read(projectAdminActionsProvider)
          .saveApprovalRule(
            project.id,
            ruleId: rule?.id,
            name: draft.name,
            approvalsRequired: draft.required!,
            userIds: draft.userIds,
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
    ApprovalRule rule,
  ) async {
    final ok = await confirmAdminAction(
      context,
      title: 'Delete approval rule?',
      body: '"${rule.name}" no longer gates merges.',
    );
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(projectAdminActionsProvider)
          .deleteApprovalRule(project.id, rule.id);
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }
}

class _RequiredRow extends StatelessWidget {
  const _RequiredRow({required this.value, required this.onEdit});

  final int? value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      dense: true,
      leading: Icon(
        Icons.how_to_vote_outlined,
        size: 18,
        color: colors.inkMuted,
      ),
      title: const Text('Required approvals'),
      subtitle: Text(
        value == null ? 'Not set' : '$value approval${value == 1 ? '' : 's'}',
      ),
      trailing: IconButton(
        icon: const Icon(Icons.edit_outlined, size: 16),
        tooltip: 'Edit',
        onPressed: onEdit,
      ),
    );
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile({
    required this.rule,
    required this.onEdit,
    required this.onDelete,
  });

  final ApprovalRule rule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final approvers = [
      for (final u in rule.users) u.name,
      for (final g in rule.groups) 'group:$g',
    ];
    return ListTile(
      dense: true,
      leading: Icon(
        Icons.fact_check_outlined,
        size: 18,
        color: colors.inkMuted,
      ),
      title: Text(rule.name),
      subtitle: Text(
        [
          '${rule.approvalsRequired} required',
          '${rule.eligibleApproverCount} eligible',
          if (approvers.isNotEmpty) approvers.join(', '),
        ].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16),
            tooltip: 'Edit',
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16),
            tooltip: 'Delete',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
