import 'package:flutter/foundation.dart';

/// What the sync is doing right now.
enum SyncPhase {
  /// Nothing in progress and the last contact with GitHub went fine.
  idle,

  /// Asking GitHub whether the file changed.
  checking,

  /// A commit is on its way.
  saving,

  /// The last call found no connection; the queue waits.
  offline,

  /// The last save or check failed for another reason (rate limit, a
  /// server error, too many conflicts); Retry sends it again.
  failed,

  /// GitHub refused the token.
  tokenProblem,

  /// The file changed on GitHub and on this phone since they last
  /// matched. Nothing moves until a side is picked
  /// ([LibrarySync.resolveConflict]).
  conflict,
}

/// The sync state the banners (A12) and D6 show.
@immutable
class SyncStatus {
  const SyncStatus({
    this.phase = SyncPhase.idle,
    this.lastSynced,
    this.lastChecked,
    this.pendingCount = 0,
    this.remoteChangedAt,
  });

  static const idle = SyncStatus();

  final SyncPhase phase;

  /// When the phone's copy last matched GitHub: after a download with
  /// nothing pending, or a successful save.
  final DateTime? lastSynced;

  /// When GitHub last answered a check, for the "every 5 minutes" rule.
  final DateTime? lastChecked;

  /// Operations not yet saved to GitHub.
  final int pendingCount;

  /// The date of GitHub's last commit on the file, looked up when a
  /// conflict is found (D17 says "GitHub: last commit …").
  final DateTime? remoteChangedAt;

  bool get hasPending => pendingCount > 0;

  SyncStatus copyWith({
    SyncPhase? phase,
    DateTime? lastSynced,
    DateTime? lastChecked,
    int? pendingCount,
    DateTime? remoteChangedAt,
  }) => SyncStatus(
    phase: phase ?? this.phase,
    lastSynced: lastSynced ?? this.lastSynced,
    lastChecked: lastChecked ?? this.lastChecked,
    pendingCount: pendingCount ?? this.pendingCount,
    remoteChangedAt: remoteChangedAt ?? this.remoteChangedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is SyncStatus &&
      other.phase == phase &&
      other.lastSynced == lastSynced &&
      other.lastChecked == lastChecked &&
      other.pendingCount == pendingCount &&
      other.remoteChangedAt == remoteChangedAt;

  @override
  int get hashCode => Object.hash(
    phase,
    lastSynced,
    lastChecked,
    pendingCount,
    remoteChangedAt,
  );

  @override
  String toString() =>
      'SyncStatus(${phase.name}, pending: $pendingCount, '
      'synced: $lastSynced, checked: $lastChecked)';
}
