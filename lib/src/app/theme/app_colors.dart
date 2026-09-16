import 'package:flutter/material.dart';

/// Semantic color tokens for Glam.
///
/// Widgets should read colors through `context.colors` (see
/// [glamColorsOf]) instead of reaching for raw hex values, so light and
/// dark mode stay consistent everywhere.
@immutable
class GlamColors extends ThemeExtension<GlamColors> {
  const GlamColors({
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceRaised,
    required this.border,
    required this.borderStrong,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.accent,
    required this.accentStrong,
    required this.accentSoft,
    required this.onAccent,
    required this.brand,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.info,
    required this.infoSoft,
    required this.merged,
    required this.mergedSoft,
    required this.codeBackground,
    required this.diffAdd,
    required this.diffAddLine,
    required this.diffRemove,
    required this.diffRemoveLine,
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  /// Page background.
  final Color canvas;

  /// Card / sheet background.
  final Color surface;

  /// Recessed areas: filter bars, table headers, code gutters.
  final Color surfaceMuted;

  /// Menus and dialogs sitting above [surface].
  final Color surfaceRaised;

  final Color border;
  final Color borderStrong;

  /// Primary text.
  final Color ink;

  /// Secondary text.
  final Color inkMuted;

  /// Placeholders, timestamps, disabled text.
  final Color inkFaint;

  /// Primary action color (violet).
  final Color accent;

  /// Hover/pressed variant of [accent].
  final Color accentStrong;

  /// Tinted background for selected/accented surfaces.
  final Color accentSoft;

  /// Text/icons on top of [accent].
  final Color onAccent;

  /// Brand orange, used sparingly (logo mark, star fills).
  final Color brand;

  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color info;
  final Color infoSoft;

  /// Merged-state violet for merge requests.
  final Color merged;
  final Color mergedSoft;

  final Color codeBackground;
  final Color diffAdd;
  final Color diffAddLine;
  final Color diffRemove;
  final Color diffRemoveLine;

  final Color shimmerBase;
  final Color shimmerHighlight;

  static const GlamColors light = GlamColors(
    canvas: Color(0xFFF7F7FA),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF0F0F5),
    surfaceRaised: Color(0xFFFFFFFF),
    border: Color(0xFFE2E2E9),
    borderStrong: Color(0xFFC9C9D4),
    ink: Color(0xFF1B1B23),
    inkMuted: Color(0xFF57576A),
    inkFaint: Color(0xFF8B8B9C),
    accent: Color(0xFF5B3EC4),
    accentStrong: Color(0xFF4A30A8),
    accentSoft: Color(0xFFEDE9FB),
    onAccent: Color(0xFFFFFFFF),
    brand: Color(0xFFFC6D26),
    success: Color(0xFF217645),
    successSoft: Color(0xFFE1F3E8),
    warning: Color(0xFF9E6A03),
    warningSoft: Color(0xFFFBF0D4),
    danger: Color(0xFFC72E2E),
    dangerSoft: Color(0xFFFBE5E5),
    info: Color(0xFF1F65C0),
    infoSoft: Color(0xFFE3EEFB),
    merged: Color(0xFF6B4FBB),
    mergedSoft: Color(0xFFEEEAF9),
    codeBackground: Color(0xFFF5F5F8),
    diffAdd: Color(0xFF2D9E5F),
    diffAddLine: Color(0xFFE2F5E9),
    diffRemove: Color(0xFFD43A3A),
    diffRemoveLine: Color(0xFFFCEDED),
    shimmerBase: Color(0xFFECECF2),
    shimmerHighlight: Color(0xFFF7F7FA),
  );

  static const GlamColors dark = GlamColors(
    canvas: Color(0xFF0D0D13),
    surface: Color(0xFF15151D),
    surfaceMuted: Color(0xFF1C1C26),
    surfaceRaised: Color(0xFF20202B),
    border: Color(0xFF2A2A38),
    borderStrong: Color(0xFF3D3D50),
    ink: Color(0xFFF1F1F6),
    inkMuted: Color(0xFFA9A9BC),
    inkFaint: Color(0xFF6E6E82),
    accent: Color(0xFF9E85F5),
    accentStrong: Color(0xFFB39DFA),
    accentSoft: Color(0xFF2A2340),
    onAccent: Color(0xFF120E1F),
    brand: Color(0xFFFC6D26),
    success: Color(0xFF4CC38A),
    successSoft: Color(0xFF163022),
    warning: Color(0xFFE5A93D),
    warningSoft: Color(0xFF33270F),
    danger: Color(0xFFF06A6A),
    dangerSoft: Color(0xFF3A1D1D),
    info: Color(0xFF6FA8F0),
    infoSoft: Color(0xFF1A2A40),
    merged: Color(0xFF9E85F5),
    mergedSoft: Color(0xFF2A2340),
    codeBackground: Color(0xFF121219),
    diffAdd: Color(0xFF4CC38A),
    diffAddLine: Color(0xFF16301F),
    diffRemove: Color(0xFFF06A6A),
    diffRemoveLine: Color(0xFF381C1C),
    shimmerBase: Color(0xFF1C1C26),
    shimmerHighlight: Color(0xFF262633),
  );

  @override
  GlamColors copyWith() => this;

  @override
  GlamColors lerp(GlamColors? other, double t) {
    if (other == null) {
      return this;
    }
    return GlamColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      inkFaint: Color.lerp(inkFaint, other.inkFaint, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentStrong: Color.lerp(accentStrong, other.accentStrong, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoSoft: Color.lerp(infoSoft, other.infoSoft, t)!,
      merged: Color.lerp(merged, other.merged, t)!,
      mergedSoft: Color.lerp(mergedSoft, other.mergedSoft, t)!,
      codeBackground: Color.lerp(codeBackground, other.codeBackground, t)!,
      diffAdd: Color.lerp(diffAdd, other.diffAdd, t)!,
      diffAddLine: Color.lerp(diffAddLine, other.diffAddLine, t)!,
      diffRemove: Color.lerp(diffRemove, other.diffRemove, t)!,
      diffRemoveLine: Color.lerp(diffRemoveLine, other.diffRemoveLine, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(
        shimmerHighlight,
        other.shimmerHighlight,
        t,
      )!,
    );
  }
}

extension GlamColorsContext on BuildContext {
  GlamColors get colors => Theme.of(this).extension<GlamColors>()!;
}
