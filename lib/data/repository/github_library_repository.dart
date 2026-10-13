import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../github/git_blob.dart';
import '../github/github_api.dart';
import '../library_codec.dart';
import '../models/library.dart';
import '../operations/library_operation.dart';
import '../sync/pending_queue.dart';
import '../sync/sync_meta.dart';
import '../sync/sync_status.dart';
import 'library_repository.dart';
import 'library_sync.dart';
import 'local_library_repository.dart';

/// The library on GitHub, with a copy on the device (DESIGN.md section 9).
///
/// Reads: the cache shows at once; a conditional raw request asks GitHub
/// whether the file changed, on load and whenever the UI asks. Writes: an
/// operation goes into `pending.json`, then into the cache; after a short
/// pause every pending operation is sent as one commit whose message is
/// the operation's summary ("Mark The Mummy as done"). A conflict fetches
/// the new file and re-applies the pending operations. Offline, the queue
/// waits for the next trigger.
///
/// GitHub is the reference: a cache that differs from GitHub with nothing
/// pending is replaced, never pushed.
class GitHubLibraryRepository implements LibraryRepository, LibrarySync {
  GitHubLibraryRepository({
    required Directory directory,
    required this._api,
    required this.path,
    required this.branch,
    this.debounce = const Duration(milliseconds: 2500),
    DateTime Function()? now,
    this.maxConflictRetries = 3,
    void Function(String message)? log,
  }) : _now = now ?? DateTime.now,
       _log = log ?? debugPrint,
       _pending = PendingQueue(_file(directory, 'pending.json')),
       _metaStore = SyncMetaStore(_file(directory, 'sync.json')) {
    _cache = LocalLibraryRepository(
      _file(directory, 'library.json'),
      seed: _download,
    );
  }

  static File _file(Directory directory, String name) =>
      File('${directory.path}${Platform.pathSeparator}$name');

  /// The file inside the repo, e.g. `library.json`.
  final String path;
  final String branch;

  /// How long edits are gathered before they go out as one commit.
  final Duration debounce;
  final int maxConflictRetries;

  final GitHubApi _api;
  final DateTime Function() _now;
  final void Function(String) _log;
  late final LocalLibraryRepository _cache;
  final PendingQueue _pending;
  final SyncMetaStore _metaStore;
  SyncMeta? _meta;
  bool _metaLoaded = false;

  SyncStatus _status = SyncStatus.idle;
  final _statusChanges = StreamController<SyncStatus>.broadcast();
  Timer? _debounce;

  /// Syncs run one after another.
  Future<void> _syncing = Future.value();
  bool _checkedOnLoad = false;
  bool _discarded = false;

  // LibraryRepository

  @override
  Future<Library> load() async {
    final library = await _ensureLoaded();
    if (!_checkedOnLoad) {
      _checkedOnLoad = true;
      // In the background: the cache is already showing.
      _enqueue(() => _sync(push: true));
    }
    return library;
  }

  @override
  Stream<Library> watch() {
    // Through load(), so the queue and the meta are read and the check
    // runs; the cache's stream carries the library and any load error.
    unawaited(load().then((_) {}, onError: (Object _) {}));
    return _cache.watch();
  }

  @override
  Future<Library> apply(LibraryOperation operation) async {
    final current = await _ensureLoaded();
    final latest = _cache.current ?? current;
    if (operation.apply(latest) == latest) return latest;
    // The queue first: a crash between the two never leaves a change in
    // the cache that GitHub will not get.
    await _pending.add(operation, operation.summary(latest));
    _setStatus(_status.copyWith(pendingCount: _pending.length));
    final result = await _cache.apply(operation);
    _restartDebounce();
    return result;
  }

  // LibrarySync

  @override
  SyncStatus get status => _status;

  @override
  Stream<SyncStatus> get statusChanges => _statusChanges.stream;

  @override
  Future<void> checkForChanges() => _enqueue(() => _sync(push: true));

  @override
  Future<void> syncNow() {
    _debounce?.cancel();
    return _enqueue(() => _sync(push: true));
  }

  @override
  Future<void> discard() async {
    _discarded = true;
    _debounce?.cancel();
    await _syncing;
    await _cache.delete();
    await _pending.delete();
    await _metaStore.delete();
  }

  /// Waits for the writes and the syncs in progress. Does not start any.
  Future<void> flush() async {
    await _syncing;
    await _cache.flush();
    await _pending.flush();
  }

  void dispose() {
    _debounce?.cancel();
    _statusChanges.close();
    _cache.dispose();
  }

  // Loading

  Future<Library> _ensureLoaded() async {
    await _pending.load();
    if (!_metaLoaded) {
      // The seed download may have set it meanwhile.
      _meta ??= await _metaStore.load();
      _metaLoaded = true;
    }
    try {
      final library = await _cache.load();
      if (_status.pendingCount != _pending.length) {
        _setStatus(_status.copyWith(pendingCount: _pending.length));
      }
      return library;
    } on GitHubException catch (e) {
      // The first download failed; the load fails with it.
      _setStatus(_status.copyWith(phase: _phaseFor(e.failure)));
      rethrow;
    }
  }

  /// The cache's seed on a new install: the file from GitHub.
  Future<String> _download() async {
    final raw = await _api.getFileRaw(path, branch: branch);
    if (raw == null) throw StateError('unconditional request answered 304');
    final remote = decodeLibrary(raw.text);
    final now = _now();
    await _saveMeta(
      SyncMeta(
        etag: raw.etag,
        remoteSha: raw.blobSha,
        canonicalSha: _shaOf(remote),
        lastSynced: _pending.isEmpty ? now : null,
        lastChecked: now,
      ),
    );
    return raw.text;
  }

  // Syncing

  Future<void> _enqueue(Future<void> Function() task) {
    final run = _syncing.then((_) => _discarded ? null : task());
    _syncing = run.catchError((Object _) {});
    return run;
  }

  void _restartDebounce() {
    _debounce?.cancel();
    _debounce = Timer(debounce, () {
      _enqueue(() => _sync(push: true));
    });
  }

  /// One round: settle a save whose answer was lost, check for changes,
  /// then send what is pending. Failures end up in the status.
  Future<void> _sync({required bool push}) async {
    try {
      await _ensureLoaded();
      _setStatus(_status.copyWith(phase: SyncPhase.checking));
      await _resolveInFlight();
      await _check();
      if (push) await _push();
      _setStatus(_status.copyWith(phase: SyncPhase.idle));
    } on GitHubException catch (e) {
      _log('Sync failed: $e');
      _setStatus(_status.copyWith(phase: _phaseFor(e.failure)));
    } on Object catch (e, stack) {
      // A bug, or a file GitHub holds that the app cannot read. Shown as
      // a failure rather than lost in the chain.
      _log('Sync failed unexpectedly: $e\n$stack');
      _setStatus(_status.copyWith(phase: SyncPhase.failed));
    }
  }

  /// A save was started and its answer never came. Find out whether it
  /// landed before anything is sent again, so no change is saved twice.
  Future<void> _resolveInFlight() async {
    final inFlight = _pending.inFlight;
    if (inFlight == null) return;
    final raw = await _api.getFileRaw(path, branch: branch);
    if (raw == null) return;
    final now = _now();
    if (raw.blobSha == inFlight.blobSha) {
      _log('The save "${inFlight.message}" landed; dropping its operations.');
      await _saveMeta(
        SyncMeta(
          etag: raw.etag,
          remoteSha: raw.blobSha,
          canonicalSha: raw.blobSha,
          lastSynced: now,
          lastChecked: now,
        ),
      );
      await _pending.remove(inFlight.ids);
      return;
    }
    if (raw.blobSha == _meta?.remoteSha) {
      // The file is as it was before the save: it did not land.
      await _pending.clearInFlight();
      await _saveMeta(_meta!.copyWith(etag: raw.etag, lastChecked: now));
      return;
    }
    // Something else was saved since. The commit list tells whether ours
    // is among it.
    final commits = await _api.commits(path, branch: branch, limit: 5);
    final since = inFlight.startedAt.subtract(const Duration(minutes: 5));
    final landed = commits.any(
      (c) => c.message == inFlight.message && c.date.isAfter(since),
    );
    if (landed) {
      _log('The save "${inFlight.message}" landed under later changes.');
      await _pending.remove(inFlight.ids);
    } else {
      await _pending.clearInFlight();
    }
    // The check that follows sees a changed file and takes it.
  }

  /// Asks GitHub whether the file changed. If it did, GitHub's copy wins
  /// and the pending operations are applied on top of it.
  Future<void> _check() async {
    final meta = _meta;
    final cached = _cache.current;
    final drift =
        meta != null &&
        cached != null &&
        _pending.isEmpty &&
        _shaOf(cached) != meta.canonicalSha;
    if (drift) {
      _log(
        'The cached library differs from GitHub with nothing pending; '
        'taking GitHub\'s copy.',
      );
    }
    final raw = await _api.getFileRaw(
      path,
      branch: branch,
      etag: drift ? null : meta?.etag,
    );
    final now = _now();
    if (raw == null) {
      // 304: unchanged.
      await _saveMeta(
        meta!.copyWith(
          lastChecked: now,
          lastSynced: _pending.isEmpty ? now : null,
        ),
      );
      return;
    }
    if (!drift && meta != null && raw.blobSha == meta.remoteSha) {
      await _saveMeta(
        meta.copyWith(
          etag: raw.etag,
          lastChecked: now,
          lastSynced: _pending.isEmpty ? now : null,
        ),
      );
      return;
    }
    final remote = decodeLibrary(raw.text);
    var library = remote;
    final dropped = <int>[];
    for (final pending in _pending.operations) {
      try {
        library = pending.operation.apply(library);
      } on Object catch (e) {
        _log('Dropping "${pending.summary}", it no longer applies: $e');
        dropped.add(pending.id);
      }
    }
    if (dropped.isNotEmpty) await _pending.remove(dropped);
    await _cache.replace(library);
    await _saveMeta(
      SyncMeta(
        etag: raw.etag,
        remoteSha: raw.blobSha,
        canonicalSha: _shaOf(remote),
        lastSynced: _pending.isEmpty ? now : meta?.lastSynced,
        lastChecked: now,
      ),
    );
  }

  /// Sends the pending operations as one commit. A conflict means the
  /// file changed since the check: take the new file, re-apply, try again.
  Future<void> _push() async {
    for (var attempt = 0; ; attempt++) {
      final operations = _pending.operations;
      if (operations.isEmpty) return;
      final meta = _meta!;
      final ids = operations.map((o) => o.id).toList();
      final bytes = utf8.encode(encodeLibrary(_cache.current!));
      final sha = gitBlobSha(bytes);
      if (sha == meta.remoteSha) {
        // The changes cancel out, or they are on GitHub already.
        await _pending.remove(ids);
        return;
      }
      final message = _message(operations);
      await _pending.markInFlight(
        InFlight(ids: ids, blobSha: sha, message: message, startedAt: _now()),
      );
      _setStatus(_status.copyWith(phase: SyncPhase.saving));
      try {
        final result = await _api.putFile(
          path,
          branch: branch,
          bytes: bytes,
          message: message,
          sha: meta.remoteSha,
        );
        final now = _now();
        await _saveMeta(
          SyncMeta(
            remoteSha: result.blobSha,
            canonicalSha: result.blobSha,
            commitSha: result.commitSha,
            lastSynced: now,
            lastChecked: now,
          ),
        );
        await _pending.remove(ids);
        return;
      } on GitHubException catch (e) {
        if (e.failure != GitHubFailure.conflict ||
            attempt >= maxConflictRetries) {
          rethrow;
        }
        // A rejected save never landed.
        await _pending.clearInFlight();
        _log('The file changed under the save; taking it and trying again.');
        _setStatus(_status.copyWith(phase: SyncPhase.checking));
        await _check();
      }
    }
  }

  /// One operation: its summary. Several: the first and how many more,
  /// with every summary listed in the body.
  static String _message(List<PendingOperation> operations) {
    final first = operations.first.summary;
    if (operations.length == 1) return first;
    final others = operations.length - 1;
    final subject = '$first and $others other change${others == 1 ? '' : 's'}';
    final body = operations.map((o) => '- ${o.summary}').join('\n');
    return '$subject\n\n$body';
  }

  Future<void> _saveMeta(SyncMeta meta) async {
    _meta = meta;
    _setStatus(
      _status.copyWith(
        lastSynced: meta.lastSynced,
        lastChecked: meta.lastChecked,
        pendingCount: _pending.length,
      ),
    );
    await _metaStore.save(meta);
  }

  static String _shaOf(Library library) =>
      gitBlobSha(utf8.encode(encodeLibrary(library)));

  static SyncPhase _phaseFor(GitHubFailure failure) => switch (failure) {
    GitHubFailure.unauthorized ||
    GitHubFailure.forbidden => SyncPhase.tokenProblem,
    GitHubFailure.offline => SyncPhase.offline,
    _ => SyncPhase.failed,
  };

  void _setStatus(SyncStatus status) {
    final next = status.copyWith(pendingCount: _pending.length);
    if (next == _status) return;
    _status = next;
    if (!_statusChanges.isClosed) _statusChanges.add(next);
  }
}
