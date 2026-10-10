import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/library.dart';
import 'repository/library_repository.dart';

/// The repository for this run of the app. Overridden in the root
/// [ProviderScope]; there is no default on purpose, so a missing override
/// fails loudly.
final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => throw UnimplementedError(
    'Override libraryRepositoryProvider in the root ProviderScope.',
  ),
);

/// The library as it is now, updated after every applied operation.
final libraryProvider = StreamProvider<Library>(
  (ref) => ref.watch(libraryRepositoryProvider).watch(),
);
