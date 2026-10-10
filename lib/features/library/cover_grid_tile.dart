import 'package:flutter/material.dart';

import '../../data/models/entry.dart';
import '../../data/models/entry_status.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_icons.dart';
import '../../widgets/entry_row.dart';
import '../../widgets/labels.dart';
import 'cover_placeholder.dart';

/// One cell of the grid with covers (A21). A check badge on the cover means
/// Done; other statuses are written under the title.
class CoverGridTile extends StatelessWidget {
  const CoverGridTile({
    super.key,
    required this.entry,
    this.onTap,
    this.today,
    this.title,
    this.caption,
  });

  final Entry entry;
  final VoidCallback? onTap;
  final DateTime? today;

  /// Shown instead of the entry's title, e.g. a rated track on its album.
  final String? title;

  /// Shown instead of the status caption, e.g. the artist for an album.
  final String? caption;

  /// Fixed line boxes, so the grid can size its rows exactly whatever the
  /// platform's font metrics or text scale.
  static const titleFontSize = 14.0;
  static const titleLineHeight = 18.0;
  static const captionFontSize = 12.5;
  static const captionLineHeight = 16.0;

  /// "Want · 1999", "Want", or just "1999" when done.
  static String statusCaption(Entry entry, {DateTime? today}) {
    final subtitle = entrySubtitle(entry, today: today);
    return [
      if (entry.status != EntryStatus.done) entry.status.label,
      if (subtitle.isNotEmpty) subtitle,
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = LibraryColors.of(context);
    final done = entry.status == EntryStatus.done;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CoverPlaceholder(
                  entry: entry,
                  width: constraints.maxWidth,
                  fontSize: 13,
                ),
                if (done)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: colors.coverBadge,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: StrokeIcon(
                          AppIcons.check,
                          size: 14,
                          color: theme.colorScheme.primary,
                          semanticLabel: 'Done',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: titleLineHeight,
              child: Text(
                title ?? entry.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaler: TextScaler.noScaling,
                style: theme.textTheme.labelMedium!.copyWith(
                  fontSize: titleFontSize,
                  height: titleLineHeight / titleFontSize,
                ),
              ),
            ),
            const SizedBox(height: 1),
            SizedBox(
              height: captionLineHeight,
              child: Text(
                caption ?? statusCaption(entry, today: today),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaler: TextScaler.noScaling,
                style: theme.textTheme.bodySmall!.copyWith(
                  fontSize: captionFontSize,
                  fontStyle: FontStyle.italic,
                  height: captionLineHeight / captionFontSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
