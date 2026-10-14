import 'dart:async';

import 'package:library_app/data/repository/library_sync.dart';
import 'package:library_app/data/sync/sync_status.dart';

/// A sync that only counts what the UI asks of it.
class FakeLibrarySync implements LibrarySync {
  FakeLibrarySync([this.status = SyncStatus.idle]);

  @override
  SyncStatus status;
  final _changes = StreamController<SyncStatus>.broadcast();
  int checks = 0;
  int syncNows = 0;
  int discards = 0;

  /// Discards that kept the library on the phone (D16).
  int keeps = 0;

  @override
  Stream<SyncStatus> get statusChanges => _changes.stream;

  /// Shows a new state, as the real sync would.
  void emit(SyncStatus next) {
    status = next;
    _changes.add(next);
  }

  @override
  Future<void> checkForChanges() async => checks++;

  @override
  Future<void> syncNow() async => syncNows++;

  @override
  Future<void> discard({bool keepLibrary = false}) async {
    if (keepLibrary) {
      keeps++;
    } else {
      discards++;
    }
  }
}
