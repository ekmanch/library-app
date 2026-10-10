import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/media_type.dart';
import '../../theme/app_theme.dart';
import '../library/library_sort.dart';
import 'entry_view.dart';

/// Display choices that live on the device, never in `library.json`.
/// Phase 2 persists them; for now they reset on restart.
@immutable
class DisplayPreferences {
  const DisplayPreferences({
    this.themeMode = ThemeMode.dark,
    this.accent = Accents.defaultAccent,
    this.viewByType = const {},
    this.sortByType = const {},
    this.filteredSort = LibrarySort.newestAdded,
  });

  final ThemeMode themeMode;
  final AccentOption accent;

  /// View per type; missing means [EntryView.text].
  final Map<MediaType, EntryView> viewByType;

  /// Sort per type's "See all" screen; missing means newest added.
  final Map<MediaType, LibrarySort> sortByType;

  /// Sort of the filtered results on the library home.
  final LibrarySort filteredSort;

  EntryView viewFor(MediaType type) => viewByType[type] ?? EntryView.text;

  LibrarySort sortFor(MediaType type) =>
      sortByType[type] ?? LibrarySort.newestAdded;

  DisplayPreferences copyWith({
    ThemeMode? themeMode,
    AccentOption? accent,
    Map<MediaType, EntryView>? viewByType,
    Map<MediaType, LibrarySort>? sortByType,
    LibrarySort? filteredSort,
  }) => DisplayPreferences(
    themeMode: themeMode ?? this.themeMode,
    accent: accent ?? this.accent,
    viewByType: viewByType ?? this.viewByType,
    sortByType: sortByType ?? this.sortByType,
    filteredSort: filteredSort ?? this.filteredSort,
  );

  @override
  bool operator ==(Object other) =>
      other is DisplayPreferences &&
      other.themeMode == themeMode &&
      other.accent == accent &&
      mapEquals(other.viewByType, viewByType) &&
      mapEquals(other.sortByType, sortByType) &&
      other.filteredSort == filteredSort;

  @override
  int get hashCode => Object.hash(
    themeMode,
    accent,
    Object.hashAllUnordered(viewByType.entries.map((e) => (e.key, e.value))),
    Object.hashAllUnordered(sortByType.entries.map((e) => (e.key, e.value))),
    filteredSort,
  );
}

class DisplayPreferencesNotifier extends Notifier<DisplayPreferences> {
  @override
  DisplayPreferences build() => const DisplayPreferences();

  void setThemeMode(ThemeMode mode) => state = state.copyWith(themeMode: mode);

  void setAccent(AccentOption accent) => state = state.copyWith(accent: accent);

  void setView(MediaType type, EntryView view) =>
      state = state.copyWith(viewByType: {...state.viewByType, type: view});

  void setSort(MediaType type, LibrarySort sort) =>
      state = state.copyWith(sortByType: {...state.sortByType, type: sort});

  void setFilteredSort(LibrarySort sort) =>
      state = state.copyWith(filteredSort: sort);
}

final displayPreferencesProvider =
    NotifierProvider<DisplayPreferencesNotifier, DisplayPreferences>(
      DisplayPreferencesNotifier.new,
    );
