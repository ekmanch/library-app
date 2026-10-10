import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/entry.dart';
import '../../data/models/media_type.dart';
import '../../data/models/music_kind.dart';
import '../../theme/app_theme.dart';
import '../library/library_sort.dart';
import '../music/music_tab.dart';
import 'entry_view.dart';

/// Display choices that live on the device, never in `library.json`.
/// Phase 2 persists them; for now they reset on restart.
@immutable
class DisplayPreferences {
  const DisplayPreferences({
    this.themeMode = ThemeMode.dark,
    this.accent = Accents.defaultAccent,
    this.viewByType = const {},
    this.musicViewByTab = const {},
    this.sortByType = const {},
    this.filteredSort = LibrarySort.newestAdded,
    this.artistSort = LibrarySort.yearOldest,
  });

  final ThemeMode themeMode;
  final AccentOption accent;

  /// View per type; missing means [EntryView.text]. Music is remembered
  /// per tab instead, in [musicViewByTab].
  final Map<MediaType, EntryView> viewByType;

  /// View per music tab (A14); missing means [EntryView.text].
  final Map<MusicTab, EntryView> musicViewByTab;

  /// Sort per type's "See all" screen; missing means newest added.
  final Map<MediaType, LibrarySort> sortByType;

  /// Sort of the filtered results on the library home.
  final LibrarySort filteredSort;

  /// Order of the albums and songs on an artist's screen (A15).
  final LibrarySort artistSort;

  EntryView viewFor(MediaType type) => viewByType[type] ?? EntryView.text;

  EntryView viewForMusic(MusicTab tab) => musicViewByTab[tab] ?? EntryView.text;

  /// The view that decides whether an entry's details show images: its
  /// type's view, or for music the Albums or Songs tab's.
  EntryView viewForEntry(Entry entry) => switch (entry.type) {
    MediaType.music => viewForMusic(
      entry.kind == MusicKind.song ? MusicTab.songs : MusicTab.albums,
    ),
    _ => viewFor(entry.type),
  };

  LibrarySort sortFor(MediaType type) =>
      sortByType[type] ?? LibrarySort.newestAdded;

  DisplayPreferences copyWith({
    ThemeMode? themeMode,
    AccentOption? accent,
    Map<MediaType, EntryView>? viewByType,
    Map<MusicTab, EntryView>? musicViewByTab,
    Map<MediaType, LibrarySort>? sortByType,
    LibrarySort? filteredSort,
    LibrarySort? artistSort,
  }) => DisplayPreferences(
    themeMode: themeMode ?? this.themeMode,
    accent: accent ?? this.accent,
    viewByType: viewByType ?? this.viewByType,
    musicViewByTab: musicViewByTab ?? this.musicViewByTab,
    sortByType: sortByType ?? this.sortByType,
    filteredSort: filteredSort ?? this.filteredSort,
    artistSort: artistSort ?? this.artistSort,
  );

  @override
  bool operator ==(Object other) =>
      other is DisplayPreferences &&
      other.themeMode == themeMode &&
      other.accent == accent &&
      mapEquals(other.viewByType, viewByType) &&
      mapEquals(other.musicViewByTab, musicViewByTab) &&
      mapEquals(other.sortByType, sortByType) &&
      other.filteredSort == filteredSort &&
      other.artistSort == artistSort;

  @override
  int get hashCode => Object.hash(
    themeMode,
    accent,
    Object.hashAllUnordered(viewByType.entries.map((e) => (e.key, e.value))),
    Object.hashAllUnordered(
      musicViewByTab.entries.map((e) => (e.key, e.value)),
    ),
    Object.hashAllUnordered(sortByType.entries.map((e) => (e.key, e.value))),
    filteredSort,
    artistSort,
  );
}

class DisplayPreferencesNotifier extends Notifier<DisplayPreferences> {
  @override
  DisplayPreferences build() => const DisplayPreferences();

  void setThemeMode(ThemeMode mode) => state = state.copyWith(themeMode: mode);

  void setAccent(AccentOption accent) => state = state.copyWith(accent: accent);

  void setView(MediaType type, EntryView view) =>
      state = state.copyWith(viewByType: {...state.viewByType, type: view});

  void setMusicView(MusicTab tab, EntryView view) => state = state.copyWith(
    musicViewByTab: {...state.musicViewByTab, tab: view},
  );

  void setArtistSort(LibrarySort sort) =>
      state = state.copyWith(artistSort: sort);

  void setSort(MediaType type, LibrarySort sort) =>
      state = state.copyWith(sortByType: {...state.sortByType, type: sort});

  void setFilteredSort(LibrarySort sort) =>
      state = state.copyWith(filteredSort: sort);
}

final displayPreferencesProvider =
    NotifierProvider<DisplayPreferencesNotifier, DisplayPreferences>(
      DisplayPreferencesNotifier.new,
    );
