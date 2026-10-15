import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dev/demo_states.dart';
import '../../dev/fake_lookup.dart';
import '../library_providers.dart';
import 'lookup_keys.dart';
import 'lookup_service.dart';
import 'lookup_source.dart';
import 'tmdb_source.dart';

/// The sources this build looks titles up in. The FIRST_RUN dev switch,
/// the widget tests and the screenshot walks get the fake instead (see
/// `lib/dev/fake_lookup_overrides.dart`). The real sources are added here
/// as they are built.
final lookupSourcesProvider = Provider<List<LookupSource>>((ref) {
  if (firstRunDemo) {
    return [FakeLookupSource(latency: FakeLookupSource.demoLatency)];
  }
  final client = ref.watch(httpClientProvider);
  return [TmdbSource(client, token: LookupKeys.tmdbReadToken)];
});

final lookupServiceProvider = Provider<LookupService>(
  (ref) => LookupService(ref.watch(lookupSourcesProvider)),
);
