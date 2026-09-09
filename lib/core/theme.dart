import 'package:flutter/material.dart';

import 'values/app_values.dart';

/// App-wide look & feel (ThemeData). Numeric tokens live in [AppValues].
/// Fonts are **bundled** (offline) — no network fetch at runtime.
abstract final class AppTheme {
  /// Warm coral seed — food-friendly, playful (default palette).
  static const Color seed = AppValues.seedColor;
  static const Color accent = AppValues.accentColor;

  static const double radiusCard = AppValues.radiusCard;
  static const double radiusButton = AppValues.radiusButton;
  static const double radiusInput = AppValues.radiusInput;
  static const double radiusChip = AppValues.radiusChip;
  static const double minTouch = AppValues.minTouch;

  // Semantic surfaces from design-system/crew-bites/MASTER.md. Keeping these
  // here makes screen code palette-independent and keeps light/dark parity in
  // one place.
  static const Color background = Color(0xFFFEF2F2);
  static const Color foreground = Color(0xFF450A0A);
  static const Color card = Color(0xFFFFFFFF);
  static const Color mutedForeground = Color(0xFF475569);
  static const Color border = Color(0xFFFECACA);

  /// Display brand (launcher / UI). Android/iOS id: `com.i1988.crewbites`.
  static const String brandName = AppValues.brandName;

  /// Shared responsive gutter: comfortable on phones and intentionally wider
  /// on tablets/landscape so long lists keep a readable measure.
  static EdgeInsets pagePadding(BuildContext context, {double bottom = 32}) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width >= 720 ? 40.0 : AppValues.pagePaddingH;
    return EdgeInsets.fromLTRB(horizontal, 0, horizontal, bottom);
  }

  /// Light theme for [palette] (default = brand coral).
  static ThemeData light([ColorPalette palette = ColorPalette.coral]) =>
      _build(Brightness.light, palette);

  /// Dark theme for [palette].
  static ThemeData dark([ColorPalette palette = ColorPalette.coral]) =>
      _build(Brightness.dark, palette);

  static LinearGradient heroGradient(ColorScheme scheme) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        scheme.primary.withValues(alpha: 0.18),
        scheme.tertiary.withValues(alpha: 0.12),
        scheme.surface,
      ],
    );
  }

  static List<BoxShadow> softShadow(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? 0.35 : 0.08),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
    ];
  }

  static ThemeData _build(Brightness brightness, ColorPalette palette) {
    final scheme = palette == ColorPalette.coral
        ? (brightness == Brightness.light
            ? const ColorScheme.light(
                primary: Color(0xFFDC2626),
                onPrimary: Colors.white,
                secondary: Color(0xFFF87171),
                onSecondary: Color(0xFF450A0A),
                tertiary: Color(0xFFA16207),
                onTertiary: Colors.white,
                surface: background,
                onSurface: foreground,
                error: Color(0xFFB91C1C),
                onError: Colors.white,
                outline: border,
              ).copyWith(
                surfaceContainerLow: card,
                surfaceContainer: card,
                surfaceContainerHighest: Color(0xFFFFE4E6),
                onSurfaceVariant: mutedForeground,
                primaryContainer: Color(0xFFFECACA),
                onPrimaryContainer: Color(0xFF7F1D1D),
                secondaryContainer: Color(0xFFFFE4E6),
                onSecondaryContainer: Color(0xFF7F1D1D),
                tertiaryContainer: Color(0xFFFEF3C7),
                onTertiaryContainer: Color(0xFF713F12),
              )
            : const ColorScheme.dark(
                primary: Color(0xFFF87171),
                onPrimary: Color(0xFF450A0A),
                secondary: Color(0xFFFCA5A5),
                onSecondary: Color(0xFF450A0A),
                tertiary: Color(0xFFFBBF24),
                onTertiary: Color(0xFF451A03),
                surface: Color(0xFF220808),
                onSurface: Color(0xFFFFF7F7),
                error: Color(0xFFFCA5A5),
                onError: Color(0xFF450A0A),
                outline: Color(0xFF9F3A3A),
              ).copyWith(
                surfaceContainerLow: Color(0xFF3A1010),
                surfaceContainer: Color(0xFF421313),
                surfaceContainerHighest: Color(0xFF5B1B1B),
                onSurfaceVariant: Color(0xFFE5CACA),
                primaryContainer: Color(0xFF7F1D1D),
                onPrimaryContainer: Color(0xFFFFDADA),
                secondaryContainer: Color(0xFF7F1D1D),
                onSecondaryContainer: Color(0xFFFFDADA),
                tertiaryContainer: Color(0xFF713F12),
                onTertiaryContainer: Color(0xFFFFE8A3),
              ))
        : palette == ColorPalette.neon
            ? const ColorScheme(
                brightness: Brightness.dark,
                primary: Color(0xFF39FF14),
                onPrimary: Colors.black,
                primaryContainer: Color(0xFF0D5C00),
                onPrimaryContainer: Color(0xFF39FF14),
                secondary: Color(0xFFFF1493),
                onSecondary: Colors.black,
                secondaryContainer: Color(0xFF5C0033),
                onSecondaryContainer: Color(0xFFFF1493),
                tertiary: Color(0xFF00E5FF),
                onTertiary: Colors.black,
                tertiaryContainer: Color(0xFF003D47),
                onTertiaryContainer: Color(0xFF00E5FF),
                surface: Color(0xFF0A0A0A),
                onSurface: Color(0xFFE0E0E0),
                onSurfaceVariant: Color(0xFFB0B0B0),
                error: Color(0xFFFF6B6B),
                onError: Colors.black,
                outline: Color(0xFF39FF14),
              )
            : ColorScheme.fromSeed(
                seedColor: palette.seed,
                brightness: brightness,
              );

    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: 'Nunito',
    );

    TextStyle merge(TextStyle? a, TextStyle? b) =>
        (a ?? const TextStyle()).merge(b);

    final display = base.textTheme.apply(fontFamily: 'Fredoka');
    final body = base.textTheme.apply(fontFamily: 'Nunito');

    final textTheme = TextTheme(
      displayLarge: merge(
        display.displayLarge,
        TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700),
      ),
      displayMedium: merge(
        display.displayMedium,
        TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700),
      ),
      displaySmall: merge(
        display.displaySmall,
        TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700),
      ),
      headlineLarge: merge(
        display.headlineLarge,
        TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          height: 1.2,
          fontSize: 36,
        ),
      ),
      headlineMedium: merge(
        display.headlineMedium,
        TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          height: 1.2,
          fontSize: 28,
        ),
      ),
      headlineSmall: merge(
        display.headlineSmall,
        TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700),
      ),
      titleLarge: merge(
        display.titleLarge,
        TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 20,
          height: 1.3,
        ),
      ),
      titleMedium: merge(
        body.titleMedium,
        TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 16,
          height: 1.3,
        ),
      ),
      titleSmall: merge(
        body.titleSmall,
        TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 14,
          height: 1.3,
        ),
      ),
      bodyLarge: merge(
        body.bodyLarge,
        TextStyle(color: scheme.onSurface, height: 1.5, fontSize: 16),
      ),
      bodyMedium: merge(
        body.bodyMedium,
        TextStyle(color: scheme.onSurface, height: 1.5, fontSize: 14),
      ),
      bodySmall: merge(
        body.bodySmall,
        TextStyle(color: scheme.onSurfaceVariant, height: 1.5, fontSize: 12),
      ),
      labelLarge: merge(
        body.labelLarge,
        TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700),
      ),
      labelMedium: merge(
        body.labelMedium,
        TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700),
      ),
      labelSmall: merge(
        body.labelSmall,
        TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Nunito',
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface.withValues(alpha: 0.92),
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor:
              palette == ColorPalette.coral ? accent : scheme.primary,
          foregroundColor:
              palette == ColorPalette.coral ? Colors.white : scheme.onPrimary,
          minimumSize: const Size(minTouch, 54),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          textStyle:
              textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(minTouch, 54),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          textStyle:
              textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(minTouch, 44),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusChip),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        labelStyle: textTheme.labelMedium,
      ),
      focusColor: scheme.primary.withValues(alpha: 0.18),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
