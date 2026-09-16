import 'dart:ui';

/// Parses GitLab's `#rrggbb`/`#rgb` label colors into [Color]s.
Color? parseHexColor(String? input) {
  if (input == null) {
    return null;
  }
  var hex = input.trim();
  if (hex.startsWith('#')) {
    hex = hex.substring(1);
  }
  if (hex.length == 3) {
    hex = hex.split('').map((c) => '$c$c').join();
  }
  if (hex.length != 6) {
    return null;
  }
  final value = int.tryParse(hex, radix: 16);
  if (value == null) {
    return null;
  }
  return Color(0xFF000000 | value);
}

/// Picks black or white text for the given background by luminance.
Color contrastingText(Color background) {
  return background.computeLuminance() > 0.45
      ? const Color(0xFF1B1B23)
      : const Color(0xFFF1F1F6);
}
