import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/widgets/description_template_picker.dart';
import 'package:glam/src/core/widgets/members_picker.dart';
import 'package:glam/src/features/auth/domain/user.dart';
import 'package:glam/src/features/merge_requests/application/mr_providers.dart';
import 'package:glam/src/features/merge_requests/domain/merge_request.dart';
import 'package:glam/src/features/repository/application/repository_providers.dart';

/// Create/edit form for a merge request. Dialog on wide screens,
/// bottom sheet on phones.
class MrFormScreen extends ConsumerStatefulWidget {
  const MrFormScreen({required this.projectId, this.mr, super.key});

  final Object projectId;
  final MergeRequest? mr;

  static Future<bool> show(
    BuildContext context, {
    required Object projectId,
    MergeRequest? mr,
  }) async {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final child = MrFormScreen(projectId: projectId, mr: mr);
    final result = wide
        ? await showDialog<bool>(
            context: context,
            builder: (_) => Dialog(
              clipBehavior: Clip.antiAlias,
              insetPadding: const EdgeInsets.all(Insets.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
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
  ConsumerState<MrFormScreen> createState() => _MrFormScreenState();
}

class _MrFormScreenState extends ConsumerState<MrFormScreen> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _labels;
  String? _source;
  String? _target;
  Set<int> _assigneeIds = {};
  Set<int> _reviewerIds = {};
  var _squash = false;
  var _removeSource = false;
  var _saving = false;
  String? _error;

  bool get _editing => widget.mr != null;

  @override
  void initState() {
    super.initState();
    final mr = widget.mr;
    _title = TextEditingController(text: mr?.title ?? '');
    _description = TextEditingController(text: mr?.description ?? '');
    _labels = TextEditingController(text: mr?.labels.join(', ') ?? '');
    _source = mr?.sourceBranch;
    _target = mr?.targetBranch;
    _assigneeIds = {for (final u in mr?.assignees ?? <GitLabUser>[]) u.id};
    _reviewerIds = {for (final u in mr?.reviewers ?? <GitLabUser>[]) u.id};
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _labels.dispose();
    super.dispose();
  }

  List<String> _labelList() => _labels.text
      .split(',')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty || _saving) {
      setState(() => _error = title.isEmpty ? 'Title is required' : null);
      return;
    }
    if (!_editing && (_source == null || _target == null)) {
      setState(() => _error = 'Pick a source and target branch');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(mrRepositoryProvider);
    try {
      if (_editing) {
        await repo.updateMergeRequest(
          widget.projectId,
          widget.mr!.iid,
          title: title,
          description: _description.text.trim(),
          labels: _labelList(),
          targetBranch: _target,
          assigneeIds: _assigneeIds.toList(),
          reviewerIds: _reviewerIds.toList(),
        );
      } else {
        await repo.createMergeRequest(
          widget.projectId,
          sourceBranch: _source!,
          targetBranch: _target!,
          title: title,
          description: _description.text.trim(),
          labels: _labelList(),
          assigneeIds: _assigneeIds.toList(),
          reviewerIds: _reviewerIds.toList(),
          squash: _squash,
          removeSourceBranch: _removeSource,
        );
      }
      ref
        ..invalidate(mrProvider)
        ..invalidate(projectMrsProvider)
        ..invalidate(mergeRequestsProvider);
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
        _error = 'Could not save the merge request';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final branches = ref.watch(branchesProvider(widget.projectId));
    final branchNames = branches.value?.items.map((b) => b.name).toList();

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
            _editing ? 'Edit merge request' : 'New merge request',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: Insets.lg),
          _BranchPicker(
            label: 'Source branch',
            value: _source,
            branches: branchNames,
            enabled: !_editing,
            onChanged: (v) => setState(() => _source = v),
          ),
          const SizedBox(height: Insets.md),
          _BranchPicker(
            label: 'Target branch',
            value: _target,
            branches: branchNames,
            onChanged: (v) => setState(() => _target = v),
          ),
          const SizedBox(height: Insets.md),
          TextField(
            controller: _title,
            autofocus: !_editing,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Insets.md),
          if (!_editing)
            DescriptionTemplatePicker(
              projectId: widget.projectId,
              type: 'merge_requests',
              onApply: (content) => setState(() => _description.text = content),
            ),
          TextField(
            controller: _description,
            minLines: 4,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Markdown supported',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Insets.md),
          TextField(
            controller: _labels,
            decoration: const InputDecoration(
              labelText: 'Labels',
              hintText: 'bug, frontend',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Insets.md),
          MembersPickerField(
            projectId: widget.projectId,
            label: 'Assignees',
            selected: _assigneeIds,
            onChanged: (s) => setState(() => _assigneeIds = s),
          ),
          const SizedBox(height: Insets.md),
          MembersPickerField(
            projectId: widget.projectId,
            label: 'Reviewers',
            selected: _reviewerIds,
            onChanged: (s) => setState(() => _reviewerIds = s),
          ),
          if (!_editing) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Squash commits'),
              value: _squash,
              onChanged: (v) => setState(() => _squash = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Delete source branch after merge'),
              value: _removeSource,
              onChanged: (v) => setState(() => _removeSource = v),
            ),
          ],
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
                child: const Text('Cancel'),
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
                    : Text(_editing ? 'Save' : 'Create MR'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BranchPicker extends StatelessWidget {
  const _BranchPicker({
    required this.label,
    required this.value,
    required this.branches,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final String? value;
  final List<String>? branches;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final b in branches ?? <String>[])
          DropdownMenuItem(
            value: b,
            child: Text(
              b,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 13,
              ),
            ),
          ),
      ],
      onChanged: enabled ? onChanged : null,
    );
  }
}
