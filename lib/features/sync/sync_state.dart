import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dev/demo_states.dart';

/// The banner at the top of the Library and Plans screens (A12).
enum SyncBanner {
  saving,
  offline,
  couldNotSave,
  tokenProblem;

  String get title => switch (this) {
    saving => 'Saving your change',
    offline => 'You are offline',
    couldNotSave => 'Could not save to GitHub',
    tokenProblem => 'GitHub refused the token',
  };

  String get body => switch (this) {
    saving => 'Sending it to GitHub.',
    offline =>
      'Showing the library as it was last loaded. '
          'Changes are saved when you are back online.',
    couldNotSave => 'Your change is kept on this phone.',
    tokenProblem => 'It may have expired.',
  };

  /// The button on the right; null for a banner without one.
  String? get actionLabel => switch (this) {
    couldNotSave => 'Retry',
    tokenProblem => 'Fix',
    _ => null,
  };

  bool get isError => this == couldNotSave || this == tokenProblem;

  /// The value of the SYNC_BANNER dart-define, or null.
  static SyncBanner? fromDemo(String name) => switch (name) {
    'saving' => saving,
    'offline' => offline,
    'failed' => couldNotSave,
    'token' => tokenProblem,
    _ => null,
  };
}

/// Phase 1 has no sync, so the banner is only ever set by hand: tests, the
/// screenshots and the SYNC_BANNER dart-define. Phase 4 drives it from the
/// real sync state.
class SyncBannerNotifier extends Notifier<SyncBanner?> {
  @override
  SyncBanner? build() => SyncBanner.fromDemo(syncBannerDemo);

  void show(SyncBanner banner) => state = banner;

  void clear() => state = null;
}

final syncBannerProvider = NotifierProvider<SyncBannerNotifier, SyncBanner?>(
  SyncBannerNotifier.new,
);

/// What the app knows about its library file on GitHub (D6). Nothing is
/// stored in phase 1; a restart forgets a disconnect.
@immutable
class LibraryConnection {
  const LibraryConnection({
    required this.connected,
    this.repository = 'ekmanch/library',
    this.file = 'library.json',
    this.lastSyncedLabel = 'Last synced a few minutes ago',
  });

  final bool connected;

  /// "owner/repo".
  final String repository;

  /// Path of the data file inside the repo.
  final String file;
  final String lastSyncedLabel;

  LibraryConnection copyWith({
    bool? connected,
    String? repository,
    String? file,
    String? lastSyncedLabel,
  }) => LibraryConnection(
    connected: connected ?? this.connected,
    repository: repository ?? this.repository,
    file: file ?? this.file,
    lastSyncedLabel: lastSyncedLabel ?? this.lastSyncedLabel,
  );

  @override
  bool operator ==(Object other) =>
      other is LibraryConnection &&
      other.connected == connected &&
      other.repository == repository &&
      other.file == file &&
      other.lastSyncedLabel == lastSyncedLabel;

  @override
  int get hashCode => Object.hash(connected, repository, file, lastSyncedLabel);
}

class LibraryConnectionNotifier extends Notifier<LibraryConnection> {
  @override
  LibraryConnection build() => LibraryConnection(connected: !firstRunDemo);

  /// The end of the first run (F7) or a replaced token (D6).
  void connect({required String repository, required String file}) =>
      state = state.copyWith(
        connected: true,
        repository: repository,
        file: file,
        lastSyncedLabel: 'Last synced just now',
      );

  /// Disconnect in D6: the app starts over at the splash.
  void disconnect() => state = state.copyWith(connected: false);

  void markSynced() =>
      state = state.copyWith(lastSyncedLabel: 'Last synced just now');
}

final libraryConnectionProvider =
    NotifierProvider<LibraryConnectionNotifier, LibraryConnection>(
      LibraryConnectionNotifier.new,
    );
