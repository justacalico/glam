import 'package:flutter/material.dart';

/// Font families bundled with the app.
abstract final class GlamFonts {
  static const String body = 'Inter';
  static const String display = 'Space Grotesk';
  static const String mono = 'JetBrains Mono';
}

/// Typography scale.
///
/// Inter carries the UI. Space Grotesk is reserved for display moments
/// (the login wordmark, large numbers, empty states). JetBrains Mono is
/// for anything a developer would expect in mono: SHAs, code, paths.
abstract final class GlamTypography {
  static TextTheme textTheme(ColorScheme scheme) {
    const body = TextStyle(fontFamily: GlamFonts.body);
    const display = TextStyle(fontFamily: GlamFonts.display);

    return TextTheme(
      displayLarge: display.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
        color: scheme.onSurface,
      ),
      displayMedium: display.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: scheme.onSurface,
      ),
      displaySmall: display.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: scheme.onSurface,
      ),
      headlineLarge: body.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: scheme.onSurface,
      ),
      headlineMedium: body.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: scheme.onSurface,
      ),
      headlineSmall: body.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleLarge: body.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleMedium: body.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleSmall: body.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      bodyLarge: body.copyWith(
        fontSize: 15,
        height: 1.5,
        color: scheme.onSurface,
      ),
      bodyMedium: body.copyWith(
        fontSize: 14,
        height: 1.45,
        color: scheme.onSurface,
      ),
      bodySmall: body.copyWith(
        fontSize: 12.5,
        height: 1.4,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: body.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      labelMedium: body.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: scheme.onSurfaceVariant,
      ),
      labelSmall: body.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: scheme.onSurfaceVariant,
      ),
    );
  }

  /// Monospaced style for code, SHAs and file paths.
  static TextStyle mono(
    BuildContext context, {
    double size = 13,
    FontWeight weight = FontWeight.w400,
    Color? color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return TextStyle(
      fontFamily: GlamFonts.mono,
      fontSize: size,
      fontWeight: weight,
      color: color ?? scheme.onSurface,
      height: 1.5,
    );
  }
}
