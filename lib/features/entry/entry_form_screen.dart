import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/library_providers.dart';
import '../../data/models/book_format.dart';
import '../../data/models/entry.dart';
import '../../data/models/entry_id.dart';
import '../../data/models/entry_status.dart';
import '../../data/models/media_type.dart';
import '../../data/models/music_kind.dart';
import '../../data/models/released.dart';
import '../../data/models/tag_category.dart';
import '../../data/operations/operations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/chip_grid.dart';
import '../../widgets/chips.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/labels.dart';
import '../../widgets/page_header.dart';
import '../../widgets/segmented_control.dart';
import 'lookup_matches.dart';
import 'rating_sheet.dart';
import 'tag_picker_sheet.dart';

/// Opens the form (A8) for a new entry, prefilled from a lookup [match] or
/// just a [type] and [title]. Resolves with the saved entry, or null.
Future<Entry?> openNewEntryForm(
  BuildContext context, {
  MediaType? type,
  String? title,
  LookupMatch? match,
}) {
  return Navigator.of(context, rootNavigator: true).push<Entry>(
    MaterialPageRoute(
      builder: (_) =>
          EntryFormScreen.create(type: type, title: title, match: match),
    ),
  );
}

/// Opens the form (A8) to edit [entry]. Resolves with the saved entry, or
/// null when the user went back.
Future<Entry?> openEditEntryForm(BuildContext context, Entry entry) {
  return Navigator.of(
    context,
    rootNavigator: true,
  ).push<Entry>(MaterialPageRoute(builder: (_) => EntryFormScreen.edit(entry)));
}

/// The add / edit entry form (A8). Saving applies [AddEntry] or
/// [UpdateEntry], preceded by an [AddTag] for every tag created in the tag
/// picker, and pops with the saved entry.
class EntryFormScreen extends ConsumerStatefulWidget {
  const EntryFormScreen.edit(Entry this.entry, {super.key})
    : type = null,
      title = null,
      match = null;

  const EntryFormScreen.create({super.key, this.type, this.title, this.match})
    : entry = null;

  final Entry? entry;
  final MediaType? type;
  final String? title;
  final LookupMatch? match;

  bool get isEditing => entry != null;

  /// Something to show for the release field when the text is not a date.
  static const releasedHelp = 'Use a year, 2026-12 or 2026-12-25';

  @override
  ConsumerState<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends ConsumerState<EntryFormScreen> {
  late final TextEditingController _title;
  late final TextEditingController _creator;
  late final TextEditingController _released;
  late final TextEditingController _note;
  late final TextEditingController _platform;
  late final TextEditingController _album;
  late MediaType _type;
  late MusicKind? _kind;
  late EntryStatus _status;
  late int? _rating;
  late List<String> _tags;
  final Map<String, TagCategory> _newTags = {};
  late Set<BookFormat> _formats;
  late bool _seasonalOnly;
  late String _description;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    final match = widget.match;
    _type = entry?.type ?? match?.type ?? widget.type ?? MediaType.movies;
    _kind =
        entry?.kind ??
        (_type == MediaType.music
            ? (match?.album == null ? MusicKind.album : MusicKind.song)
            : null);
    _title = TextEditingController(
      text: entry?.title ?? match?.title ?? widget.title ?? '',
    );
    _creator = TextEditingController(
      text: entry?.creator ?? match?.creator ?? '',
    );
    _released = TextEditingController(
      text: (entry?.released ?? match?.released)?.toString() ?? '',
    );
    _note = TextEditingController(text: entry?.note ?? '');
    _platform = TextEditingController(text: entry?.platform ?? '');
    _album = TextEditingController(text: entry?.album ?? match?.album ?? '');
    _status = entry?.status ?? EntryStatus.want;
    _rating = entry?.rating;
    _tags = [...?entry?.tags];
    _formats = {...?entry?.formats};
    _seasonalOnly = entry?.seasonalOnly ?? false;
    _description = entry?.description ?? match?.description ?? '';
  }

  @override
  void dispose() {
    _title.dispose();
    _creator.dispose();
    _released.dispose();
    _note.dispose();
    _platform.dispose();
    _album.dispose();
    super.dispose();
  }

  List<EntryStatus> get _statusOptions =>
      EntryStatus.optionsFor(_type, kind: _kind);

  String? get _releasedError {
    final text = _released.text.trim();
    if (text.isEmpty || Released.tryParse(text) != null) return null;
    return EntryFormScreen.releasedHelp;
  }

  bool get _canSave =>
      !_saving && _title.text.trim().isNotEmpty && _releasedError == null;

  void _pickType(MediaType type) {
    setState(() {
      _type = type;
      _kind = type == MediaType.music ? (_kind ?? MusicKind.album) : null;
      if (!_statusOptions.contains(_status)) _status = EntryStatus.want;
    });
  }

  Future<void> _pickRating() async {
    final choice = await showRatingSheet(
      context,
      title: _title.text.trim().isEmpty ? 'New entry' : _title.text.trim(),
      current: _rating,
    );
    if (choice != null && mounted) setState(() => _rating = choice.rating);
  }

  Future<void> _pickTags() async {
    final library = await ref.read(libraryRepositoryProvider).load();
    if (!mounted) return;
    final pick = await showTagPickerSheet(
      context,
      library: library,
      selected: _tags,
      created: _newTags,
      defaultCategory: switch (_type) {
        MediaType.games => TagCategory.gameGenre,
        _ => TagCategory.genre,
      },
    );
    if (pick == null || !mounted) return;
    setState(() {
      _tags = pick.selected;
      _newTags
        ..clear()
        ..addAll(pick.created);
    });
  }

  Entry _buildEntry(Iterable<String> existingIds) {
    final title = _title.text.trim();
    final creator = _creator.text.trim();
    final releasedText = _released.text.trim();
    final released = releasedText.isEmpty ? null : Released.parse(releasedText);
    final isMusic = _type == MediaType.music;
    final platform = _platform.text.trim();
    final album = _album.text.trim();
    final base = widget.entry;
    final now = DateTime.now();
    return Entry(
      id:
          base?.id ??
          EntryId.generate(
            type: _type,
            title: title,
            year: released?.year.toString(),
            artist: creator.isEmpty ? null : creator,
            existingIds: existingIds,
          ),
      type: _type,
      title: title,
      released: released,
      creator: creator.isEmpty ? null : creator,
      status: _status,
      rating: _rating,
      tags: _tags,
      note: _note.text.trim(),
      description: _description,
      seasonalOnly: _seasonalOnly,
      added: base?.added ?? DateTime(now.year, now.month, now.day),
      platform: _type == MediaType.games && platform.isNotEmpty
          ? platform
          : null,
      formats: _type == MediaType.books && _formats.isNotEmpty
          ? [
              for (final f in BookFormat.values)
                if (_formats.contains(f)) f,
            ]
          : null,
      kind: isMusic ? _kind : null,
      album: isMusic && _kind == MusicKind.song && album.isNotEmpty
          ? album
          : null,
      tracks: isMusic && _kind == MusicKind.album ? base?.tracks : null,
    );
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    final repository = ref.read(libraryRepositoryProvider);
    final library = await repository.load();
    for (final MapEntry(key: name, value: category) in _newTags.entries) {
      if (_tags.contains(name)) await repository.apply(AddTag(name, category));
    }
    final entry = _buildEntry(library.entries.map((e) => e.id));
    final Entry saved;
    if (widget.isEditing) {
      await repository.apply(UpdateEntry(entry));
      saved = entry;
    } else {
      final result = await repository.apply(AddEntry(entry));
      saved = result.entries.last;
    }
    if (mounted) Navigator.pop(context, saved);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = LibraryColors.of(context);
    final editing = widget.isEditing;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: editing ? 'Edit entry' : 'New entry',
              onBack: () => Navigator.pop(context),
              actions: [
                AppButton(
                  label: editing ? 'Save' : 'Add',
                  compact: true,
                  onPressed: _canSave ? _save : null,
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  const FieldLabel('Title'),
                  AppTextField(
                    controller: _title,
                    hintText: 'Title',
                    autofocus: !editing && _title.text.isEmpty,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  const FieldLabel('Type'),
                  ChipGrid(
                    columns: 3,
                    gap: 8,
                    children: [
                      for (final type in MediaType.values)
                        PillChip(
                          label: type.label,
                          selected: type == _type,
                          dotColor: colors.forType(type),
                          horizontalPadding: 4,
                          onTap: () => _pickType(type),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FieldLabel(creatorLabel(_type)),
                            AppTextField(
                              controller: _creator,
                              hintText: 'Optional',
                              textCapitalization: TextCapitalization.words,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 132,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const FieldLabel('Released'),
                            AppTextField(
                              controller: _released,
                              hintText: 'Year or date',
                              errorText: _releasedError,
                              textCapitalization: TextCapitalization.none,
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_type == MediaType.music && _kind == MusicKind.song) ...[
                    const SizedBox(height: 14),
                    const FieldLabel('Album'),
                    AppTextField(
                      controller: _album,
                      hintText: 'Optional',
                      textCapitalization: TextCapitalization.words,
                    ),
                  ],
                  if (_type == MediaType.games) ...[
                    const SizedBox(height: 14),
                    const FieldLabel('Platform'),
                    AppTextField(
                      controller: _platform,
                      hintText: 'Optional',
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ],
                  if (_type == MediaType.books) ...[
                    const SizedBox(height: 14),
                    const FieldLabel('Formats'),
                    Row(
                      children: [
                        for (final format in BookFormat.values) ...[
                          if (format != BookFormat.values.first)
                            const SizedBox(width: 8),
                          PillChip(
                            label: format.label,
                            selected: _formats.contains(format),
                            style: PillChipStyle.accent,
                            onTap: () => setState(() {
                              if (!_formats.remove(format)) {
                                _formats.add(format);
                              }
                            }),
                          ),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  const FieldLabel('Status'),
                  StatusSegmentedControl(
                    selected: _status,
                    type: _type,
                    kind: _kind,
                    style: SegmentedStyle.accent,
                    onChanged: (status) {
                      if (status != null) setState(() => _status = status);
                    },
                  ),
                  const SizedBox(height: 14),
                  const FieldLabel('Rating'),
                  FieldButton(
                    placeholder: _rating == null,
                    semanticsLabel: 'Rating, ${ratingLabel(_rating)}',
                    onTap: _pickRating,
                    child: Text(ratingLabel(_rating)),
                  ),
                  const SizedBox(height: 14),
                  const FieldLabel('Tags'),
                  FieldButton(
                    placeholder: _tags.isEmpty,
                    semanticsLabel: _tags.isEmpty
                        ? 'Tags, none chosen'
                        : 'Tags, ${_tags.map((t) => '#$t').join(', ')}',
                    onTap: _pickTags,
                    child: _tags.isEmpty
                        ? const Text('Choose from your tags')
                        : Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [for (final tag in _tags) TagChip(tag)],
                          ),
                  ),
                  const SizedBox(height: 14),
                  const FieldLabel('Note'),
                  AppTextField(
                    controller: _note,
                    hintText: 'Optional',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _seasonalOnly,
                    onChanged: (on) => setState(() => _seasonalOnly = on),
                    title: Text(
                      'Seasonal only',
                      style: theme.textTheme.bodyLarge,
                    ),
                    subtitle: Text(
                      'Only wanted in its season; hidden from the main lists',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on BookFormat {
  String get label => switch (this) {
    BookFormat.audiobook => 'Audiobook',
    BookFormat.physical => 'Physical',
  };
}
