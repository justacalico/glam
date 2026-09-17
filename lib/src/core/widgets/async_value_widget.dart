import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/core/widgets/error_view.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/widgets/loading_shimmer.dart';

/// Renders an [AsyncValue] as loading, error, or data.
///
/// While refreshing with existing data (pull-to-refresh), the data stays
/// on screen instead of flashing a spinner.
class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    required this.value,
    required this.data,
    this.loading,
    this.onRetry,
    this.wrapRefresh = false,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget? loading;
  final VoidCallback? onRetry;

  /// Wrap the data in a [RefreshIndicator] wired to [onRetry].
  final bool wrapRefresh;

  @override
  Widget build(BuildContext context) {
    final current = value.value;
    Widget child;
    if (current != null) {
      child = data(current);
      final retry = onRetry;
      if (wrapRefresh && retry != null) {
        child = RefreshIndicator(onRefresh: () async => retry(), child: child);
      }
    } else if (value.hasError) {
      child = ErrorView(error: value.error!, onRetry: onRetry);
    } else {
      child = loading ?? const ListShimmer();
    }
    return AnimatedSwitcher(
      duration: Motion.medium,
      switchInCurve: Motion.easeOut,
      switchOutCurve: Motion.easeIn,
      child: KeyedSubtree(
        key: ValueKey(Object.hash(current != null, value.hasError)),
        child: child,
      ),
    );
  }
}
