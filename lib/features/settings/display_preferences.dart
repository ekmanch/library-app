import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';

/// Display choices that live on the device, never in `library.json`.
/// Phase 2 persists them; for now they reset on restart.
@immutable
class DisplayPreferences {
  const DisplayPreferences({
    this.themeMode = ThemeMode.dark,
    this.accent = Accents.defaultAccent,
  });

  final ThemeMode themeMode;
  final AccentOption accent;

  DisplayPreferences copyWith({ThemeMode? themeMode, AccentOption? accent}) =>
      DisplayPreferences(
        themeMode: themeMode ?? this.themeMode,
        accent: accent ?? this.accent,
      );

  @override
  bool operator ==(Object other) =>
      other is DisplayPreferences &&
      other.themeMode == themeMode &&
      other.accent == accent;

  @override
  int get hashCode => Object.hash(themeMode, accent);
}

class DisplayPreferencesNotifier extends Notifier<DisplayPreferences> {
  @override
  DisplayPreferences build() => const DisplayPreferences();

  void setThemeMode(ThemeMode mode) => state = state.copyWith(themeMode: mode);

  void setAccent(AccentOption accent) => state = state.copyWith(accent: accent);
}

final displayPreferencesProvider =
    NotifierProvider<DisplayPreferencesNotifier, DisplayPreferences>(
      DisplayPreferencesNotifier.new,
    );
