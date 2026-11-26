import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// "Sacred Simplicity, Modern Elegance".
/// Brand palette: Ivory #F5F2EB · Forest #203B36 · Brass #B49A72 · Ink #262824 · Stone #DCD8CE.
/// The other colours are tints and shades derived from those five.
///
/// Where to use what (from the wireframes):
/// - Ivory: page backgrounds. Forest: primary buttons, selected tabs and chips, the verse card.
/// - Brass: accents only (section rules, progress, play buttons, the "Last used" badge).
/// - Ink: text. Stone: hairlines and quiet surfaces.
class BethelColors {
  static const ivory = Color(0xFFF5F2EB);
  static const forest = Color(0xFF203B36);
  static const brass = Color(0xFFB49A72);
  static const ink = Color(0xFF262824);
  static const stone = Color(0xFFDCD8CE);

  static const forestDeep = Color(0xFF152824);

  /// Brass for small text on Ivory (4.5:1). Use [BethelTokens.brassText] so dark mode gets its own shade.
  static const brassText = Color(0xFF8E7449);
  static const brassSoft = Color(0xFFEDE5D6); // light brass wash
  static const brassLight = Color(0xFFE2CFAE); // brass for text on Forest
  static const stoneSoft = Color(0xFFEAE7DF); // raised surfaces: chips, fields, plaques
  static const card = Color(0xFFFCFBF8); // cards and the tab bar
  static const muted = Color(0xFF5F6058); // secondary text on Ivory (5.6:1)
  static const rose = Color(0xFFA4553F); // errors and the live dot

  static const sage = Color(0xFF9FC1B6); // Forest's partner in dark mode: links, selected tabs
  static const nightBg = Color(0xFF111413);
  static const nightSurface = Color(0xFF1A1E1C);
  static const nightCard = Color(0xFF222826);
  static const nightTile = Color(0xFF2B322F);
  static const nightLine = Color(0xFF333A37);
  static const nightMuted = Color(0xFFA9A79F);
  static const nightBrassText = Color(0xFFD2B98F);
  static const nightRose = Color(0xFFE08B76);
}

class BethelFonts {
  /// Serif for headings, section titles, verses and lyrics.
  static const display = 'Newsreader';

  /// Interface sans: body text, labels, buttons.
  static const sans = 'InstrumentSans';

  /// Telugu song titles and lyrics.
  static const telugu = 'NotoSerifTelugu';

  /// Kept for older call sites; the welcome screen now uses the interface sans.
  static const welcome = sans;
}

/// The six type sizes used across the app. Nothing else.
class BethelType {
  static const caption = 13.0;
  static const body = 15.0;
  static const lead = 17.0;
  static const title = 20.0;
  static const heading = 26.0;
  static const display = 34.0;
}

/// Colours and effects the Material [ColorScheme] has no slot for.
/// Read with `BethelTokens.of(context)`.
@immutable
class BethelTokens extends ThemeExtension<BethelTokens> {
  const BethelTokens({
    required this.card,
    required this.raised,
    required this.tile,
    required this.hairline,
    required this.brassText,
    required this.error,
    required this.scrim,
    required this.tileShadow,
    required this.toast,
  });

  /// Cards and the tab bar.
  final Color card;

  /// Chips, search field, plaques, quiet buttons.
  final Color raised;

  /// Input fields and code boxes: lighter than the card they sit on, with [tileShadow].
  final Color tile;

  /// 1px dividers between rows and around plaques.
  final Color hairline;

  /// Brass for small text and links that need contrast.
  final Color brassText;

  /// Error text, error outlines and the live dot.
  final Color error;

  /// Behind sheets and dialogs.
  final Color scrim;

  final List<BoxShadow> tileShadow;

  /// Background of toasts.
  final Color toast;

  static BethelTokens of(BuildContext context) => Theme.of(context).extension<BethelTokens>()!;

  static const light = BethelTokens(
    card: BethelColors.card,
    raised: BethelColors.stoneSoft,
    tile: Colors.white,
    hairline: BethelColors.stone,
    brassText: BethelColors.brassText,
    error: BethelColors.rose,
    scrim: Color(0x73141816),
    tileShadow: [
      BoxShadow(color: Color(0x24262824), blurRadius: 3, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x0A262824), spreadRadius: 1),
    ],
    toast: BethelColors.ink,
  );

  static const dark = BethelTokens(
    card: BethelColors.nightSurface,
    raised: BethelColors.nightCard,
    tile: BethelColors.nightTile,
    hairline: BethelColors.nightLine,
    brassText: BethelColors.nightBrassText,
    error: BethelColors.nightRose,
    scrim: Color(0x99000000),
    tileShadow: [BoxShadow(color: Color(0x4D000000), blurRadius: 2, offset: Offset(0, 1))],
    toast: BethelColors.nightTile,
  );

  @override
  BethelTokens copyWith({
    Color? card,
    Color? raised,
    Color? tile,
    Color? hairline,
    Color? brassText,
    Color? error,
    Color? scrim,
    List<BoxShadow>? tileShadow,
    Color? toast,
  }) =>
      BethelTokens(
        card: card ?? this.card,
        raised: raised ?? this.raised,
        tile: tile ?? this.tile,
        hairline: hairline ?? this.hairline,
        brassText: brassText ?? this.brassText,
        error: error ?? this.error,
        scrim: scrim ?? this.scrim,
        tileShadow: tileShadow ?? this.tileShadow,
        toast: toast ?? this.toast,
      );

  @override
  BethelTokens lerp(BethelTokens? other, double t) {
    if (other == null) return this;
    return BethelTokens(
      card: Color.lerp(card, other.card, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      tile: Color.lerp(tile, other.tile, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      brassText: Color.lerp(brassText, other.brassText, t)!,
      error: Color.lerp(error, other.error, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      tileShadow: t < 0.5 ? tileShadow : other.tileShadow,
      toast: Color.lerp(toast, other.toast, t)!,
    );
  }
}

class BethelTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final dark = b == Brightness.dark;
    final tokens = dark ? BethelTokens.dark : BethelTokens.light;
    final text = dark ? BethelColors.ivory : BethelColors.ink;
    final muted = dark ? BethelColors.nightMuted : BethelColors.muted;
    final scheme = ColorScheme(
      brightness: b,
      primary: dark ? BethelColors.sage : BethelColors.forest,
      onPrimary: dark ? BethelColors.forestDeep : BethelColors.ivory,
      secondary: BethelColors.brass,
      onSecondary: BethelColors.ink,
      tertiary: tokens.error,
      onTertiary: Colors.white,
      error: tokens.error,
      onError: Colors.white,
      surface: dark ? BethelColors.nightBg : BethelColors.ivory,
      onSurface: text,
      onSurfaceVariant: muted,
      surfaceContainerLowest: dark ? BethelColors.nightBg : BethelColors.card,
      surfaceContainerLow: tokens.card,
      surfaceContainer: tokens.raised,
      surfaceContainerHigh: dark ? BethelColors.nightTile : BethelColors.stone,
      surfaceContainerHighest: dark ? BethelColors.nightTile : BethelColors.stone,
      outline: muted,
      outlineVariant: tokens.hairline,
      scrim: tokens.scrim,
    );

    TextStyle serif(double size, {FontWeight weight = FontWeight.w400, double height = 1.2}) =>
        TextStyle(fontFamily: BethelFonts.display, fontSize: size, fontWeight: weight, height: height, color: text);
    TextStyle sans(double size, {FontWeight weight = FontWeight.w400, Color? color, double height = 1.45}) =>
        TextStyle(fontFamily: BethelFonts.sans, fontSize: size, fontWeight: weight, height: height, color: color ?? text);

    // Primary buttons stay Forest with Ivory text in both modes (as in the dark wireframes).
    const forestFill = BethelColors.forest;
    final pressScale = WidgetStateProperty.all<OutlinedBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)));

    final textTheme = TextTheme(
      displaySmall: serif(BethelType.display, height: 1.15), // screen titles: Songs, Watch, Prayer, More
      headlineMedium: serif(30, height: 1.15), // greeting, detail-page titles
      headlineSmall: serif(BethelType.heading), // sheet and card titles
      titleLarge: serif(BethelType.title, weight: FontWeight.w500), // section titles, app bar
      titleMedium: serif(BethelType.lead, weight: FontWeight.w500), // serif list titles (sermons, reading plan)
      titleSmall: sans(BethelType.body, weight: FontWeight.w500), // row titles
      bodyLarge: sans(BethelType.lead),
      bodyMedium: sans(BethelType.body),
      bodySmall: sans(BethelType.caption, color: muted),
      labelLarge: sans(BethelType.body, weight: FontWeight.w500), // buttons
      labelMedium: sans(BethelType.caption, weight: FontWeight.w500),
      labelSmall: sans(11, weight: FontWeight.w500),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      fontFamily: BethelFonts.sans,
      // Telugu in any text falls back to the Telugu serif.
      fontFamilyFallback: const [BethelFonts.telugu, 'NotoSansTelugu'],
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      extensions: [tokens],
      splashFactory: NoSplash.splashFactory, // presses use a surface step, not ripples
      highlightColor: text.withValues(alpha: 0.05),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        systemOverlayStyle: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: serif(BethelType.title, weight: FontWeight.w500),
      ),
      cardTheme: CardThemeData(
        color: tokens.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent, // flat tab bar: colour marks the selected tab
        elevation: 0,
        height: 60,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((s) => sans(11,
            weight: s.contains(WidgetState.selected) ? FontWeight.w500 : FontWeight.w400,
            color: s.contains(WidgetState.selected) ? scheme.primary : muted)),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              size: 24,
              color: s.contains(WidgetState.selected) ? scheme.primary : muted,
            )),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(0, 52)),
          shape: pressScale,
          elevation: WidgetStateProperty.all(0),
          backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.disabled)
              ? forestFill.withValues(alpha: 0.5)
              : s.contains(WidgetState.pressed)
                  ? BethelColors.forestDeep
                  : forestFill),
          foregroundColor: WidgetStateProperty.all(BethelColors.ivory),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          textStyle: WidgetStateProperty.all(sans(BethelType.body, weight: FontWeight.w500)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(0, 52)),
          shape: pressScale,
          side: WidgetStateProperty.all(BorderSide(color: tokens.hairline)),
          foregroundColor: WidgetStateProperty.all(scheme.primary),
          backgroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.pressed) ? tokens.raised : Colors.transparent),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          textStyle: WidgetStateProperty.all(sans(BethelType.body, weight: FontWeight.w500)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(44, 44),
          textStyle: sans(BethelType.body, weight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.tile,
        hintStyle: sans(BethelType.lead, color: muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: tokens.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: tokens.error, width: 2),
        ),
        errorStyle: sans(BethelType.caption, color: tokens.error),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: tokens.hairline),
        backgroundColor: Colors.transparent,
        selectedColor: BethelColors.forest,
        checkmarkColor: BethelColors.ivory,
        showCheckmark: false,
        labelStyle: sans(BethelType.body),
        secondaryLabelStyle: sans(BethelType.body, color: BethelColors.ivory),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? BethelColors.brass : Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? BethelColors.forest : tokens.hairline),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: BethelColors.brass, linearTrackColor: tokens.hairline),
      sliderTheme: SliderThemeData(
        activeTrackColor: BethelColors.forest,
        inactiveTrackColor: tokens.hairline,
        thumbColor: Colors.white,
      ),
      dividerTheme: DividerThemeData(color: tokens.hairline, space: 1, thickness: 1),
      listTileTheme: ListTileThemeData(
        iconColor: muted,
        titleTextStyle: sans(BethelType.body, weight: FontWeight.w500),
        subtitleTextStyle: sans(BethelType.caption, color: muted),
        contentPadding: EdgeInsets.zero,
        minVerticalPadding: 12,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: tokens.scrim,
        showDragHandle: true,
        dragHandleColor: tokens.hairline,
        dragHandleSize: const Size(40, 5),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: serif(BethelType.title, weight: FontWeight.w500),
        contentTextStyle: sans(BethelType.body, color: muted),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: tokens.toast,
        contentTextStyle: sans(BethelType.body, color: BethelColors.ivory),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: text,
        unselectedLabelColor: muted,
        labelStyle: sans(BethelType.body, weight: FontWeight.w500),
        unselectedLabelStyle: sans(BethelType.body),
        indicatorColor: scheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: tokens.hairline,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        labelPadding: const EdgeInsets.only(right: 24),
      ),
    );
  }
}
