import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../data/repository/library_sync.dart';

/// When the app asks GitHub for changes on its own (DESIGN.md section 9):
/// when it comes to the foreground, every [interval] while it stays there,
/// and on a tab switch when the last check is older than [interval].
/// Pull-to-refresh and "Sync now" go to the sync directly, and a save
/// checks on its own first.
class SyncScheduler {
  SyncScheduler({
    required this._sync,
    this.interval = const Duration(minutes: 5),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Read on every use: the repository, and its sync, can be rebuilt
  /// (a replaced token).
  final LibrarySync? Function() _sync;
  final Duration interval;
  final DateTime Function() _now;

  AppLifecycleListener? _lifecycle;
  Timer? _timer;

  /// Starts listening. The first check is the repository's own, on load.
  void start() {
    _lifecycle = AppLifecycleListener(onResume: _onResume, onHide: _onHide);
    _startTimer();
  }

  void dispose() {
    _lifecycle?.dispose();
    _timer?.cancel();
  }

  /// Whether the last answer from GitHub is older than [interval].
  bool get isStale {
    final checked = _sync()?.status.lastChecked;
    return checked == null || _now().difference(checked) >= interval;
  }

  /// A tab switch: checks only when the last one is old.
  void onTabSwitch() {
    if (isStale) unawaited(_check());
  }

  void _onResume() {
    unawaited(_check());
    _startTimer();
  }

  void _onHide() {
    _timer?.cancel();
    _timer = null;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => unawaited(_check()));
  }

  Future<void> _check() async {
    await _sync()?.checkForChanges();
  }
}
