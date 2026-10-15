import 'dart:io';

import 'package:flutter_riverpod/misc.dart';

import '../data/images/artwork_providers.dart';
import '../data/library_providers.dart';
import '../data/lookup/lookup_failure.dart';
import '../data/lookup/lookup_providers.dart';
import 'fake_images.dart';
import 'fake_lookup.dart';

/// Provider overrides that keep every lookup and image off the network,
/// for the widget tests, the screenshot walks and the accessibility
/// audit: the fake catalog answers, covers are drawn, and the cache lives
/// in [cacheDirectory] (a fresh temporary folder when not given).
/// [latency] shows the loading states, [failure] an error state, and
/// `configured: false` the "not set up" state.
List<Override> fakeLookupOverrides({
  Duration latency = Duration.zero,
  LookupFailure? failure,
  bool configured = true,
  Directory? cacheDirectory,
}) => [
  lookupSourcesProvider.overrideWithValue([
    FakeLookupSource(
      latency: latency,
      failure: failure,
      configured: configured,
    ),
  ]),
  imageFetcherProvider.overrideWithValue(FakeImageFetcher(latency: latency)),
  appCacheDirectoryProvider.overrideWithValue(
    cacheDirectory ?? Directory.systemTemp.createTempSync('libri-cache-'),
  ),
  // The session prune and its timer stay out of tests and walks; the
  // prune itself has its own test.
  artworkPrunerProvider.overrideWith((ref) {}),
];
