import 'package:flutter/material.dart';

import '../../data/models/library.dart';
import '../../data/models/tag_category.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_icons.dart';
import '../../widgets/labels.dart';
import '../../widgets/sheet_frame.dart';
import '../../widgets/tag_group.dart';
import 'similar_tags.dart';
import 'tag_dialogs.dart';

/// What the tag picker was closed with: the tags now on the entry, in
/// order, and the tags that do not exist yet with their categories. The
/// form creates those right before it saves the entry.
@immutable
class TagPick {
  const TagPick({required this.selected, required this.created});

  final List<String> selected;
  final Map<String, TagCategory> created;
}

/// The entry form's tag picker, the only place a tag can be created. New
/// names go through the similar-tag check (D9) and the category dialog
/// (D10). Resolves with null when dismissed.
Future<TagPick?> showTagPickerSheet(
  BuildContext context, {
  required Library library,
  required List<String> selected,
  Map<String, TagCategory> created = const {},
  TagCategory defaultCategory = TagCategory.genre,
}) {
  return showAppSheet<TagPick>(
    context,
    builder: (context) => TagPickerSheet(
      library: library,
      selected: selected,
      created: created,
      defaultCategory: defaultCategory,
    ),
  );
}

class TagPickerSheet extends StatefulWidget {
  const TagPickerSheet({
    super.key,
    required this.library,
    required this.selected,
    required this.created,
    required this.defaultCategory,
  });

  final Library library;
  final List<String> selected;
  final Map<String, TagCategory> created;
  final TagCategory defaultCategory;

  @override
  State<TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends State<TagPickerSheet> {
  late final List<String> _selected = [...widget.selected];
  late final Map<String, TagCategory> _created = {...widget.created};
  final _query = TextEditingController();
  TagCategory? _openGroup;

  @override
  void initState() {
    super.initState();
    _openGroup = _groups.keys.firstOrNull;
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  /// The library's tags plus the ones created in this picker.
  Map<TagCategory, List<String>> get _groups {
    final groups = <TagCategory, List<String>>{
      for (final MapEntry(key: k, value: v) in widget.library.tags.entries)
        k: [...v],
    };
    for (final category in TagCategory.values) {
      for (final MapEntry(key: name, value: c) in _created.entries) {
        if (c == category) groups.putIfAbsent(category, () => []).add(name);
      }
    }
    return groups;
  }

  Set<String> get _allNames => {for (final v in _groups.values) ...v};

  void _toggle(String tag) {
    setState(() {
      if (!_selected.remove(tag)) _selected.add(tag);
    });
  }

  Future<void> _create(String name) async {
    final similar = findSimilarTag(name, _allNames);
    if (similar != null) {
      final usedBy = widget.library.entries
          .where((e) => e.tags.contains(similar))
          .length;
      final choice = await showSimilarTagDialog(
        context,
        typed: name,
        existing: similar,
        usedBy: usedBy,
      );
      if (!mounted || choice == null) return;
      if (choice == SimilarTagChoice.useExisting) {
        setState(() {
          if (!_selected.contains(similar)) _selected.add(similar);
          _query.clear();
        });
        return;
      }
    }
    final category = await showNewTagDialog(
      context,
      name: name,
      initial: widget.defaultCategory,
    );
    if (!mounted || category == null) return;
    setState(() {
      _created[name] = category;
      _selected.add(name);
      _openGroup = category;
      _query.clear();
    });
  }

  void _done() {
    // A tag created and then unpicked again is not worth keeping.
    final created = {
      for (final MapEntry(key: name, value: c) in _created.entries)
        if (_selected.contains(name)) name: c,
    };
    Navigator.pop(context, TagPick(selected: _selected, created: created));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = LibraryColors.of(context);
    final query = _query.text.trim().toLowerCase();
    final candidate = normalizeTag(_query.text);
    final canCreate = candidate.isNotEmpty && !_allNames.contains(candidate);
    final groups = _groups;

    return SheetFrame(
      title: 'Tags',
      scrollable: true,
      action: AppButton(label: 'Done', compact: true, onPressed: _done),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _query,
            autofocus: _selected.isEmpty,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (canCreate) _create(candidate);
            },
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'Search or add a tag',
              isDense: true,
            ),
          ),
          if (canCreate)
            Semantics(
              button: true,
              label: 'Create #$candidate',
              excludeSemantics: true,
              child: InkWell(
                onTap: () => _create(candidate),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: colors.divider)),
                  ),
                  child: Row(
                    children: [
                      StrokeIcon(
                        AppIcons.plus,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Create #$candidate',
                          style: theme.textTheme.labelLarge!.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          for (final MapEntry(key: category, value: names) in groups.entries)
            TagGroup(
              label: category.label,
              tags: query.isEmpty
                  ? names
                  : names
                        .where((n) => n.toLowerCase().contains(query))
                        .toList(),
              selected: _selected,
              open: query.isNotEmpty || _openGroup == category,
              onToggleOpen: () => setState(
                () => _openGroup = _openGroup == category ? null : category,
              ),
              onToggleTag: _toggle,
            ),
        ],
      ),
    );
  }
}
