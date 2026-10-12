import '../models/library.dart';

/// One small change to the library, such as "set the status of X".
///
/// Every edit is an operation so that it can be re-applied to a fresh copy
/// after a sync conflict. Operations are tolerant: if their target no longer
/// exists they return the library unchanged, and they never reorder existing
/// entries or plans.
abstract class LibraryOperation {
  const LibraryOperation();

  Library apply(Library library);

  /// A short, readable account of the change in the imperative, such as
  /// "Mark The Mummy as done": the commit message when saving to GitHub.
  /// [before] is the library the operation is applied to, for the titles.
  String summary(Library before);
}
