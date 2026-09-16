import 'package:flutter/material.dart';
import 'package:glam/src/app/theme/app_spacing.dart';

/// Shared helpers for the project settings admin sections.

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.sm),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

void showAdminError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<bool?> confirmAdminAction(
  BuildContext context, {
  required String title,
  required String body,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
}
