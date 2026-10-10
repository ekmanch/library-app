// Theme for the Library app.
//
// Colors and fonts come from the design canvas (design/canvas.html) and
// docs/DESIGN.md. Widgets should read colors from Theme.of(context) or from
// LibraryColors.of(context), never from literals.
//
// Fonts are bundled: Bricolage Grotesque (Bold) and Figtree (Regular, Italic,
// Medium, SemiBold, Bold) in assets/fonts/, declared in pubspec.yaml.

import 'package:flutter/material.dart';

enum MediaType { movies, shows, books, games, music, anime }

/// One selectable accent color. [dark] is used on the dark theme. [ink] is the
/// darker variant used on the light theme, where the pastel would be too faint.
class AccentOption {
  const AccentOption(this.name, this.dark, this.ink);
  final String name;
  final Color dark;
  final Color ink;
}

class Accents {
  static const hotPink = AccentOption('Hot pink', Color(0xFFFF7AB6), Color(0xFFC2185B));

  static const vivid = <AccentOption>[
    AccentOption('Violet', Color(0xFFA78BFA), Color(0xFF6D3FD1)),
    hotPink,
    AccentOption('Amber', Color(0xFFF2B544), Color(0xFF9A6A00)),
    AccentOption('Green', Color(0xFF5EE08A), Color(0xFF1E7B34)),
    AccentOption('Blue', Color(0xFF5AA9FF), Color(0xFF1D5FBF)),
  ];

  // TODO: the ink values below are first guesses; check them against the
  // light theme mockup (D8) and the Settings screen (S6).
  static const pastel = <AccentOption>[
    AccentOption('Beige', Color(0xFFF9E2AF), Color(0xFF8A6A1F)),
    AccentOption('Rosewater', Color(0xFFF5E0DC), Color(0xFF9C5A4E)),
    AccentOption('Flamingo', Color(0xFFF2CDCD), Color(0xFFA14F4F)),
    AccentOption('Pink', Color(0xFFF5C2E7), Color(0xFFA83E8C)),
    AccentOption('Red', Color(0xFFF38BA8), Color(0xFFB3264E)),
    AccentOption('Mauve', Color(0xFFCBA6F7), Color(0xFF7A3FC4)),
    AccentOption('Lavender', Color(0xFFB4BEFE), Color(0xFF4A56C4)),
    AccentOption('Blue', Color(0xFF89B4FA), Color(0xFF2A5FC0)),
    AccentOption('Sky', Color(0xFF89DCEB), Color(0xFF0F7A8C)),
    AccentOption('Green', Color(0xFFA6E3A1), Color(0xFF2E7D32)),
  ];

  static const defaultAccent = hotPink;
}

/// Seasonal accents, used only inside a plan with the seasonal theme on.
class SeasonalAccents {
  static const halloween = Color(0xFFF08A3C);
  static const christmas = Color(0xFF35A56A);
}

/// Colors that Material's ColorScheme has no slot for.
@immutable
class LibraryColors extends ThemeExtension<LibraryColors> {
  const LibraryColors({
    required this.surfaceHigh,
    required this.dialog,
    required this.divider,
    required this.muted,
    required this.placeholder,
    required this.dangerText,
    required this.neutralFill,
    required this.scrim,
    required this.movies,
    required this.shows,
    required this.books,
    required this.games,
    required this.music,
    required this.anime,
    required this.cardShadow,
  });

  final Color surfaceHigh;
  final Color dialog;
  final Color divider;
  final Color muted;
  final Color placeholder;

  /// Destructive actions: red text only. Buttons use [neutralFill] behind it,
  /// never a red fill, and never sit next to an accent-colored button.
  final Color dangerText;
  final Color neutralFill;
  final Color scrim;

  final Color movies;
  final Color shows;
  final Color books;
  final Color games;
  final Color music;
  final Color anime;

  /// Empty on dark (cards use a fill); a soft shadow on light.
  final List<BoxShadow> cardShadow;

  Color forType(MediaType t) => switch (t) {
        MediaType.movies => movies,
        MediaType.shows => shows,
        MediaType.books => books,
        MediaType.games => games,
        MediaType.music => music,
        MediaType.anime => anime,
      };

  static LibraryColors of(BuildContext context) =>
      Theme.of(context).extension<LibraryColors>()!;

  static const dark = LibraryColors(
    surfaceHigh: Color(0xFF2A2D31),
    dialog: Color(0xFF26292D),
    divider: Color(0xFF26292D),
    muted: Color(0xFFA3A8AE),
    placeholder: Color(0xFF666B73),
    dangerText: Color(0xFFFF6B6B),
    neutralFill: Color(0xFF3A3E44),
    scrim: Color(0xFF08090A),
    movies: Color(0xFFF2B544),
    shows: Color(0xFF7FB7FF),
    books: Color(0xFF8FD694),
    games: Color(0xFFFF8F7A),
    music: Color(0xFFC4A7FF),
    anime: Color(0xFF5FD4C8),
    cardShadow: [],
  );

  // TODO: surfaces, muted, danger and shadow are first guesses; the type
  // colors are settled. Check against the light theme mockup (D8).
  static const light = LibraryColors(
    surfaceHigh: Color(0xFFF1F2F4),
    dialog: Color(0xFFFFFFFF),
    divider: Color(0xFFE6E8EB),
    muted: Color(0xFF5F656D),
    placeholder: Color(0xFF9AA0A8),
    dangerText: Color(0xFFC62828),
    neutralFill: Color(0xFFE6E8EB),
    scrim: Color(0x99000000),
    movies: Color(0xFFC79400),
    shows: Color(0xFF1D5FBF),
    books: Color(0xFF1E7B34),
    games: Color(0xFFC2410C),
    music: Color(0xFF6D3FD1),
    anime: Color(0xFF0F766E),
    cardShadow: [
      BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 4)),
    ],
  );

  @override
  LibraryColors copyWith() => this;

  @override
  LibraryColors lerp(ThemeExtension<LibraryColors>? other, double t) =>
      t < 0.5 || other is! LibraryColors ? this : other;
}

/// Builds the app theme.
///
/// [accent] is the user's choice from Settings. Inside a plan with the
/// seasonal theme on, wrap that screen in a Theme built with [seasonal] set.
ThemeData buildTheme({
  required Brightness brightness,
  AccentOption accent = Accents.defaultAccent,
  Color? seasonal,
}) {
  final isDark = brightness == Brightness.dark;
  final ext = isDark ? LibraryColors.dark : LibraryColors.light;

  final background = isDark ? const Color(0xFF131416) : const Color(0xFFFFFFFF);
  final surface = isDark ? const Color(0xFF1D1F22) : const Color(0xFFFFFFFF);
  final outline = isDark ? const Color(0xFF3A3E44) : const Color(0xFFD5D8DC);
  final text = isDark ? const Color(0xFFEEF0F2) : const Color(0xFF131416);
  final primary = seasonal ?? (isDark ? accent.dark : accent.ink);
  final onPrimary = isDark ? const Color(0xFF131416) : const Color(0xFFFFFFFF);

  final scheme = ColorScheme(
    brightness: brightness,
    primary: primary,
    onPrimary: onPrimary,
    secondary: primary,
    onSecondary: onPrimary,
    error: ext.dangerText,
    onError: onPrimary,
    surface: surface,
    onSurface: text,
    onSurfaceVariant: ext.muted,
    surfaceContainerHighest: ext.surfaceHigh,
    outline: outline,
    outlineVariant: ext.divider,
    scrim: ext.scrim,
  );

  final body = (isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme)
      .apply(fontFamily: 'Figtree', bodyColor: text, displayColor: text);

  TextStyle title(double size) => TextStyle(
        fontFamily: 'Bricolage Grotesque',
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * size,
        color: text,
      );

  final textTheme = body.copyWith(
    // Screen titles: 34 on top-level screens, 28 with a back arrow, 26 in sheets.
    headlineLarge: title(34),
    headlineMedium: title(28),
    headlineSmall: title(26),
    // Row title.
    titleMedium: body.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
    // Row subtitle: use with FontStyle.italic and LibraryColors.muted.
    bodySmall: body.bodySmall?.copyWith(fontSize: 13.5, color: ext.muted),
    bodyMedium: body.bodyMedium?.copyWith(fontSize: 15.5, height: 1.45),
    // Section and field labels: uppercase, set in the widget.
    labelSmall: body.labelSmall?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.04,
      color: ext.muted,
    ),
    labelLarge: body.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'Figtree',
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    textTheme: textTheme,
    extensions: [ext],
    dividerTheme: DividerThemeData(color: ext.divider, thickness: 1, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: text,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: title(28),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: ext.dialog,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: const StadiumBorder(),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: const StadiumBorder(),
        foregroundColor: text,
        side: BorderSide(color: outline),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        foregroundColor: text,
        textStyle: textTheme.labelLarge,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: onPrimary,
      shape: const CircleBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? background : ext.surfaceHigh,
      hintStyle: TextStyle(color: ext.placeholder),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: outline),
      ),
    ),
  );
}

/// Destructive button style: neutral fill with red text.
ButtonStyle destructiveButtonStyle(BuildContext context) {
  final c = LibraryColors.of(context);
  return FilledButton.styleFrom(
    backgroundColor: c.neutralFill,
    foregroundColor: c.dangerText,
  );
}
