import 'package:flutter/material.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/utils/debouncer.dart';

/// Compact debounced search box used above filterable lists.
class SearchField extends StatefulWidget {
  const SearchField({required this.hint, required this.onChanged, super.key});

  final String hint;
  final ValueChanged<String?> onChanged;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _debouncer = Debouncer();

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: 38,
      child: TextField(
        textInputAction: TextInputAction.search,
        onChanged: (v) =>
            _debouncer(() => widget.onChanged(v.isEmpty ? null : v)),
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.search, size: 18),
          isDense: true,
          filled: true,
          fillColor: colors.surfaceMuted,
          border: OutlineInputBorder(
            borderRadius: Radii.borderMd,
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
