import 'package:flutter_riverpod/misc.dart';

import '../data/lookup/lookup_failure.dart';
import '../data/lookup/lookup_providers.dart';
import 'fake_lookup.dart';

/// Provider overrides that make every lookup answer from the fake catalog,
/// for the widget tests, the screenshot walks and the accessibility audit.
/// [latency] shows the loading state, [failure] an error state, and
/// `configured: false` the "not set up" state.
List<Override> fakeLookupOverrides({
  Duration latency = Duration.zero,
  LookupFailure? failure,
  bool configured = true,
}) => [
  lookupSourcesProvider.overrideWithValue([
    FakeLookupSource(
      latency: latency,
      failure: failure,
      configured: configured,
    ),
  ]),
];
