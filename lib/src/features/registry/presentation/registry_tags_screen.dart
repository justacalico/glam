import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/core/widgets/search_field.dart';
import 'package:glam/src/features/registry/application/registry_providers.dart';
import 'package:glam/src/features/registry/domain/registry_models.dart';
import 'package:glam/src/app/theme/app_typography.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// Tags inside one container repository.
class RegistryTagsScreen extends ConsumerStatefulWidget {
  const RegistryTagsScreen({required this.loc, this.repoName, super.key});

  final RegistryLoc loc;

  /// Repository path shown in the app bar when navigation passed it along.
  final String? repoName;

  @override
  ConsumerState<RegistryTagsScreen> createState() => _RegistryTagsScreenState();
}

class _RegistryTagsScreenState extends ConsumerState<RegistryTagsScreen> {
  String? _name;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filter = (loc: widget.loc, name: _name);
    final state = ref.watch(registryTagsProvider(filter));
    final notifier = ref.read(registryTagsProvider(filter).notifier);

    return Scaffold(
      appBar: AppBar(title: Text(widget.repoName ?? context.l10n.tabTags)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.lg,
              Insets.sm,
              Insets.lg,
              0,
            ),
            child: SearchField(
              hint: context.l10n.filterTagsRegex,
              onChanged: (s) => setState(() => _name = s),
            ),
          ),
          Expanded(
            child: AsyncValueWidget(
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
                empty: EmptyState(
                  icon: Icons.sell_outlined,
                  title: context.l10n.noTags,
                ),
                itemBuilder: (context, index) {
                  final t = data.items[index];
                  return ListTile(
                    leading: const Icon(Icons.sell_outlined, size: 20),
                    title: Text(
                      t.name,
                      style: const TextStyle(
                        fontFamily: GlamFonts.mono,
                        fontSize: 12.5,
                      ),
                    ),
                    subtitle: _TagSubtitle(loc: widget.loc, tag: t),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () => _delete(context, ref, t),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
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
        title: Text(context.l10n.deleteTag),
        content: Text(context.l10n.p0IsRemovedPermanently(tag.name)),
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
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(registryTagsProvider((loc: widget.loc, name: _name)).notifier)
          .deleteTag(tag.name);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

/// The tags list payload only carries name/path/location; size, revision
/// and dates come from the per-tag detail endpoint.
class _TagSubtitle extends ConsumerWidget {
  const _TagSubtitle({required this.loc, required this.tag});

  final RegistryLoc loc;
  final RegistryTag tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref
        .watch(
          registryTagDetailProvider((
            project: loc.project,
            repoId: loc.repoId,
            tag: tag.name,
          )),
        )
        .value;

    return Text(
      detail == null
          ? tag.location
          : [
              if (detail.shortRevision.isNotEmpty) detail.shortRevision,
              if (detail.totalSize != null) Format.bytes(detail.totalSize!),
              if (detail.createdAt != null) Format.date(detail.createdAt!),
            ].join(' · '),
    );
  }
}
