import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_type_provider.dart';
import 'library_filter.dart';

/// The filter applied on the library home. Session state, not a preference.
class LibraryFilterNotifier extends Notifier<LibraryFilter> {
  @override
  LibraryFilter build() => LibraryFilter.none;

  void set(LibraryFilter filter) => _apply(filter);

  void clear() => state = LibraryFilter.none;

  void remove(ActiveFilterChip chip) => _apply(chip.remove(state));

  /// A lone type filter becomes the type view: the filter clears and the
  /// home picks that type, as if its chip had been tapped.
  void _apply(LibraryFilter filter) {
    final type = filter.onlyType;
    if (type == null) {
      state = filter;
      return;
    }
    state = LibraryFilter.none;
    ref.read(homeTypeProvider.notifier).set(type);
  }
}

final libraryFilterProvider =
    NotifierProvider<LibraryFilterNotifier, LibraryFilter>(
      LibraryFilterNotifier.new,
    );
