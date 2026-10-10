import 'package:flutter/material.dart';

import '../../data/models/entry.dart';
import '../../data/models/entry_status.dart';
import '../../data/models/library.dart';
import '../../data/models/media_type.dart';
import '../../data/models/tag_category.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_icons.dart';
import '../../widgets/chips.dart';
import '../../widgets/labels.dart';
import '../../widgets/section_heading.dart';
import '../../widgets/sheet_frame.dart';
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

extension TagCategoryLabel on TagCategory {
  String get label => switch (this) {
    TagCategory.genre => 'Genre',
    TagCategory.animationStyle => 'Animation style',
    TagCategory.gameGenre => 'Game genre',
    TagCategory.mood => 'Mood',
    TagCategory.season => 'Season',
    TagCategory.creators => 'Creators',
    TagCategory.other => 'Other',
  };
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = LibraryColors.of(context);
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
        label: switch (count) {
          0 => 'No entries match',
          1 => 'Show 1 entry',
          _ => 'Show $count entries',
        },
        onPressed: count == 0 ? null : () => Navigator.pop(context, _draft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeading('Type', padding: EdgeInsets.zero),
          const SizedBox(height: 8),
          _ChipGrid(
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
          _ChipGrid(
            columns: 4,
            children: [
              for (final status in EntryStatus.values)
                PillChip(
                  label: status.label,
                  selected: _draft.statuses.contains(status),
                  style: PillChipStyle.accent,
                  horizontalPadding: 4,
                  onTap: () =>
                      setState(() => _draft = _draft.toggleStatus(status)),
                ),
            ],
          ),
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
          TextField(
            onChanged: (value) => setState(() => _tagQuery = value),
            decoration: const InputDecoration(
              hintText: 'Search tags',
              isDense: true,
            ),
          ),
          for (final MapEntry(key: category, value: names)
              in widget.library.tags.entries)
            _TagGroup(
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
              divider: colors.divider,
            ),
        ],
      ),
    );
  }
}

/// Equal-width chips in rows, 6 px apart, like the CSS grids in A2.
class _ChipGrid extends StatelessWidget {
  const _ChipGrid({required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var start = 0; start < children.length; start += columns) {
      final row = children.sublist(
        start,
        (start + columns).clamp(0, children.length),
      );
      rows.add(
        Row(
          children: [
            for (var i = 0; i < columns; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(child: i < row.length ? row[i] : const SizedBox()),
            ],
          ],
        ),
      );
    }
    return Column(
      children: [
        for (final (i, row) in rows.indexed) ...[
          if (i > 0) const SizedBox(height: 6),
          row,
        ],
      ],
    );
  }
}

class _TagGroup extends StatelessWidget {
  const _TagGroup({
    required this.label,
    required this.tags,
    required this.selected,
    required this.open,
    required this.onToggleOpen,
    required this.onToggleTag,
    required this.divider,
  });

  final String label;
  final List<String> tags;
  final Set<String> selected;
  final bool open;
  final VoidCallback onToggleOpen;
  final ValueChanged<String> onToggleTag;
  final Color divider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final picked = tags.where(selected.contains).length;
    if (tags.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: open,
            child: InkWell(
              onTap: onToggleOpen,
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(label, style: theme.textTheme.labelLarge),
                    ),
                    if (picked > 0)
                      Text(
                        '$picked selected',
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontSize: 13,
                        ),
                      ),
                    const SizedBox(width: 8),
                    RotatedBox(
                      quarterTurns: open ? 2 : 0,
                      child: StrokeIcon(
                        AppIcons.chevronDown,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in tags)
                    PillChip(
                      label: '#$tag',
                      selected: selected.contains(tag),
                      style: PillChipStyle.accent,
                      onTap: () => onToggleTag(tag),
                    ),
                ],
              ),
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
