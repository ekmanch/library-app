import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/media_type.dart';
import '../../widgets/labels.dart';

/// The type chip picked on the library home (A1); null means All. Shared
/// with the shell so the "+" button can say what it adds.
class HomeTypeNotifier extends Notifier<MediaType?> {
  @override
  MediaType? build() => null;

  void set(MediaType? type) => state = type;
}

final homeTypeProvider = NotifierProvider<HomeTypeNotifier, MediaType?>(
  HomeTypeNotifier.new,
);

/// The "+" button's label on the Library tab: "New entry" on All, otherwise
/// "New movie", "New album or song".
String newEntryLabel(MediaType? type) => switch (type) {
  null => 'New entry',
  MediaType.music => 'New album or song',
  _ => 'New ${type.singular.toLowerCase()}',
};
