import 'package:flutter/material.dart';

import '../data/models/entry.dart';
import '../data/models/entry_status.dart';
import '../data/models/media_type.dart';
import '../data/models/music_kind.dart';
import '../theme/app_theme.dart';
import 'app_icons.dart';
import 'labels.dart';

/// The italic line under a title. The year; for books and music the creator
/// and the year; for a song its album and the year. "Not released yet" when
/// the release date is still ahead.
String entrySubtitle(Entry entry, {DateTime? today}) {
  final released = entry.released;
  if (released != null && !released.isReleasedOn(today ?? DateTime.now())) {
    return 'Not released yet';
  }
  final year = released?.year.toString();
  final lead = switch (entry.type) {
    MediaType.books => entry.creator,
    MediaType.music when entry.kind == MusicKind.song =>
      entry.album ?? entry.creator,
    MediaType.music => entry.creator,
    _ => null,
  };
  return [
    lead,
    year,
  ].where((part) => part != null && part.isNotEmpty).join(' · ');
}

/// One entry in a list: title, italic subtitle and a status mark. No tags.
class EntryRow extends StatelessWidget {
  const EntryRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    this.onTap,
  });

  EntryRow.forEntry(Entry entry, {super.key, this.onTap, DateTime? today})
    : title = entry.title,
      subtitle = entrySubtitle(entry, today: today),
      status = entry.status;

  final String title;
  final String subtitle;
  final EntryStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = LibraryColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
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
            const SizedBox(width: 12),
            StatusMark(status),
          ],
        ),
      ),
    );
  }
}

/// A check in the accent color for Done; a small pill with the status word
/// otherwise. "In progress" is filled, Want and DNF are outlined.
class StatusMark extends StatelessWidget {
  const StatusMark(this.status, {super.key});

  final EntryStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = LibraryColors.of(context);
    if (status == EntryStatus.done) {
      return StrokeIcon(
        AppIcons.check,
        size: 20,
        color: theme.colorScheme.primary,
        semanticLabel: 'Done',
      );
    }
    final filled = status == EntryStatus.inProgress;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? colors.selectedFill : null,
        borderRadius: BorderRadius.circular(12),
        border: filled ? null : Border.all(color: theme.colorScheme.outline),
      ),
      child: Text(
        status.label,
        style: theme.textTheme.labelMedium!.copyWith(fontSize: 12.5),
      ),
    );
  }
}
