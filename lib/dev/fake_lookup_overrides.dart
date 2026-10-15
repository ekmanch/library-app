import 'dart:io';

import 'package:flutter_riverpod/misc.dart';

import '../data/images/artwork_providers.dart';
import '../data/images/artwork_resolver.dart';
import '../data/library_providers.dart';
import '../data/lookup/lookup_failure.dart';
import '../data/lookup/lookup_providers.dart';
import '../data/storage/json_file.dart';
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
  Set<String>? failingImages,
}) => [
  lookupSourcesProvider.overrideWithValue([
    FakeLookupSource(
      latency: latency,
      failure: failure,
      configured: configured,
    ),
  ]),
  imageFetcherProvider.overrideWithValue(
    FakeImageFetcher(latency: latency, failing: failingImages),
  ),
  appCacheDirectoryProvider.overrideWithValue(
    cacheDirectory ?? Directory.systemTemp.createTempSync('libri-cache-'),
  ),
  // Records are written at once, so no write timer is pending when a
  // widget test ends.
  artworkResolverProvider.overrideWith(
    (ref) => ArtworkResolver(
      lookups: ref.watch(lookupServiceProvider),
      cache: JsonFile(
        File(
          '${ref.watch(appCacheDirectoryProvider).path}'
          '${Platform.pathSeparator}artwork.json',
        ),
      ),
      writeDelay: Duration.zero,
    ),
  ),
];
