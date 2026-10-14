import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_type_provider.dart';
import 'library_filter_provider.dart';

/// Tapping Library in the pill while already on the Library tab returns to
/// the home (A1): the filter and the type go, so the chips show All with
/// the status segment reset, and the home scrolls to the top. The state
/// counts the returns so the home screen can listen for the scroll.
class HomeReturnNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void goHome() {
    ref.read(libraryFilterProvider.notifier).clear();
    ref.read(homeTypeProvider.notifier).set(null);
    state++;
  }
}

final homeReturnProvider = NotifierProvider<HomeReturnNotifier, int>(
  HomeReturnNotifier.new,
);
