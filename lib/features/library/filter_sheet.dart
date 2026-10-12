import 'package:flutter/material.dart';

import '../../data/models/entry.dart';
import '../../data/models/library.dart';
import '../../data/models/media_type.dart';
import '../../data/models/music_kind.dart';
import '../../data/models/tag_category.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/chip_grid.dart';
import '../../widgets/chips.dart';
import '../../widgets/labels.dart';
import '../../widgets/search_field.dart';
import '../../widgets/section_heading.dart';
import '../../widgets/sheet_frame.dart';
import '../../widgets/tag_group.dart';
import 'library_filter.dart';

/// Opens the filter sheet (A2). Resolves with the chosen filter, or null
/// when dismissed.
Future<LibraryFilter?> showFilterSheet(
  BuildContext context, {
  required Library library,
  required LibraryFilter initial,
}) {
  return showAppSheet<LibraryFilter>(
    context,
    builder: (context) => FilterSheet(library: library, initial: initial),
  );
}

class FilterSheet extends StatefulWidget {
  const FilterSheet({super.key, required this.library, required this.initial});

  final Library library;
  final LibraryFilter initial;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late LibraryFilter _draft = widget.initial;
  TagCategory? _openGroup;
  String _tagQuery = '';

  @override
  void initState() {
    super.initState();
    _openGroup = widget.library.tags.keys.firstOrNull;
  }

  List<Entry> get _matching => _draft.apply(widget.library.entries);

  /// The decades the library actually spans, gaps filled in.
  List<Decade> get _decades =>
      Decade.optionsFor(widget.library.entries.map((e) => e.year));

  /// "Show 5 movies" when the result is a type view, else "Show 9 entries".
  static String _showLabel(int count, TypeView? view) {
    if (count == 0) return 'No entries match';
    final (one, many) = switch (view) {
      null => ('entry', 'entries'),
      (type: MediaType.music, kind: final kind?, status: _) => (
        kind == MusicKind.song ? 'song' : 'album',
        kind.plural,
      ),
      (type: MediaType.music, kind: null, status: _) => (
        'music entry',
        'music entries',
      ),
      (:final type, kind: _, status: _) => (
        countNoun(type, 1),
        countNoun(type, 2),
      ),
    };
    return 'Show $count ${count == 1 ? one : many}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = _matching.length;
    final query = _tagQuery.trim().toLowerCase();

    return SheetFrame(
      title: 'Filters',
      scrollable: true,
      action: TextButton(
        onPressed: () => setState(() => _draft = LibraryFilter.none),
        style: TextButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        child: const Text('Reset'),
      ),
      footer: AppButton(
        label: _showLabel(count, _draft.typeView),
        onPressed: count == 0 ? null : () => Navigator.pop(context, _draft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeading('Type', padding: EdgeInsets.zero),
          const SizedBox(height: 8),
          ChipGrid(
            columns: 3,
            children: [
              for (final type in MediaType.values)
                PillChip(
                  label: type.label,
                  selected: _draft.types.contains(type),
                  style: PillChipStyle.accent,
                  horizontalPadding: 4,
                  onTap: () => setState(() => _draft = _draft.toggleType(type)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SectionHeading('Status', padding: EdgeInsets.zero),
          const SizedBox(height: 8),
          FitChipRow(
            labels: [for (final s in _draft.statusOptions) s.label],
            builder: (i) {
              final status = _draft.statusOptions[i];
              return PillChip(
                label: status.label,
                selected: _draft.statuses.contains(status),
                style: PillChipStyle.accent,
                onTap: () =>
                    setState(() => _draft = _draft.toggleStatus(status)),
              );
            },
          ),
          if (_draft.offersKind) ...[
            const SizedBox(height: 12),
            SectionHeading('Kind', padding: EdgeInsets.zero),
            const SizedBox(height: 8),
            FitChipRow(
              labels: [for (final k in MusicKind.values) k.label],
              builder: (i) {
                final kind = MusicKind.values[i];
                return PillChip(
                  label: kind.label,
                  selected: _draft.kinds.contains(kind),
                  style: PillChipStyle.accent,
                  onTap: () => setState(() => _draft = _draft.toggleKind(kind)),
                );
              },
            ),
          ],
          const SizedBox(height: 12),
          if (_decades.isNotEmpty) ...[
            SectionHeading('Released', padding: EdgeInsets.zero),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                // Bleed to the sheet edges so the row scrolls under them.
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  for (final (i, decade) in _decades.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    PillChip(
                      label: decade.label,
                      selected: _draft.decades.contains(decade),
                      style: PillChipStyle.accent,
                      onTap: () =>
                          setState(() => _draft = _draft.toggleDecade(decade)),
                    ),
                  ],
                ],
              ),
            ).bleed(20),
          ],
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _draft.includeSeasonalOnly,
            onChanged: (on) => setState(
              () => _draft = _draft.copyWith(includeSeasonalOnly: on),
            ),
            title: Text(
              'Include seasonal-only',
              style: theme.textTheme.bodyLarge,
            ),
            subtitle: Text(
              'Titles you only want in their season',
              style: theme.textTheme.bodySmall,
            ),
          ),
          SectionHeading('Tags', padding: EdgeInsets.zero),
          const SizedBox(height: 8),
          SearchField(
            hintText: 'Search tags',
            onChanged: (value) => setState(() => _tagQuery = value),
          ),
          for (final MapEntry(key: category, value: names)
              in widget.library.tags.entries)
            TagGroup(
              label: category.label,
              tags: query.isEmpty
                  ? names
                  : names
                        .where((n) => n.toLowerCase().contains(query))
                        .toList(),
              selected: _draft.tags,
              open: query.isNotEmpty || _openGroup == category,
              onToggleOpen: () => setState(
                () => _openGroup = _openGroup == category ? null : category,
              ),
              onToggleTag: (tag) =>
                  setState(() => _draft = _draft.toggleTag(tag)),
            ),
        ],
      ),
    );
  }
}

extension on Widget {
  /// Lets a horizontal list run under the sheet's side padding.
  Widget bleed(double inset) => Transform.translate(
    offset: Offset(-inset, 0),
    child: SizedBox(width: double.infinity, child: this),
  );
}
