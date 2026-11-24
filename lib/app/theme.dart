import 'package:flutter/material.dart';

/// Warm & modern palette: cream base, navy from the Bethel logo, gold accent.
class BethelColors {
  static const navy = Color(0xFF1E3A5F);
  static const navyDeep = Color(0xFF14273F);
  static const gold = Color(0xFFC8963E);
  static const goldSoft = Color(0xFFF3E4C6);
  static const cream = Color(0xFFFAF6EF);
  static const sand = Color(0xFFF1EADF);
  static const ink = Color(0xFF2A2420);
  static const muted = Color(0xFF7A6F66);
  static const rose = Color(0xFFC4604A);

  static const nightBg = Color(0xFF121418);
  static const nightSurface = Color(0xFF1C1F25);
  static const nightCard = Color(0xFF242832);
}

class BethelTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final dark = b == Brightness.dark;
    final scheme = ColorScheme(
      brightness: b,
      primary: dark ? const Color(0xFF9DB8DC) : BethelColors.navy,
      onPrimary: dark ? BethelColors.navyDeep : Colors.white,
      secondary: BethelColors.gold,
      onSecondary: Colors.white,
      tertiary: BethelColors.rose,
      onTertiary: Colors.white,
      error: const Color(0xFFB3261E),
      onError: Colors.white,
      surface: dark ? BethelColors.nightBg : BethelColors.cream,
      onSurface: dark ? const Color(0xFFECE7E1) : BethelColors.ink,
      onSurfaceVariant: dark ? const Color(0xFFA8A097) : BethelColors.muted,
      surfaceContainerLowest: dark ? BethelColors.nightBg : Colors.white,
      surfaceContainerLow: dark ? BethelColors.nightSurface : Colors.white,
      surfaceContainer: dark ? BethelColors.nightCard : BethelColors.sand,
      surfaceContainerHigh: dark ? const Color(0xFF2C313C) : const Color(0xFFEAE1D3),
      outlineVariant: dark ? const Color(0xFF353A45) : const Color(0xFFE6DDCF),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Poppins',
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
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w600, color: scheme.onSurface),
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
        indicatorColor: dark ? const Color(0xFF2E3B52) : BethelColors.goldSoft,
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
        selectedColor: dark ? const Color(0xFF2E3B52) : BethelColors.goldSoft,
        labelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: scheme.onSurface),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    );
  }
}
