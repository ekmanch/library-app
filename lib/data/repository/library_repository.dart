import '../models/library.dart';
import '../operations/library_operation.dart';

/// The only way the app reads and changes the library.
///
/// Widgets never know which implementation they have: a fixture in phase 1,
/// a local file in phase 2, the GitHub repo in phase 4.
abstract class LibraryRepository {
  /// Loads the library. Later calls may return a cached copy.
  Future<Library> load();

  /// Emits the current library first, then every change.
  Stream<Library> watch();

  /// Applies one operation and returns the resulting library.
  Future<Library> apply(LibraryOperation operation);
}
