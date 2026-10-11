import 'package:flutter/material.dart';

import '../../data/models/entry.dart';
import '../../data/models/media_type.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_icons.dart';
import '../../widgets/chips.dart';
import '../../widgets/labels.dart';
import '../../widgets/page_header.dart';
import '../../widgets/search_field.dart';
import '../../widgets/section_heading.dart';
import 'entry_form_screen.dart';
import 'lookup_matches.dart';

/// Starts a new entry (A13 then A8), full screen above the floating
/// navigation. Resolves with the saved entry, or null.
Future<Entry?> openNewEntryScreen(
  BuildContext context, {
  MediaType? type,
  String? title,
  List<String> tags = const [],
}) {
  return Navigator.of(context, rootNavigator: true).push<Entry>(
    MaterialPageRoute(
      builder: (_) => NewEntryScreen(
        initialType: type,
        initialTitle: title,
        initialTags: tags,
      ),
    ),
  );
}

/// New entry: pick a match (A13). The title typed here is looked up; a
/// match opens the form prefilled, "Fill in the details myself" opens it
/// with just the title and type.
class NewEntryScreen extends StatefulWidget {
  const NewEntryScreen({
    super.key,
    this.initialType,
    this.initialTitle,
    this.initialTags = const [],
  });

  final MediaType? initialType;
  final String? initialTitle;
  final List<String> initialTags;

  @override
  State<NewEntryScreen> createState() => _NewEntryScreenState();
}

class _NewEntryScreenState extends State<NewEntryScreen> {
  late final _query = TextEditingController(text: widget.initialTitle ?? '');
  late MediaType? _type = widget.initialType;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _open({LookupMatch? match}) async {
    final saved = await openNewEntryForm(
      context,
      type: _type,
      title: _query.text.trim(),
      match: match,
      tags: widget.initialTags,
    );
    if (saved != null && mounted) Navigator.pop(context, saved);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = LibraryColors.of(context);
    final query = _query.text.trim();
    final matches = fakeLookup(query, type: _type);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: 'New entry',
              onBack: () => Navigator.pop(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Title',
                    style: theme.textTheme.labelSmall!.copyWith(
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SearchField(
                    controller: _query,
                    hintText: 'Title',
                    autofocus: query.isEmpty,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    PillChip(
                      label: 'All',
                      selected: _type == null,
                      onTap: () => setState(() => _type = null),
                    ),
                    for (final t in MediaType.values) ...[
                      const SizedBox(width: 8),
                      PillChip(
                        label: t.label,
                        selected: _type == t,
                        dotColor: colors.forType(t),
                        onTap: () => setState(() => _type = t),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              child: query.isEmpty
                  ? const SizedBox.shrink()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      children: [
                        if (matches.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: Text(
                              'No matches for "$query".',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium!.copyWith(
                                color: colors.muted,
                              ),
                            ),
                          )
                        else ...[
                          const SectionHeading(
                            'Is it one of these?',
                            padding: EdgeInsets.fromLTRB(0, 16, 0, 2),
                          ),
                          for (final match in matches)
                            _MatchRow(
                              match: match,
                              onTap: () => _open(match: match),
                            ),
                        ],
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (matches.isNotEmpty) ...[
                    Text(
                      'Not listed?',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                  ],
                  AppButton(
                    label: 'Fill in the details myself',
                    kind: AppButtonKind.outline,
                    onPressed: () => _open(),
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

class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.match, required this.onTap});

  final LookupMatch match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = LibraryColors.of(context);
    final kind = match.type == MediaType.music
        ? (match.album == null ? 'Album' : 'Song')
        : match.type.singular;
    final year = match.released?.year;
    final subtitle = [
      ?match.creator,
      ?match.album,
      if (match.platforms.isNotEmpty) match.platforms.join(', '),
    ].where((s) => s.isNotEmpty).join(' · ');
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.divider)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: match.type == MediaType.music ? 44 : 66,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outline),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [kind, if (year != null) '$year'].join(' · ').toUpperCase(),
                    style: theme.textTheme.labelSmall!.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: colors.forType(match.type),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    match.title,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall!.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            StrokeIcon(AppIcons.chevronRight, size: 18, color: colors.muted),
          ],
        ),
      ),
    );
  }
}
