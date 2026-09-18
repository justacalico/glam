import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/utils/color_parse.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/search_field.dart';
import 'package:glam/src/core/widgets/label_chip.dart';
import 'package:glam/src/features/labels/domain/label.dart';
import 'package:glam/src/features/milestones/application/planning_providers.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// Labels tab inside project or group detail.
class LabelsTab extends ConsumerStatefulWidget {
  const LabelsTab({required this.scope, super.key});

  final ContainerScope scope;

  @override
  ConsumerState<LabelsTab> createState() => _LabelsTabState();
}

class _LabelsTabState extends ConsumerState<LabelsTab> {
  String? _search;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filter = (scope: widget.scope, search: _search);
    final labels = ref.watch(labelsProvider(filter));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Insets.lg,
            Insets.sm,
            Insets.lg,
            0,
          ),
          child: SearchField(
            hint: context.l10n.searchLabels,
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.lg,
              Insets.xs,
              Insets.lg,
              Insets.xs,
            ),
            child: IconButton(
              tooltip: context.l10n.newLabel,
              icon: const Icon(Icons.add),
              onPressed: () => unawaited(
                LabelFormScreen.show(context, scope: widget.scope).then((
                  saved,
                ) {
                  if (saved) {
                    ref.invalidate(labelsProvider);
                  }
                }),
              ),
            ),
          ),
        ),
        Expanded(
          child: AsyncValueWidget(
            value: labels,
            onRetry: () => ref.invalidate(labelsProvider(filter)),
            data: (items) => items.isEmpty
                ? const EmptyState(
                    icon: Icons.label_outline,
                    title: context.l10n.noLabels,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: Insets.sm),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: colors.border,
                      indent: Insets.lg,
                    ),
                    itemBuilder: (context, index) =>
                        _LabelTile(label: items[index], scope: widget.scope),
                  ),
          ),
        ),
      ],
    );
  }
}

class _LabelTile extends ConsumerWidget {
  const _LabelTile({required this.label, required this.scope});

  final Label label;
  final ContainerScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      title: Align(
        alignment: Alignment.centerLeft,
        child: LabelChip(name: label.name, color: label.color),
      ),
      subtitle: label.description?.isNotEmpty ?? false
          ? Text(
              label.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label.openIssuesCount != null)
            Text(
              context.l10n.p0Issues(label.openIssuesCount),
              style: theme.textTheme.bodySmall,
            ),
          PopupMenuButton<String>(
            iconSize: 18,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text(context.l10n.actionEdit)),
              PopupMenuItem(
                value: 'subscribe',
                child: Text(
                  label.subscribed ?? false ? 'Unsubscribe' : 'Subscribe',
                ),
              ),
              if (scope.isProject)
                const PopupMenuItem(
                  value: 'promote',
                  child: Text(context.l10n.promoteToGroup),
                ),
              const PopupMenuItem(value: 'delete', child: Text(context.l10n.actionDelete)),
            ],
            onSelected: (v) {
              if (v == 'edit') {
                unawaited(
                  LabelFormScreen.show(
                    context,
                    scope: scope,
                    label: label,
                  ).then((saved) {
                    if (saved) {
                      ref.invalidate(labelsProvider);
                    }
                  }),
                );
              } else if (v == 'subscribe') {
                unawaited(_subscribe(context, ref));
              } else if (v == 'promote') {
                unawaited(_promote(context, ref));
              } else {
                unawaited(_delete(context, ref));
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _subscribe(BuildContext context, WidgetRef ref) async {
    await ref
        .read(labelsRepositoryProvider)
        .setSubscribed(
          scope.id,
          isProject: scope.isProject,
          labelId: label.id,
          subscribed: !(label.subscribed ?? false),
        );
    ref.invalidate(labelsProvider);
  }

  Future<void> _promote(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.promoteP0(label.name)),
        content: const Text(
          context.l10n.theLabelMovesToTheParent
          'issue and MR that uses it.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: const Text(context.l10n.promote),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await ref.read(labelsRepositoryProvider).promote(scope.id, label.id);
    ref.invalidate(labelsProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteNamedConfirm(label.name)),
        content: const Text(context.l10n.theLabelIsRemovedFromEvery),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: const Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await ref
        .read(labelsRepositoryProvider)
        .delete(scope.id, isProject: scope.isProject, name: label.name);
    ref.invalidate(labelsProvider);
  }
}

/// Create/edit form for a label with a color picker.
class LabelFormScreen extends ConsumerStatefulWidget {
  const LabelFormScreen({required this.scope, this.label, super.key});

  final ContainerScope scope;

  /// Non-null = edit mode.
  final Label? label;

  static Future<bool> show(
    BuildContext context, {
    required ContainerScope scope,
    Label? label,
  }) async {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final child = LabelFormScreen(scope: scope, label: label);
    final result = wide
        ? await showDialog<bool>(
            context: context,
            builder: (_) => Dialog(
              clipBehavior: Clip.antiAlias,
              insetPadding: const EdgeInsets.all(Insets.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: child,
              ),
            ),
          )
        : await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            showDragHandle: true,
            builder: (_) => child,
          );
    return result ?? false;
  }

  @override
  ConsumerState<LabelFormScreen> createState() => _LabelFormScreenState();
}

class _LabelFormScreenState extends ConsumerState<LabelFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late String _color;
  var _saving = false;
  String? _error;

  bool get _editing => widget.label != null;

  /// GitLab's suggested palette.
  static const _palette = [
    '#d9534f',
    '#d18fe2',
    '#428fdc',
    '#69d100',
    '#f0ad4e',
    '#34495e',
    '#7f8fa9',
    '#8e44ad',
    '#ffdb4d',
    '#1aaa55',
    '#0033cc',
    '#5843ad',
  ];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.label?.name ?? '');
    _description = TextEditingController(text: widget.label?.description ?? '');
    _color = widget.label?.color ?? _palette.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || _saving) {
      setState(() => _error = name.isEmpty ? 'Name is required' : null);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(labelsRepositoryProvider);
    try {
      if (_editing) {
        await repo.update(
          widget.scope.id,
          isProject: widget.scope.isProject,
          name: widget.label!.name,
          newName: name == widget.label!.name ? null : name,
          color: _color == widget.label!.color ? null : _color,
          description: _description.text.trim(),
        );
      } else {
        await repo.create(
          widget.scope.id,
          isProject: widget.scope.isProject,
          name: name,
          color: _color,
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
        );
      }
      if (mounted) {
        context.pop(true);
      }
    } on ApiException catch (e) {
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } on Object {
      setState(() {
        _saving = false;
        _error = 'Could not save the label';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: Insets.lg,
        right: Insets.lg,
        top: Insets.lg,
        bottom: Insets.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _editing ? 'Edit label' : 'New label',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: Insets.lg),
          Center(
            child: LabelChip(
              name: _name.text.isEmpty ? 'Label preview' : _name.text,
              color: _color,
            ),
          ),
          const SizedBox(height: Insets.lg),
          TextField(
            controller: _name,
            autofocus: !_editing,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: context.l10n.fieldName,
              hintText: context.l10n.bugOrPriorityHigh,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Insets.md),
          TextField(
            controller: _description,
            decoration: const InputDecoration(
              labelText: context.l10n.fieldDescription,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Insets.md),
          Text(context.l10n.color, style: theme.textTheme.labelLarge),
          const SizedBox(height: Insets.sm),
          Wrap(
            spacing: Insets.sm,
            runSpacing: Insets.sm,
            children: [
              for (final hex in _palette)
                InkWell(
                  borderRadius: Radii.borderSm,
                  onTap: () => setState(() => _color = hex),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: parseHexColor(hex),
                      borderRadius: Radii.borderSm,
                      border: Border.all(
                        color: _color == hex ? colors.ink : colors.border,
                        width: _color == hex ? 2 : 1,
                      ),
                    ),
                    child: _color == hex
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: contrastingText(parseHexColor(hex)!),
                          )
                        : null,
                  ),
                ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: Insets.sm),
              child: Text(_error!, style: TextStyle(color: colors.danger)),
            ),
          const SizedBox(height: Insets.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _saving ? null : () => context.pop(false),
                child: const Text(context.l10n.actionCancel),
              ),
              const SizedBox(width: Insets.sm),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_editing ? context.l10n.actionSave : context.l10n.createLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
