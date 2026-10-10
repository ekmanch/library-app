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
}
