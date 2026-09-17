import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/app/theme/app_typography.dart';

/// Builds the app's [ThemeData] for light and dark mode.
abstract final class GlamTheme {
  static ThemeData light() => _build(GlamColors.light, Brightness.light);
  static ThemeData dark() => _build(GlamColors.dark, Brightness.dark);

  static ThemeData _build(GlamColors colors, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: colors.accent,
      onPrimary: colors.onAccent,
      secondary: colors.brand,
      onSecondary: Colors.white,
      error: colors.danger,
      onError: Colors.white,
      surface: colors.surface,
      onSurface: colors.ink,
      surfaceContainerHighest: colors.surfaceMuted,
      onSurfaceVariant: colors.inkMuted,
      outline: colors.border,
      outlineVariant: colors.borderStrong,
      shadow: Colors.black.withValues(alpha: 0.25),
      scrim: Colors.black.withValues(alpha: 0.5),
      inverseSurface: colors.ink,
      onInverseSurface: colors.canvas,
      inversePrimary: colors.accentSoft,
      surfaceTint: Colors.transparent,
    );

    final textTheme = GlamTypography.textTheme(scheme);
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.canvas,
      textTheme: textTheme,
      extensions: [colors],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.canvas,
        foregroundColor: colors.ink,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        shadowColor: colors.border,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.borderMd,
          side: BorderSide(color: colors.border),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceRaised,
        shape: RoundedRectangleBorder(borderRadius: Radii.borderLg),
        titleTextStyle: textTheme.headlineSmall,
      ),
      drawerTheme: DrawerThemeData(backgroundColor: colors.surface),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? colors.surfaceRaised : colors.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? colors.ink : colors.surface,
        ),
        shape: RoundedRectangleBorder(borderRadius: Radii.borderMd),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.ink,
          borderRadius: Radii.borderSm,
        ),
        textStyle: textTheme.labelMedium?.copyWith(color: colors.canvas),
        waitDuration: const Duration(milliseconds: 600),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceMuted,
        selectedColor: colors.accentSoft,
        disabledColor: colors.surfaceMuted,
        labelStyle: textTheme.labelMedium!,
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(borderRadius: Radii.borderPill),
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.sm,
          vertical: Insets.xs,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        hintStyle: textTheme.bodyMedium?.copyWith(color: colors.inkFaint),
        labelStyle: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Insets.md,
          vertical: Insets.md,
        ),
        border: OutlineInputBorder(
          borderRadius: Radii.borderMd,
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Radii.borderMd,
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Radii.borderMd,
          borderSide: BorderSide(color: colors.accent, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: Radii.borderMd,
          borderSide: BorderSide(color: colors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: Radii.borderMd,
          borderSide: BorderSide(color: colors.danger, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.onAccent,
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
          shape: RoundedRectangleBorder(borderRadius: Radii.borderMd),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.ink,
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(0, 44),
          side: BorderSide(color: colors.borderStrong),
          padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
          shape: RoundedRectangleBorder(borderRadius: Radii.borderMd),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.accent,
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: colors.inkMuted),
      ),
      listTileTheme: ListTileThemeData(
        textColor: colors.ink,
        iconColor: colors.inkMuted,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodySmall,
        contentPadding: const EdgeInsets.symmetric(horizontal: Insets.lg),
        shape: RoundedRectangleBorder(borderRadius: Radii.borderMd),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colors.accent,
        unselectedLabelColor: colors.inkMuted,
        labelStyle: textTheme.titleSmall,
        unselectedLabelStyle: textTheme.titleSmall,
        indicatorColor: colors.accent,
        dividerColor: colors.border,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.accentSoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final style = textTheme.labelMedium!;
          return states.contains(WidgetState.selected)
              ? style.copyWith(color: colors.ink)
              : style.copyWith(color: colors.inkMuted);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colors.accent
                : colors.inkMuted,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.surface,
        selectedIconTheme: IconThemeData(color: colors.accent),
        unselectedIconTheme: IconThemeData(color: colors.inkMuted),
        selectedLabelTextStyle: textTheme.labelMedium!.copyWith(
          color: colors.accent,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium!.copyWith(
          color: colors.inkMuted,
        ),
        indicatorColor: colors.accentSoft,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.borderMd,
          side: BorderSide(color: colors.border),
        ),
        textStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceRaised,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colors.accent),
      badgeTheme: BadgeThemeData(
        backgroundColor: colors.danger,
        textColor: Colors.white,
        textStyle: textTheme.labelSmall,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(textTheme.labelMedium),
          side: WidgetStatePropertyAll(BorderSide(color: colors.border)),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colors.accent;
            }
            return colors.inkMuted;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colors.accentSoft;
            }
            return Colors.transparent;
          }),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: const WidgetStatePropertyAll(false),
        interactive: true,
        radius: const Radius.circular(Radii.pill),
        thickness: const WidgetStatePropertyAll(4),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.dragged)
              ? colors.inkMuted
              : colors.inkFaint;
        }),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
