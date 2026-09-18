import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/models/ci_variable.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/app/theme/app_typography.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// Editable fields from the variable dialog.
typedef VariableFields = ({
  String key,
  String value,
  bool protected_,
  bool masked,
  String environmentScope,
});

/// Shared CI/CD variable list for project and group scopes. Callers own
/// persistence; the section handles the add/edit dialog and delete confirm.
class CiVariablesSection extends StatelessWidget {
  const CiVariablesSection({
    required this.variables,
    required this.onSave,
    required this.onDelete,
    super.key,
  });

  final AsyncValue<List<CiVariable>> variables;
  final Future<void> Function(CiVariable? existing, VariableFields fields)
  onSave;
  final Future<void> Function(CiVariable variable) onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: Insets.sm),
                child: Text(
                  context.l10n.varsTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: Text(context.l10n.actionAdd),
              onPressed: () => _editVariable(context, null),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.borderMd,
            border: Border.all(color: colors.border),
          ),
          child: variables.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(Insets.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(Insets.lg),
              child: Text('$e'),
            ),
            data: (list) => list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(Insets.lg),
                    child: EmptyState(
                      icon: Icons.key_outlined,
                      title: context.l10n.varsEmpty,
                    ),
                  )
                : Column(
                    children: [
                      for (final v in list)
                        _VariableTile(
                          variable: v,
                          onEdit: () => _editVariable(context, v),
                          onDelete: () => _confirmDelete(context, v),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _editVariable(BuildContext context, CiVariable? existing) async {
    final key = TextEditingController(text: existing?.key ?? '');
    final value = TextEditingController(text: existing?.value ?? '');
    final scope = TextEditingController(
      text: existing?.environmentScope ?? '*',
    );
    var protected_ = existing?.protected_ ?? false;
    var masked = existing?.masked ?? false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            existing == null
                ? context.l10n.varAddTitle
                : context.l10n.varEditTitle,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: key,
                enabled: existing == null,
                decoration: InputDecoration(labelText: context.l10n.fieldKey),
              ),
              const SizedBox(height: Insets.md),
              TextField(
                controller: value,
                decoration: InputDecoration(labelText: context.l10n.fieldValue),
              ),
              const SizedBox(height: Insets.md),
              TextField(
                controller: scope,
                decoration: InputDecoration(
                  labelText: context.l10n.varEnvScope,
                ),
              ),
              CheckboxListTile(
                title: Text(context.l10n.varProtected),
                value: protected_,
                onChanged: (v) => setState(() => protected_ = v!),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: Text(context.l10n.varMasked),
                value: masked,
                onChanged: (v) => setState(() => masked = v!),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ],
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
      ),
    );

    final fields = (
      key: key.text.trim(),
      value: value.text,
      protected_: protected_,
      masked: masked,
      environmentScope: scope.text.trim().isEmpty ? '*' : scope.text.trim(),
    );
    key.dispose();
    value.dispose();
    scope.dispose();

    if (saved == true && fields.key.isNotEmpty && context.mounted) {
      await onSave(existing, fields);
    }
  }

  Future<void> _confirmDelete(BuildContext context, CiVariable variable) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.varDeleteConfirm(variable.key)),
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
    if (confirmed == true && context.mounted) {
      await onDelete(variable);
    }
  }
}

class _VariableTile extends StatelessWidget {
  const _VariableTile({
    required this.variable,
    required this.onEdit,
    required this.onDelete,
  });

  final CiVariable variable;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return ListTile(
      title: Text(
        variable.key,
        style: theme.textTheme.titleSmall?.copyWith(fontFamily: GlamFonts.mono),
      ),
      subtitle: Text(
        [
          if (variable.protected_) 'protected',
          if (variable.masked) context.l10n.varMasked,
          if (variable.environmentScope != '*')
            context.l10n.envScope(variable.environmentScope),
          if (variable.variableType == 'file') context.l10n.varFile,
        ].join(' · '),
        style: theme.textTheme.labelSmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 18, color: colors.inkMuted),
            onPressed: onEdit,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18, color: colors.danger),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
