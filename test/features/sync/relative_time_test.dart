import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/features/sync/relative_time.dart';

void main() {
  final now = DateTime(2026, 10, 13, 20, 30);

  test('reads naturally at every distance', () {
    String at(Duration ago) => relativeTime(now.subtract(ago), now: now);
    expect(at(Duration.zero), 'just now');
    expect(at(const Duration(seconds: 59)), 'just now');
    expect(at(const Duration(minutes: 1)), '1 minute ago');
    expect(at(const Duration(minutes: 3)), '3 minutes ago');
    expect(at(const Duration(hours: 1)), '1 hour ago');
    expect(at(const Duration(hours: 5)), '5 hours ago');
    expect(at(const Duration(hours: 30)), 'yesterday');
    expect(at(const Duration(days: 2)), '2 days ago');
    expect(at(const Duration(days: 29)), '29 days ago');
    expect(at(const Duration(days: 40)), 'Sep 3, 2026');
  });

  test('a time in the future is just now', () {
    expect(
      relativeTime(now.add(const Duration(minutes: 5)), now: now),
      'just now',
    );
  });
}
