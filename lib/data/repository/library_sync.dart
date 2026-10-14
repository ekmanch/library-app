import '../sync/sync_status.dart';

/// The sync side of a repository that keeps the library on GitHub. The UI
/// reaches it for the banners (A12), D6 and the refresh triggers; a
/// repository without sync (the fixture) simply does not implement it.
abstract interface class LibrarySync {
  SyncStatus get status;

  /// Every change of [status].
  Stream<SyncStatus> get statusChanges;

  /// Asks GitHub whether the file changed and, if it did, shows the new
  /// library with the pending changes applied on top. Pending changes are
  /// sent too. Never throws: failures show in [status].
  Future<void> checkForChanges();

  /// [checkForChanges] without waiting for the debounce: "Sync now" in D6
  /// and Retry on a banner.
  Future<void> syncNow();

  /// Disconnect: stops syncing and removes the queue and the sync meta
  /// from the device, and the cached library too unless [keepLibrary],
  /// which leaves `library.json` in place for use without a sync (D16).
  Future<void> discard({bool keepLibrary = false});
}
