import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/github/token_store.dart';
import '../../data/library_providers.dart';
import '../../data/storage/connection_store.dart';
import '../../data/sync/sync_status.dart';
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

  /// The banner for a sync state: none while idle or checking.
  static SyncBanner? forStatus(SyncStatus status) => switch (status.phase) {
    SyncPhase.saving => saving,
    SyncPhase.offline => offline,
    SyncPhase.failed => couldNotSave,
    SyncPhase.tokenProblem => tokenProblem,
    SyncPhase.idle || SyncPhase.checking => null,
  };
}

/// A banner set by hand (tests, the screenshots) that wins over the real
/// state until [SyncBannerNotifier.follow]. [_noOverride] means none.
final _bannerOverrideProvider = NotifierProvider<_BannerOverride, Object?>(
  _BannerOverride.new,
);

const _noOverride = Object();

class _BannerOverride extends Notifier<Object?> {
  @override
  Object? build() => _noOverride;

  void set(Object? value) => state = value;
}

/// The banner to show: one forced by hand, else the SYNC_BANNER
/// dart-define, else the one for the real sync state.
class SyncBannerNotifier extends Notifier<SyncBanner?> {
  @override
  SyncBanner? build() {
    final override = ref.watch(_bannerOverrideProvider);
    if (override != _noOverride) return override as SyncBanner?;
    final demo = SyncBanner.fromDemo(syncBannerDemo);
    if (demo != null) return demo;
    final status = ref.watch(syncStatusProvider).value;
    return status == null ? null : SyncBanner.forStatus(status);
  }

  /// Forces a banner, until [follow].
  void show(SyncBanner banner) =>
      ref.read(_bannerOverrideProvider.notifier).set(banner);

  /// Forces no banner, until [follow].
  void clear() => ref.read(_bannerOverrideProvider.notifier).set(null);

  /// Back to the real sync state.
  void follow() => ref.read(_bannerOverrideProvider.notifier).set(_noOverride);
}

final syncBannerProvider = NotifierProvider<SyncBannerNotifier, SyncBanner?>(
  SyncBannerNotifier.new,
);

/// Where the library file is: a repo, a path and a branch.
@immutable
class ConnectionTarget {
  const ConnectionTarget({
    required this.repository,
    required this.file,
    required this.branch,
  });

  /// "owner/repo".
  final String repository;

  /// Path of the data file inside the repo.
  final String file;
  final String branch;

  @override
  bool operator ==(Object other) =>
      other is ConnectionTarget &&
      other.repository == repository &&
      other.file == file &&
      other.branch == branch;

  @override
  int get hashCode => Object.hash(repository, file, branch);
}

/// What the app knows about its library file on GitHub (D6), kept in
/// `connection.json`. The token is in the secure storage, not here.
@immutable
class LibraryConnection {
  const LibraryConnection({
    required this.connected,
    this.repository = 'ekmanch/library',
    this.file = 'library.json',
    this.branch = 'main',
  });

  /// The first run, with the last repo and file as hints for F3.
  static const disconnected = LibraryConnection(connected: false);

  final bool connected;

  /// "owner/repo".
  final String repository;

  /// Path of the data file inside the repo.
  final String file;
  final String branch;

  /// Where to sync, or null until connected.
  ConnectionTarget? get target => connected
      ? ConnectionTarget(repository: repository, file: file, branch: branch)
      : null;

  LibraryConnection copyWith({
    bool? connected,
    String? repository,
    String? file,
    String? branch,
  }) => LibraryConnection(
    connected: connected ?? this.connected,
    repository: repository ?? this.repository,
    file: file ?? this.file,
    branch: branch ?? this.branch,
  );

  Map<String, Object?> toJson() => {
    'repository': repository,
    'file': file,
    'branch': branch,
  };

  /// A stored connection counts as connected; the token is checked apart.
  static LibraryConnection fromJson(Map<String, Object?> json) =>
      LibraryConnection(
        connected: true,
        repository: json['repository'] as String? ?? 'ekmanch/library',
        file: json['file'] as String? ?? 'library.json',
        branch: json['branch'] as String? ?? 'main',
      );

  @override
  bool operator ==(Object other) =>
      other is LibraryConnection &&
      other.connected == connected &&
      other.repository == repository &&
      other.file == file &&
      other.branch == branch;

  @override
  int get hashCode => Object.hash(connected, repository, file, branch);
}

/// Where the token is kept. Memory outside the running app; `main`
/// overrides it with the secure storage.
final tokenStoreProvider = Provider<TokenStore>((ref) => MemoryTokenStore());

/// Where the connection is kept. Memory outside the running app; `main`
/// overrides it with `connection.json`.
final connectionStoreProvider = Provider<ConnectionStore>(
  (ref) => MemoryConnectionStore(),
);

/// The connection as read at startup. Outside the running app the default
/// counts as connected, so a test or a capture lands on the library.
final initialConnectionProvider = Provider<LibraryConnection>(
  (ref) => const LibraryConnection(connected: true),
);

/// The token as read at startup; null when there is none or the secure
/// storage could not be read, which means the first run.
final initialTokenProvider = Provider<String?>((ref) => null);

class TokenNotifier extends Notifier<String?> {
  @override
  String? build() => ref.watch(initialTokenProvider);

  Future<void> set(String token) async {
    await ref.read(tokenStoreProvider).write(token);
    state = token;
  }

  Future<void> clear() async {
    await ref.read(tokenStoreProvider).delete();
    state = null;
  }
}

/// The GitHub token in use, or null when disconnected.
final tokenProvider = NotifierProvider<TokenNotifier, String?>(
  TokenNotifier.new,
);

class LibraryConnectionNotifier extends Notifier<LibraryConnection> {
  @override
  LibraryConnection build() => firstRunDemo
      ? LibraryConnection.disconnected
      : ref.watch(initialConnectionProvider);

  /// The end of the first run (F7) or a replaced token (D6): keeps the
  /// token and the connection on the device, then the app opens the
  /// library.
  Future<void> connect({
    required String repository,
    required String file,
    required String branch,
    required String token,
  }) async {
    final connection = LibraryConnection(
      connected: true,
      repository: repository,
      file: file,
      branch: branch,
    );
    await ref.read(tokenProvider.notifier).set(token);
    await ref.read(connectionStoreProvider).save(connection.toJson());
    state = connection;
  }

  /// A new token for the same connection (D6).
  Future<void> replaceToken(String token) =>
      ref.read(tokenProvider.notifier).set(token);

  /// Disconnect in D6: the sync stops at once and the app starts over at
  /// the splash; then the cached library, the queue, the token and the
  /// connection leave the device.
  Future<void> disconnect() async {
    final discarding = ref.read(librarySyncProvider)?.discard();
    state = state.copyWith(connected: false);
    await discarding;
    await ref.read(tokenProvider.notifier).clear();
    await ref.read(connectionStoreProvider).clear();
  }
}

final libraryConnectionProvider =
    NotifierProvider<LibraryConnectionNotifier, LibraryConnection>(
      LibraryConnectionNotifier.new,
    );
