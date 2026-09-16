import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/features/registry/application/registry_providers.dart';
import 'package:glam/src/features/registry/domain/registry_models.dart';

/// Tags inside one container repository.
class RegistryTagsScreen extends ConsumerWidget {
  const RegistryTagsScreen({required this.loc, super.key});

  final RegistryLoc loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(registryTagsProvider(loc));
    final notifier = ref.read(registryTagsProvider(loc).notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Tags')),
      body: AsyncValueWidget(
        value: state,
        onRetry: notifier.refresh,
        data: (data) => PagedListView<RegistryTag>(
          state: data,
          onLoadMore: notifier.loadMore,
          onRefresh: notifier.refresh,
          padding: const EdgeInsets.symmetric(vertical: Insets.sm),
          separator: Divider(
            height: 1,
            color: colors.border,
            indent: Insets.lg,
          ),
          empty: const EmptyState(icon: Icons.sell_outlined, title: 'No tags'),
          itemBuilder: (context, index) {
            final t = data.items[index];
            return ListTile(
              leading: const Icon(Icons.sell_outlined, size: 20),
              title: Text(
                t.name,
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12.5,
                ),
              ),
              subtitle: Text(
                [
                  if (t.shortRevision.isNotEmpty) t.shortRevision,
                  if (t.totalSize != null) Format.bytes(t.totalSize!),
                  if (t.createdAt != null) Format.date(t.createdAt!),
                ].join(' · '),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: () => _delete(context, ref, t),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    RegistryTag tag,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete tag?'),
        content: Text('"${tag.name}" is removed permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await ref.read(registryTagsProvider(loc).notifier).deleteTag(tag.name);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}
