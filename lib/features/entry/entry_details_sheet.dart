import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/library_providers.dart';
import '../../data/models/entry.dart';
import '../../data/models/music_kind.dart';
import '../../data/models/track.dart';
import '../../data/operations/operations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/chips.dart';
import '../../widgets/labels.dart';
import '../../widgets/section_heading.dart';
import '../../widgets/segmented_control.dart';
import '../../widgets/sheet_frame.dart';
import '../plans/plan_progress.dart';
import '../settings/display_preferences.dart';
import '../settings/entry_view.dart';
import '../../widgets/bordered_row.dart';
import 'add_to_plan_sheet.dart';
import 'entry_header.dart';
import 'delete_entry_dialog.dart';
import 'entry_form_screen.dart';
import 'lookup_matches.dart';
import 'rating_sheet.dart';

/// Opens the entry details sheet (A6) for the entry with [entryId].
Future<void> showEntryDetailsSheet(BuildContext context, String entryId) {
  return showAppSheet<void>(
    context,
    builder: (context) => EntryDetailsSheet(entryId: entryId),
  );
}

/// Entry details (A6): cover spot, status, rating, note, about, tags,
/// plans, Edit and Delete. An album also gets its track list with track
/// ratings (A22). Watches the library, so a change made here or in the
/// edit form shows at once. Status and rating apply immediately.
class EntryDetailsSheet extends ConsumerWidget {
  const EntryDetailsSheet({super.key, required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = LibraryColors.of(context);
    final libraryAsync = ref.watch(libraryProvider);
    // The sheet may be the first to watch the library; wait for it.
    if (!libraryAsync.hasValue) return const SizedBox(height: 120);
    final library = libraryAsync.value!;
    final entry = library.entryById(entryId);
    if (entry == null) {
      // Gone, e.g. deleted from somewhere else. Nothing to show.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
      return const SizedBox(height: 120);
    }
    final repository = ref.read(libraryRepositoryProvider);
    final plans = library.plans
        .where((p) => p.itemFor(entry.id) != null)
        .toList();
    final showCover =
        ref.watch(displayPreferencesProvider).viewForEntry(entry) !=
        EntryView.text;
    final isAlbum = entry.kind == MusicKind.album;

    Future<void> pickRating() async {
      final choice = await showRatingSheet(
        context,
        title: entry.title,
        current: entry.rating,
      );
      if (choice != null && choice.rating != entry.rating) {
        await repository.apply(SetRating(entry.id, choice.rating));
      }
    }

    Future<void> rateTrack(TrackInfo info, Track? current) async {
      final choice = await showRatingSheet(
        context,
        title: info.title,
        current: current?.rating,
      );
      if (choice == null || choice.rating == current?.rating) return;
      final rating = choice.rating;
      await repository.apply(
        rating == null
            ? ClearTrackRating(
                entry.id,
                trackId: current?.id ?? info.id,
                title: info.title,
              )
            : RateTrack(
                entry.id,
                Track(
                  title: info.title,
                  id: current?.id ?? info.id,
                  rating: rating,
                ),
              ),
      );
    }

    Future<void> delete() async {
      final ok = await confirmDeleteEntry(context, entry: entry, plans: plans);
      if (!ok) return;
      await repository.apply(DeleteEntry(entry.id));
      if (context.mounted) Navigator.of(context).pop();
    }

    return SheetFrame(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EntryHeader(entry: entry, showCover: showCover),
          const SizedBox(height: 13),
          const SectionHeading('Status', padding: EdgeInsets.zero),
          const SizedBox(height: 6),
          StatusSegmentedControl(
            selected: entry.status,
            type: entry.type,
            kind: entry.kind,
            style: SegmentedStyle.accent,
            inset: true,
            onChanged: (status) {
              if (status != null && status != entry.status) {
                repository.apply(SetStatus(entry.id, status));
              }
            },
          ),
          const SizedBox(height: 13),
          BorderedRow(
            onTap: pickRating,
            semanticsLabel: 'Rating, ${ratingLabel(entry.rating)}',
            minHeight: 48,
            leading: Text(
              isAlbum ? 'Album rating' : 'Rating',
              style: theme.textTheme.bodyMedium!.copyWith(
                fontSize: 15,
                color: colors.muted,
              ),
            ),
            trailing: Text(
              ratingLabel(entry.rating),
              style: theme.textTheme.titleMedium!.copyWith(fontSize: 15),
            ),
          ),
          if (isAlbum) ...[
            const SizedBox(height: 13),
            _TrackList(
              album: entry,
              trackList: fakeTrackList(entry),
              onRate: rateTrack,
            ),
          ],
          if (entry.note.isNotEmpty) ...[
            const SizedBox(height: 13),
            const SectionHeading('Note', padding: EdgeInsets.zero),
            const SizedBox(height: 6),
            Text(entry.note, style: theme.textTheme.bodyMedium),
          ],
          if (entry.description.isNotEmpty) ...[
            const SizedBox(height: 13),
            const SectionHeading('About', padding: EdgeInsets.zero),
            const SizedBox(height: 6),
            Text(
              entry.description,
              style: theme.textTheme.bodyMedium!.copyWith(
                fontSize: 14.5,
                color: colors.soft,
              ),
            ),
          ],
          if (entry.tags.isNotEmpty) ...[
            const SizedBox(height: 13),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final tag in entry.tags) TagChip(tag)],
            ),
          ],
          const SizedBox(height: 13),
          BorderedRow(
            onTap: () => showAddToPlanSheet(context, entry.id),
            semanticsLabel: 'Add to plan',
            minHeight: 52,
            leading: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plans.isEmpty ? 'Plans' : 'In plans',
                  style: theme.textTheme.bodySmall!.copyWith(
                    fontSize: 13,
                    fontStyle: FontStyle.normal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  plans.isEmpty
                      ? 'Not in any plan'
                      : plans.map(planTitle).join(', '),
                  style: theme.textTheme.titleMedium!.copyWith(fontSize: 15),
                ),
              ],
            ),
            trailing: Text(
              'Add to plan',
              style: theme.textTheme.labelMedium!.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Edit',
                  kind: AppButtonKind.neutral,
                  onPressed: () => openEditEntryForm(context, entry),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  label: 'Delete',
                  kind: AppButtonKind.destructive,
                  onPressed: delete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The Tracks section of an album (A22). With a cached track list every
/// track is listed, numbered, with its rating or "Rate"; the first six are
/// shown until "Show all" is tapped. Without one, only the rated tracks are
/// listed and a line says the full list needs a connection.
class _TrackList extends StatefulWidget {
  const _TrackList({
    required this.album,
    required this.trackList,
    required this.onRate,
  });

  final Entry album;
  final List<TrackInfo>? trackList;
  final Future<void> Function(TrackInfo track, Track? current) onRate;

  static const collapsedCount = 6;

  @override
  State<_TrackList> createState() => _TrackListState();
}

class _TrackListState extends State<_TrackList> {
  bool _expanded = false;

  Track? _ratingOf(TrackInfo info) {
    for (final track in widget.album.tracks ?? const <Track>[]) {
      final byId = track.id != null && info.id.isNotEmpty;
      if (byId ? track.id == info.id : track.title == info.title) return track;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = LibraryColors.of(context);
    final rated = widget.album.tracks ?? const <Track>[];
    final full = widget.trackList;
    final List<(int? number, TrackInfo info, Track? rating)> rows;
    if (full == null) {
      rows = [
        for (final track in rated)
          (null, (id: track.id ?? '', title: track.title), track),
      ];
    } else {
      final shown = _expanded || full.length <= _TrackList.collapsedCount
          ? full
          : full.sublist(0, _TrackList.collapsedCount);
      rows = [
        for (final (i, info) in shown.indexed) (i + 1, info, _ratingOf(info)),
      ];
    }
    final muted = theme.textTheme.bodyMedium!.copyWith(
      fontSize: 13.5,
      color: colors.muted,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeading(
          'Tracks',
          padding: EdgeInsets.zero,
          trailing: full == null
              ? '${rated.length} rated'
              : '${rated.length} of ${full.length} rated',
        ),
        const SizedBox(height: 4),
        for (final (number, info, rating) in rows)
          Semantics(
            button: true,
            label:
                '${info.title}, ${rating == null ? 'not rated' : ratingLabel(rating.rating)}',
            excludeSemantics: true,
            child: InkWell(
              onTap: () => widget.onRate(info, rating),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: colors.divider)),
                ),
                child: Row(
                  children: [
                    if (number != null)
                      SizedBox(width: 26, child: Text('$number', style: muted)),
                    Expanded(
                      child: Text(
                        info.title,
                        style: theme.textTheme.bodyMedium!.copyWith(
                          fontSize: 15,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      rating == null ? 'Rate' : ratingLabel(rating.rating),
                      style: theme.textTheme.labelMedium!.copyWith(
                        color: rating == null
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (full == null) ...[
          const SizedBox(height: 8),
          Text(
            rated.isEmpty
                ? 'No tracks rated yet. The full track list needs a connection.'
                : 'The full track list needs a connection.',
            style: muted,
          ),
        ] else if (!_expanded && full.length > _TrackList.collapsedCount)
          TextButton(
            onPressed: () => setState(() => _expanded = true),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
              textStyle: theme.textTheme.labelMedium,
            ),
            child: Text('Show all ${full.length} tracks'),
          ),
      ],
    );
  }
}
