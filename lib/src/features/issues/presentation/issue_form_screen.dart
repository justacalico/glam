import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/features/issues/application/issues_providers.dart';
import 'package:glam/src/features/issues/domain/issue.dart';

/// Create/edit form for an issue. Shows as a dialog on wide screens,
/// a bottom sheet on phones.
class IssueFormScreen extends ConsumerStatefulWidget {
  const IssueFormScreen({required this.projectId, this.issue, super.key});

  final Object projectId;

  /// Non-null = edit mode.
  final Issue? issue;

  /// Opens the right chrome for the form factor. Resolves `true` when
  /// the issue was saved.
  static Future<bool> show(
    BuildContext context, {
    required Object projectId,
    Issue? issue,
  }) async {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final child = IssueFormScreen(projectId: projectId, issue: issue);
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
  ConsumerState<IssueFormScreen> createState() => _IssueFormScreenState();
}

class _IssueFormScreenState extends ConsumerState<IssueFormScreen> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _labels;
  late final TextEditingController _weight;
  DateTime? _dueDate;
  var _confidential = false;
  var _saving = false;
  String? _error;

  bool get _editing => widget.issue != null;

  @override
  void initState() {
    super.initState();
    final issue = widget.issue;
    _title = TextEditingController(text: issue?.title ?? '');
    _description = TextEditingController(text: issue?.description ?? '');
    _labels = TextEditingController(text: issue?.labels.join(', ') ?? '');
    _weight = TextEditingController(text: issue?.weight?.toString() ?? '');
    _dueDate = issue?.dueDate;
    _confidential = issue?.confidential ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _labels.dispose();
    _weight.dispose();
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
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(issuesRepositoryProvider);
    final weight = int.tryParse(_weight.text.trim());
    try {
      if (_editing) {
        await repo.updateIssue(
          widget.projectId,
          widget.issue!.iid,
          title: title,
          description: _description.text.trim(),
          labels: _labelList(),
          dueDate: _dueDate?.toIso8601String().substring(0, 10),
          weight: weight,
        );
      } else {
        await repo.createIssue(
          widget.projectId,
          title: title,
          description: _description.text.trim(),
          labels: _labelList(),
          dueDate: _dueDate?.toIso8601String().substring(0, 10),
          weight: weight,
          confidential: _confidential,
        );
      }
      ref
        ..invalidate(issueProvider)
        ..invalidate(projectIssuesProvider)
        ..invalidate(issuesProvider);
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
        _error = 'Could not save the issue';
      });
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _dueDate ?? DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
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
            _editing ? 'Edit issue' : 'New issue',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: Insets.lg),
          TextField(
            controller: _title,
            autofocus: !_editing,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Insets.md),
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
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weight,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Weight',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: Insets.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDueDate,
                  icon: const Icon(Icons.event_outlined, size: 18),
                  label: Text(
                    _dueDate == null
                        ? 'Due date'
                        : _dueDate!.toIso8601String().substring(0, 10),
                  ),
                ),
              ),
            ],
          ),
          if (!_editing)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Confidential'),
              subtitle: const Text('Only visible to members and assignees'),
              value: _confidential,
              onChanged: (v) => setState(() => _confidential = v),
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
                    : Text(_editing ? 'Save' : 'Create issue'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
