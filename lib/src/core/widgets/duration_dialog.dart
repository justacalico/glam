import 'package:flutter/material.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// Asks for a GitLab duration (`2h`, `1d 4h`, `30m`). Returns the
/// trimmed string or null when cancelled.
Future<String?> promptDuration(BuildContext context, {required String title}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'e.g. 2h, 1d 4h, 30m'),
        onSubmitted: (v) => Navigator.pop(context, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: Text(context.l10n.actionSave),
        ),
      ],
    ),
  );
}
