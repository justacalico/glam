extension StringX on String {
  /// `jane.doe` → `JD`, `Jane` → `JA`.
  String get initials {
    final parts = trim().split(RegExp(r'[\s._-]+'))
      ..removeWhere((p) => p.isEmpty);
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      final p = parts.first;
      return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

extension DateTimeX on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
}
