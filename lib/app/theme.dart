import 'package:flutter/material.dart';

/// "Sacred Simplicity, Modern Elegance".
/// Brand palette: Ivory #F5F2EB · Forest #203B36 · Brass #B49A72 · Ink #262824 · Stone #DCD8CE.
/// The other colours are tints and shades derived from those five.
class BethelColors {
  static const ivory = Color(0xFFF5F2EB);
  static const forest = Color(0xFF203B36);
  static const brass = Color(0xFFB49A72);
  static const ink = Color(0xFF262824);
  static const stone = Color(0xFFDCD8CE);

  static const forestDeep = Color(0xFF152824);
  /// Brass for text on Ivory: deep enough to read, still light enough to work in dark mode.
  static const brassText = Color(0xFF8E7449);
  static const brassSoft = Color(0xFFEDE5D6); // light brass wash
  static const brassLight = Color(0xFFE2CFAE); // highlight for the brass gradient
  static const stoneSoft = Color(0xFFEAE7DF); // between Ivory and Stone, for chips and fields
  static const muted = Color(0xFF6B6C64); // secondary text, readable on Ivory
  static const rose = Color(0xFFB0614E); // likes and alerts, muted to sit with the palette

  static const nightBg = Color(0xFF111413);
  static const nightSurface = Color(0xFF1A1E1C);
  static const nightCard = Color(0xFF222826);
}

class BethelFonts {
  /// Display serif for big headings (Domaine Display slot; see pubspec.yaml).
  static const display = 'Display';

  /// Clean sans for the welcome screen (Switzer; files are git-ignored, see pubspec.yaml).
  static const welcome = 'Switzer';
}

class BethelTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final dark = b == Brightness.dark;
    final scheme = ColorScheme(
      brightness: b,
      primary: dark ? const Color(0xFF9FC1B6) : BethelColors.forest,
      onPrimary: dark ? BethelColors.forestDeep : BethelColors.ivory,
      secondary: BethelColors.brass,
      onSecondary: BethelColors.ink,
      tertiary: BethelColors.rose,
      onTertiary: Colors.white,
      error: const Color(0xFFB3261E),
      onError: Colors.white,
      surface: dark ? BethelColors.nightBg : BethelColors.ivory,
      onSurface: dark ? BethelColors.ivory : BethelColors.ink,
      onSurfaceVariant: dark ? const Color(0xFFA9A79F) : BethelColors.muted,
      surfaceContainerLowest: dark ? BethelColors.nightBg : const Color(0xFFFCFBF8),
      surfaceContainerLow: dark ? BethelColors.nightSurface : const Color(0xFFFCFBF8),
      surfaceContainer: dark ? BethelColors.nightCard : BethelColors.stoneSoft,
      surfaceContainerHigh: dark ? const Color(0xFF2B322F) : BethelColors.stone,
      outlineVariant: dark ? const Color(0xFF333A37) : BethelColors.stone,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Poppins',
      // Telugu song lyrics and titles. Bundled so it works offline and in the preview.
      fontFamilyFallback: const ['NotoSansTelugu'],
      scaffoldBackgroundColor: scheme.surface,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displaySmall: base.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle:
            TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w600, color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: dark ? const Color(0xFF2A3F3A) : BethelColors.brassSoft,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11.5,
              fontWeight: s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
              color: s.contains(WidgetState.selected) ? scheme.onSurface : scheme.onSurfaceVariant,
            )),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              color: s.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant,
            )),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: dark ? const Color(0xFF2A3F3A) : BethelColors.brassSoft,
        labelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: scheme.onSurface),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    );
  }
}
