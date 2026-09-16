import 'package:flutter/material.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer skeleton that stands in for list content while loading.
class ListShimmer extends StatelessWidget {
  const ListShimmer({this.itemCount = 8, this.compact = false, super.key});

  final int itemCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Shimmer.fromColors(
      baseColor: colors.shimmerBase,
      highlightColor: colors.shimmerHighlight,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: Insets.pagePadding,
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: Insets.lg),
        itemBuilder: (_, _) => const _SkeletonRow(),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.surfaceMuted,
            borderRadius: Radii.borderMd,
          ),
        ),
        const SizedBox(width: Insets.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 13,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.surfaceMuted,
                  borderRadius: Radii.borderSm,
                ),
              ),
              const SizedBox(height: Insets.sm),
              FractionallySizedBox(
                widthFactor: 0.55,
                child: Container(
                  height: 11,
                  decoration: BoxDecoration(
                    color: colors.surfaceMuted,
                    borderRadius: Radii.borderSm,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
