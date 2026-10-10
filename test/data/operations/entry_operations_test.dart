import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/models/entry_status.dart';
import 'package:library_app/data/models/media_type.dart';
import 'package:library_app/data/models/tag_category.dart';
import 'package:library_app/data/models/track.dart';
import 'package:library_app/data/operations/operations.dart';

import '../../helpers/sample_library.dart';

void main() {
  test('SetStatus changes one entry in place', () {
    final result = SetStatus(mummy.id, EntryStatus.want).apply(sampleLibrary());
    expect(result.entries.first.status, EntryStatus.want);
    expect(result.entries.map((e) => e.id), [mummy.id, dirt.id]);
  });

  test('operations on a missing entry leave the library unchanged', () {
    final library = sampleLibrary();
    expect(const SetStatus('nope', EntryStatus.done).apply(library), library);
    expect(const SetRating('nope', 5).apply(library), library);
    expect(const DeleteEntry('nope').apply(library), library);
    expect(UpdateEntry(mummy.copyWith(id: 'nope')).apply(library), library);
  });

  test('SetRating sets and clears', () {
    final library = sampleLibrary();
    expect(
      SetRating(mummy.id, 3).apply(library).entryById(mummy.id)!.rating,
      3,
    );
    expect(
      SetRating(mummy.id, null).apply(library).entryById(mummy.id)!.rating,
      isNull,
    );
  });

  test('AddEntry appends and keeps the id unique', () {
    final library = sampleLibrary();
    final added = AddEntry(mummy.copyWith(title: 'The Mummy (again)'))
        .apply(library);
    expect(added.entries.length, 3);
    expect(added.entries.last.id, 'movies/the-mummy-1999-2');
    expect(added.entries.last.title, 'The Mummy (again)');

    final fresh = AddEntry(
      mummy.copyWith(id: 'movies/the-mummy-2017', type: MediaType.movies),
    ).apply(library);
    expect(fresh.entries.last.id, 'movies/the-mummy-2017');
  });

  test('UpdateEntry keeps id and position and prunes tags', () {
    final library = sampleLibrary();
    final updated = UpdateEntry(
      mummy.copyWith(title: 'The Mummy (1999)', tags: ['adventure']),
    ).apply(library);
    expect(updated.entries.first.id, mummy.id);
    expect(updated.entries.first.title, 'The Mummy (1999)');
    expect(updated.entries.map((e) => e.id), library.entries.map((e) => e.id));
    expect(updated.tags[TagCategory.mood], isNull);
    expect(updated.tags[TagCategory.genre], ['adventure', 'grunge']);
    expect(updated.tags[TagCategory.season], ['halloween', 'christmas']);
  });

  test('DeleteEntry removes the entry, its plan items and unused tags', () {
    final result = DeleteEntry(mummy.id).apply(sampleLibrary());
    expect(result.entries.map((e) => e.id), [dirt.id]);
    expect(result.plans.first.items, isEmpty);
    expect(result.tags[TagCategory.genre], ['grunge']);
    expect(result.tags[TagCategory.season], ['halloween', 'christmas']);
  });

  group('tracks', () {
    test('RateTrack adds a track, matching by id or title', () {
      final library = sampleLibrary();
      final added = RateTrack(
        dirt.id,
        const Track(title: 'Them Bones', id: 'mb:2', rating: 9),
      ).apply(library);
      expect(added.entryById(dirt.id)!.tracks!.map((t) => t.title), [
        'Rooster',
        'Them Bones',
      ]);

      final byId = RateTrack(
        dirt.id,
        const Track(title: 'Rooster (remaster)', id: 'mb:1', rating: 8),
      ).apply(library);
      expect(byId.entryById(dirt.id)!.tracks!.single.rating, 8);

      final byTitle = RateTrack(
        dirt.id,
        const Track(title: 'Rooster', rating: 7),
      ).apply(library);
      expect(byTitle.entryById(dirt.id)!.tracks!.single.rating, 7);
    });

    test('RateTrack on an album without tracks creates the list', () {
      final library = sampleLibrary();
      final bare = UpdateEntry(dirt.copyWith(tracks: null)).apply(library);
      final rated = RateTrack(
        dirt.id,
        const Track(title: 'Rain When I Die', rating: 9),
      ).apply(bare);
      expect(rated.entryById(dirt.id)!.tracks!.length, 1);
    });

    test('ClearTrackRating removes the track and drops an empty list', () {
      final library = sampleLibrary();
      final cleared = ClearTrackRating(dirt.id, trackId: 'mb:1').apply(library);
      expect(cleared.entryById(dirt.id)!.tracks, isNull);

      final two = RateTrack(
        dirt.id,
        const Track(title: 'Them Bones', rating: 9),
      ).apply(library);
      final one = ClearTrackRating(dirt.id, title: 'Them Bones').apply(two);
      expect(one.entryById(dirt.id)!.tracks!.single.title, 'Rooster');
    });
  });
}
