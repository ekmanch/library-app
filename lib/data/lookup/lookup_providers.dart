import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dev/demo_states.dart';
import '../../dev/fake_lookup.dart';
import '../library_providers.dart';
import '../storage/json_file.dart';
import 'anilist_source.dart';
import 'deezer_source.dart';
import 'google_books_fill_in.dart';
import 'igdb_source.dart';
import 'igdb_token_store.dart';
import 'lookup_keys.dart';
import 'lookup_service.dart';
import 'lookup_source.dart';
import 'open_library_source.dart';
import 'tmdb_source.dart';
import 'track_list_service.dart';
import 'track_list_store.dart';
import '../images/artwork_providers.dart';
import '../models/entry.dart';

/// The sources this build looks titles up in. The FIRST_RUN dev switch,
/// the widget tests and the screenshot walks get the fake instead (see
/// `lib/dev/fake_lookup_overrides.dart`). The real sources are added here
/// as they are built.
final lookupSourcesProvider = Provider<List<LookupSource>>((ref) {
  if (firstRunDemo) {
    return [FakeLookupSource(latency: FakeLookupSource.demoLatency)];
  }
  final client = ref.watch(httpClientProvider);
  final cache = ref.watch(appCacheDirectoryProvider);
  return [
    IgdbSource(
      client,
      clientId: LookupKeys.igdbClientId,
      clientSecret: LookupKeys.igdbClientSecret,
      tokens: IgdbTokenStore(
        JsonFile(File('${cache.path}${Platform.pathSeparator}igdb_token.json')),
      ),
    ),
    TmdbSource(client, token: LookupKeys.tmdbReadToken),
    AniListSource(client),
    OpenLibrarySource(
      client,
      fillIn: GoogleBooksFillIn(client, key: LookupKeys.googleBooksKey),
    ),
    DeezerSource(client),
  ];
});

final lookupServiceProvider = Provider<LookupService>(
  (ref) => LookupService(ref.watch(lookupSourcesProvider)),
);

/// Album track lists (A22), stored under the app cache folder. The fake
/// overrides keep them in memory.
final trackListServiceProvider = Provider<TrackListService>(
  (ref) => TrackListService(
    lookups: ref.watch(lookupServiceProvider),
    resolver: ref.watch(artworkResolverProvider),
    store: FileTrackListStore(ref.watch(appCacheDirectoryProvider)),
  ),
);

/// The track list of the album entry [entryId]: null when none could be
/// found, an error when the fetch failed (offline, or the source did not
/// answer). Fetched again when the entry's source, title or artist change,
/// not when a track is rated.
final trackListProvider = FutureProvider.autoDispose.family<TrackList?, String>(
  (ref, entryId) async {
    final album = ref.watch(
      libraryProvider.select((l) => _albumKey(l.value?.entryById(entryId))),
    );
    if (album == null) return null;
    return ref.watch(trackListServiceProvider).load(album);
  },
  // No automatic retry: offline is said as such, and opening the album
  // again asks again.
  retry: (_, _) => null,
);

/// The fields the track list depends on, so a rating does not refetch.
Entry? _albumKey(Entry? entry) => entry == null
    ? null
    : Entry(
        id: entry.id,
        type: entry.type,
        title: entry.title,
        released: entry.released,
        creator: entry.creator,
        status: entry.status,
        added: entry.added,
        source: entry.source,
        kind: entry.kind,
        album: entry.album,
      );
