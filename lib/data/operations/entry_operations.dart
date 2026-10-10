import '../models/entry.dart';
import '../models/entry_id.dart';
import '../models/entry_status.dart';
import '../models/library.dart';
import '../models/track.dart';
import 'library_operation.dart';

/// Replaces the entry with the same id in place. Missing: unchanged.
Library _replaceEntry(Library library, Entry entry) {
  final index = library.entries.indexWhere((e) => e.id == entry.id);
  if (index < 0) return library;
  final entries = [...library.entries];
  entries[index] = entry;
  return library.copyWith(entries: entries);
}

class SetStatus extends LibraryOperation {
  const SetStatus(this.entryId, this.status);

  final String entryId;
  final EntryStatus status;

  @override
  Library apply(Library library) {
    final entry = library.entryById(entryId);
    if (entry == null) return library;
    if (!EntryStatus.optionsForEntry(entry).contains(status)) {
      throw ArgumentError.value(
        status,
        'status',
        'not allowed for ${entry.type.name}',
      );
    }
    return _replaceEntry(library, entry.copyWith(status: status));
  }
}

class SetRating extends LibraryOperation {
  const SetRating(this.entryId, this.rating)
    : assert(rating == null || (rating >= 1 && rating <= 10));

  final String entryId;

  /// 1 to 10, or null to clear.
  final int? rating;

  @override
  Library apply(Library library) {
    final entry = library.entryById(entryId);
    if (entry == null) return library;
    return _replaceEntry(library, entry.copyWith(rating: rating));
  }
}

/// Appends an entry. The caller builds the id with [EntryId.generate]; if
/// that id is taken by the time the operation runs (after a sync conflict),
/// a numeric suffix is added. Tags the entry uses must already exist in the
/// tag map (see [AddTag]).
class AddEntry extends LibraryOperation {
  const AddEntry(this.entry);

  final Entry entry;

  @override
  Library apply(Library library) {
    final id = EntryId.unique(entry.id, library.entries.map((e) => e.id));
    return library.copyWith(
      entries: [
        ...library.entries,
        entry.copyWith(id: id),
      ],
    );
  }
}

/// Replaces an entry in place, keeping its id and position.
class UpdateEntry extends LibraryOperation {
  const UpdateEntry(this.entry);

  final Entry entry;

  @override
  Library apply(Library library) {
    if (library.entryById(entry.id) == null) return library;
    return _replaceEntry(library, entry).withUnusedTagsRemoved();
  }
}

/// Removes an entry everywhere: from the list and from every plan.
class DeleteEntry extends LibraryOperation {
  const DeleteEntry(this.entryId);

  final String entryId;

  @override
  Library apply(Library library) {
    if (library.entryById(entryId) == null) return library;
    return library
        .copyWith(
          entries: library.entries.where((e) => e.id != entryId).toList(),
          plans: [
            for (final plan in library.plans)
              plan.copyWith(
                items: plan.items.where((i) => i.entry != entryId).toList(),
              ),
          ],
        )
        .withUnusedTagsRemoved();
  }
}

bool _sameTrack(Track a, Track b) =>
    a.id != null && b.id != null ? a.id == b.id : a.title == b.title;

/// Adds or replaces a rated track on an album entry. Tracks match by lookup
/// id when both have one, otherwise by title.
class RateTrack extends LibraryOperation {
  const RateTrack(this.entryId, this.track);

  final String entryId;
  final Track track;

  @override
  Library apply(Library library) {
    if (track.rating < 1 || track.rating > 10) {
      throw ArgumentError.value(track.rating, 'rating', 'must be 1 to 10');
    }
    final entry = library.entryById(entryId);
    if (entry == null) return library;
    final tracks = [...?entry.tracks];
    final index = tracks.indexWhere((t) => _sameTrack(t, track));
    if (index < 0) {
      tracks.add(track);
    } else {
      tracks[index] = track;
    }
    return _replaceEntry(library, entry.copyWith(tracks: tracks));
  }
}

/// Removes a track's rating. When no rated tracks remain the `tracks` field
/// is dropped, since only rated tracks are stored.
class ClearTrackRating extends LibraryOperation {
  const ClearTrackRating(this.entryId, {this.trackId, this.title})
    : assert(trackId != null || title != null);

  final String entryId;
  final String? trackId;
  final String? title;

  @override
  Library apply(Library library) {
    final entry = library.entryById(entryId);
    if (entry == null || entry.tracks == null) return library;
    final probe = Track(title: title ?? '', id: trackId, rating: 1);
    final tracks = entry.tracks!.where((t) => !_sameTrack(t, probe)).toList();
    return _replaceEntry(
      library,
      entry.copyWith(tracks: tracks.isEmpty ? null : tracks),
    );
  }
}
