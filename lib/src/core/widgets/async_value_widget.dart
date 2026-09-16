import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/core/widgets/error_view.dart';
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
    if (current != null) {
      final child = data(current);
      final retry = onRetry;
      if (wrapRefresh && retry != null) {
        return RefreshIndicator(onRefresh: () async => retry(), child: child);
      }
      return child;
    }
    if (value.hasError) {
      return ErrorView(error: value.error!, onRetry: onRetry);
    }
    return loading ?? const ListShimmer();
  }
}
