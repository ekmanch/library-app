import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dev/demo_states.dart';
import '../../dev/fake_images.dart';
import '../library_providers.dart';
import 'image_cache_store.dart';
import 'image_fetcher.dart';

/// Downloads images. The FIRST_RUN dev switch draws them instead (see
/// `lib/dev/fake_images.dart`); the tests and walks override this too.
final imageFetcherProvider = Provider<ImageFetcher>((ref) {
  if (firstRunDemo) return FakeImageFetcher();
  return HttpImageFetcher(ref.watch(httpClientProvider));
});

/// The image files on the device, under the app cache folder.
final imageCacheProvider = Provider<ImageCacheStore>(
  (ref) => ImageCacheStore(
    Directory(ref.watch(appCacheDirectoryProvider).path),
    fetcher: ref.watch(imageFetcherProvider),
  ),
);
