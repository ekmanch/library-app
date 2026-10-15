import 'dart:async';

/// Keeps at least [minGap] between the starts of the actions run through
/// it, in order. AniList allows about 30 requests a minute, IGDB 4 a
/// second; a scroll through a photo view must not burst past that.
class RateLimiter {
  RateLimiter(this.minGap, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final Duration minGap;
  final DateTime Function() _now;

  Future<void> _tail = Future.value();
  DateTime? _nextAllowed;

  Future<T> run<T>(Future<T> Function() action) {
    final gate = _tail.then((_) async {
      final next = _nextAllowed;
      if (next != null) {
        final wait = next.difference(_now());
        if (wait > Duration.zero) await Future<void>.delayed(wait);
      }
      _nextAllowed = _now().add(minGap);
    });
    _tail = gate;
    return gate.then((_) => action());
  }
}
