import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'library_filter.dart';

/// The filter applied on the library home. Session state, not a preference.
class LibraryFilterNotifier extends Notifier<LibraryFilter> {
  @override
  LibraryFilter build() => LibraryFilter.none;

  void set(LibraryFilter filter) => state = filter;

  void clear() => state = LibraryFilter.none;

  void remove(ActiveFilterChip chip) => state = chip.remove(state);
}

final libraryFilterProvider =
    NotifierProvider<LibraryFilterNotifier, LibraryFilter>(
      LibraryFilterNotifier.new,
    );
