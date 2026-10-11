import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/library_providers.dart';
import '../../data/models/book_format.dart';
import '../../data/models/entry.dart';
import '../../data/models/entry_id.dart';
import '../../data/models/entry_status.dart';
import '../../data/models/library.dart';
import '../../data/models/media_type.dart';
import '../../data/models/music_kind.dart';
import '../../data/models/platform_names.dart';
import '../../data/models/released.dart';
import '../../data/models/tag_category.dart';
import '../../data/operations/operations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_icons.dart';
import '../../widgets/chip_grid.dart';
import '../../widgets/chips.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/labels.dart';
import '../../widgets/page_header.dart';
import '../../widgets/segmented_control.dart';
import '../settings/display_preferences.dart';
import 'lookup_matches.dart';
import 'rating_sheet.dart';
import 'replace_dialogs.dart';
import 'similar_tags.dart';
import 'tag_dialogs.dart';
import 'tag_picker_sheet.dart';

/// Opens the form (A8) for a new entry, prefilled from a lookup [match] or
/// just a [type] and [title]. Resolves with the saved entry, or null.
Future<Entry?> openNewEntryForm(
  BuildContext context, {
  MediaType? type,
  String? title,
  LookupMatch? match,
  List<String> tags = const [],
}) {
  return Navigator.of(context, rootNavigator: true).push<Entry>(
    MaterialPageRoute(
      builder: (_) => EntryFormScreen.create(
        type: type,
        title: title,
        match: match,
        tags: tags,
      ),
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
/// picker, and pops with the saved entry. Saving an album whose songs are
/// saved, or a song whose album is, asks first (D12, D13).
class EntryFormScreen extends ConsumerStatefulWidget {
  const EntryFormScreen.edit(Entry this.entry, {super.key})
    : type = null,
      title = null,
      match = null,
      tags = const [];

  const EntryFormScreen.create({
    super.key,
    this.type,
    this.title,
    this.match,
    this.tags = const [],
  }) : entry = null;

  final Entry? entry;
  final MediaType? type;
  final String? title;
  final LookupMatch? match;

  /// Tags a new entry starts with, e.g. a plan's tags from its pool (S4).
  final List<String> tags;

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
  late final TextEditingController _otherPlatform;
  late final TextEditingController _album;
  late MediaType _type;
  late MusicKind? _kind;
  late EntryStatus _status;
  late int? _rating;
  late List<String> _tags;
  final Map<String, TagCategory> _newTags = {};

  /// Tags the lookup suggested that are not in the library, in order.
  /// Matches to existing tags were put straight into [_tags].
  List<String> _suggestedNew = const [];

  /// Existing tags the lookup matched; they start selected and come back
  /// as suggestions when removed.
  List<String> _suggestedExisting = const [];
  bool _suggestionsPrepared = false;

  /// The platform chips: from the lookup, the entry and the library, plus
  /// any typed under "Other…", in that order.
  final List<String> _platformOptions = [];
  final Set<String> _platformsOn = {};
  bool _otherPlatformOpen = false;
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
    _otherPlatform = TextEditingController();
    for (final platform in [
      ...?match?.platforms,
      ...splitPlatforms(entry?.platform),
    ]) {
      _addPlatformOption(platform);
    }
    _platformsOn.addAll(splitPlatforms(entry?.platform));
    // A new game starts with the default platform from Settings picked,
    // when the game came out on it.
    if (entry == null && _type == MediaType.games) {
      final wanted = ref.read(displayPreferencesProvider).defaultPlatform;
      final name = wanted == null ? null : normalizePlatform(wanted);
      _platformsOn.addAll(
        _platformOptions.where((p) => p.toLowerCase() == name?.toLowerCase()),
      );
    }
    _album = TextEditingController(text: entry?.album ?? match?.album ?? '');
    _status = entry?.status ?? EntryStatus.want;
    _rating = entry?.rating;
    _tags = [...?entry?.tags, ...widget.tags];
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
    _otherPlatform.dispose();
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

  double _releasedWidth(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(
        text: '0000-00-00',
        style: Theme.of(context).textTheme.bodyLarge!
            .copyWith(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width;
    painter.dispose();
    // The field's 14 px side padding, the border and a little air.
    return math.max(132.0, width + 2 * 14 + 8);
  }

  bool get _canSave =>
      !_saving && _title.text.trim().isNotEmpty && _releasedError == null;

  /// "PlayStation 5, PC" in the entry's `platform` field, as a list of
  /// spelled-out names ("PS5" reads as "PlayStation 5").
  static List<String> splitPlatforms(String? text) => [
    for (final part in (text ?? '').split(','))
      if (part.trim().isNotEmpty) normalizePlatform(part),
  ];

  /// Adds a chip unless one with the same platform is there already.
  /// Returns the chip's name.
  String _addPlatformOption(String platform) {
    final name = normalizePlatform(platform);
    for (final p in _platformOptions) {
      if (p.toLowerCase() == name.toLowerCase()) return p;
    }
    _platformOptions.add(name);
    return name;
  }

  void _addOtherPlatform() {
    final name = _otherPlatform.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _platformsOn.add(_addPlatformOption(name));
      _otherPlatform.clear();
      _otherPlatformOpen = false;
    });
  }

  /// Sorts the lookup's suggested tags into matches to the library's tags
  /// (selected at once; a near miss like "sci-fi" counts as "scifi") and
  /// new names offered under the field. At most six in total.
  void _prepareSuggestions(Library library) {
    _suggestionsPrepared = true;
    final match = widget.match;
    if (match == null) return;
    final existing = library.allTags;
    final matched = <String>[];
    final fresh = <String>[];
    for (final raw in match.tags) {
      final name = normalizeTag(raw);
      if (name.isEmpty) continue;
      final hit = existing.contains(name)
          ? name
          : findSimilarTag(name, existing);
      if (hit != null) {
        if (!matched.contains(hit)) matched.add(hit);
      } else if (!fresh.contains(name)) {
        fresh.add(name);
      }
      if (matched.length + fresh.length == 6) break;
    }
    _suggestedExisting = matched;
    _suggestedNew = fresh;
    for (final tag in matched) {
      if (!_tags.contains(tag)) _tags.add(tag);
    }
  }

  /// The suggestions not on the entry right now.
  List<String> get _suggestions => [
    for (final tag in [..._suggestedExisting, ..._suggestedNew])
      if (!_tags.contains(tag)) tag,
  ];

  Future<void> _addSuggestion(String tag) async {
    if (_suggestedExisting.contains(tag)) {
      setState(() => _tags.add(tag));
      return;
    }
    final category = await showNewTagDialog(
      context,
      name: tag,
      initial: _defaultCategory,
    );
    if (category == null || !mounted) return;
    setState(() {
      _newTags[tag] = category;
      _tags.add(tag);
    });
  }

  TagCategory get _defaultCategory => switch (_type) {
    MediaType.games => TagCategory.gameGenre,
    _ => TagCategory.genre,
  };

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
      defaultCategory: _defaultCategory,
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
    final platform = _platformOptions.where(_platformsOn.contains).join(', ');
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
    var entry = _buildEntry(library.entries.map((e) => e.id));
    final replaced = <Entry>[];
    if (entry.type == MediaType.music && mounted) {
      final ReplaceChoice? choice;
      if (entry.kind == MusicKind.song) {
        final album = albumOfSong(library, entry);
        choice = album == null
            ? ReplaceChoice.keepBoth
            : await showReplaceAlbumDialog(
                context,
                song: entry,
                album: album,
                adding: !widget.isEditing,
              );
        if (choice == ReplaceChoice.replace) replaced.add(album!);
      } else {
        final songs = songsFromAlbum(library, entry);
        choice = songs.isEmpty
            ? ReplaceChoice.keepBoth
            : await showReplaceSongsDialog(context, album: entry, songs: songs);
        if (choice == ReplaceChoice.replace) {
          entry = absorbSongs(entry, songs);
          replaced.addAll(songs);
        }
      }
      if (choice == null) {
        if (mounted) setState(() => _saving = false);
        return;
      }
    }
    for (final MapEntry(key: name, value: category) in _newTags.entries) {
      if (_tags.contains(name)) await repository.apply(AddTag(name, category));
    }
    final Entry saved;
    if (widget.isEditing) {
      await repository.apply(UpdateEntry(entry));
      saved = entry;
    } else {
      final result = await repository.apply(AddEntry(entry));
      saved = result.entries.last;
    }
    // After the save, so tags shared with the replaced entries survive the
    // pruning that a delete does.
    for (final old in replaced) {
      await repository.apply(DeleteEntry(old.id));
    }
    if (mounted) Navigator.pop(context, saved);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = LibraryColors.of(context);
    final editing = widget.isEditing;
    final library = ref.watch(libraryProvider).value;
    if (library != null && !_suggestionsPrepared) {
      // First build with the library: match the suggested tags. The
      // platform chips are only the ones the game came out on (fetched)
      // and the entry's own; anything else goes through "Other…".
      // Plain field writes, no setState.
      _prepareSuggestions(library);
    }
    final suggestions = _suggestions;
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
                  if (widget.match != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        // On light the surface is white, so the card needs
                        // its shadow to show.
                        boxShadow: colors.cardShadow,
                      ),
                      child: Row(
                        children: [
                          StrokeIcon(
                            AppIcons.sparkle,
                            size: 18,
                            color: colors.muted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Details fetched online. You can change anything.',
                              style: theme.textTheme.bodySmall!.copyWith(
                                fontStyle: FontStyle.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
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
                  if (_type == MediaType.music) ...[
                    const SizedBox(height: 14),
                    const FieldLabel('Album or song'),
                    SegmentedControl<MusicKind>(
                      segments: const [
                        SegmentOption(MusicKind.album, 'Album'),
                        SegmentOption(MusicKind.song, 'Song'),
                      ],
                      selected: _kind ?? MusicKind.album,
                      onChanged: (kind) => setState(() {
                        _kind = kind;
                        if (!_statusOptions.contains(_status)) {
                          _status = EntryStatus.want;
                        }
                      }),
                    ),
                  ],
                  const SizedBox(height: 14),
                  // Side by side while the creator keeps room for a name;
                  // stacked at a large text size on a small phone, so
                  // neither field is cut.
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final dateWidth = _releasedWidth(context);
                      final creatorField = Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FieldLabel(creatorLabel(_type)),
                          AppTextField(
                            controller: _creator,
                            hintText: 'Optional',
                            textCapitalization: TextCapitalization.words,
                          ),
                        ],
                      );
                      final releasedField = Column(
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
                      );
                      if (constraints.maxWidth - dateWidth - 12 <
                          MediaQuery.textScalerOf(context).scale(150)) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            creatorField,
                            const SizedBox(height: 14),
                            releasedField,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: creatorField),
                          const SizedBox(width: 12),
                          SizedBox(width: dateWidth, child: releasedField),
                        ],
                      );
                    },
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
                    const FieldLabel('Platforms'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final platform in _platformOptions)
                          PillChip(
                            label: platform,
                            selected: _platformsOn.contains(platform),
                            checked: true,
                            onTap: () => setState(() {
                              if (!_platformsOn.remove(platform)) {
                                _platformsOn.add(platform);
                              }
                            }),
                          ),
                        if (!_otherPlatformOpen)
                          DashedChip(
                            label: 'Other…',
                            height: 44,
                            semanticsLabel: 'Other platform',
                            onTap: () =>
                                setState(() => _otherPlatformOpen = true),
                          ),
                      ],
                    ),
                    if (_otherPlatformOpen) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _otherPlatform,
                              hintText: 'Type a platform',
                              autofocus: true,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _addOtherPlatform(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppButton(
                            label: 'Add',
                            kind: AppButtonKind.outline,
                            compact: true,
                            onPressed: _addOtherPlatform,
                          ),
                        ],
                      ),
                    ],
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
                    padding: _tags.isEmpty
                        ? const EdgeInsets.fromLTRB(14, 8, 12, 8)
                        : const EdgeInsets.fromLTRB(8, 8, 12, 8),
                    semanticsLabel: _tags.isEmpty
                        ? 'Tags, none chosen'
                        : 'Tags, ${_tags.map((t) => '#$t').join(', ')}',
                    onTap: _pickTags,
                    child: _tags.isEmpty
                        ? const Text('Choose from your tags')
                        : Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final tag in _tags)
                                TagChip(tag, isNew: _newTags.containsKey(tag)),
                            ],
                          ),
                  ),
                  if (suggestions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Suggested · tap to add',
                      style: theme.textTheme.bodySmall!.copyWith(
                        fontSize: 12.5,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in suggestions)
                          DashedChip(
                            label: '#$tag',
                            badge: _suggestedNew.contains(tag) ? 'new' : null,
                            semanticsLabel: 'Add #$tag',
                            onTap: () => _addSuggestion(tag),
                          ),
                      ],
                    ),
                  ],
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
                      'Only wanted in its season; hidden from the main lists.',
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
