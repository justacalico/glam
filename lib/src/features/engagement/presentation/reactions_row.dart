import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/models/award_emoji.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/engagement/application/engagement_providers.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// Reaction chips + an add-emoji button for an issue, MR, or note.
class ReactionsRow extends ConsumerWidget {
  const ReactionsRow({required this.loc, super.key});

  final AwardableRef loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(awardEmojisProvider(loc));
    final userId = ref.watch(sessionProvider).value?.user.id;
    final awards = async.value ?? const <AwardEmoji>[];
    if (async.isLoading && awards.isEmpty) {
      return const SizedBox(height: 28);
    }

    final byName = <String, List<AwardEmoji>>{};
    for (final a in awards) {
      byName.putIfAbsent(a.name, () => []).add(a);
    }

    return Wrap(
      spacing: Insets.sm,
      runSpacing: Insets.xs,
      children: [
        for (final entry in byName.entries)
          _ReactionChip(
            name: entry.key,
            awards: entry.value,
            mine: entry.value.any((a) => a.user?.id == userId),
            onTap: () =>
                ref.read(awardEmojisProvider(loc).notifier).toggle(entry.key),
          ),
        _AddEmojiButton(
          onPick: (name) =>
              ref.read(awardEmojisProvider(loc).notifier).toggle(name),
        ),
      ],
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.name,
    required this.awards,
    required this.mine,
    required this.onTap,
  });

  final String name;
  final List<AwardEmoji> awards;
  final bool mine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final names = awards.map((a) => a.user?.username ?? '?').join(', ');
    return Tooltip(
      message: names,
      child: Material(
        color: mine ? colors.accentSoft : colors.surfaceMuted,
        borderRadius: Radii.borderPill,
        child: InkWell(
          onTap: onTap,
          borderRadius: Radii.borderPill,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.sm + 2,
              vertical: Insets.xs - 1,
            ),
            child: AnimatedSwitcher(
              duration: Motion.fast,
              child: Text(
                context.l10n.storageStatPair(awards.first.glyph, awards.length),
                key: ValueKey(awards.length),
                style: TextStyle(
                  fontSize: 13,
                  color: mine ? colors.accent : colors.inkMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddEmojiButton extends StatelessWidget {
  const _AddEmojiButton({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: Colors.transparent,
      borderRadius: Radii.borderPill,
      child: InkWell(
        borderRadius: Radii.borderPill,
        onTap: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Insets.md),
              child: Wrap(
                spacing: Insets.sm,
                runSpacing: Insets.sm,
                children: [
                  for (final e in AwardEmoji.glyphs.entries)
                    IconButton(
                      icon: Text(e.value, style: const TextStyle(fontSize: 24)),
                      onPressed: () {
                        Navigator.pop(context);
                        onPick(e.key);
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.sm,
            vertical: Insets.xs - 1,
          ),
          child: Icon(
            Icons.add_reaction_outlined,
            size: 18,
            color: colors.inkMuted,
          ),
        ),
      ),
    );
  }
}
