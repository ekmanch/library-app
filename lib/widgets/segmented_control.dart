import 'package:flutter/material.dart';

import '../data/models/entry_status.dart';
import '../theme/app_theme.dart';
import 'labels.dart';

/// How the selected segment is shown.
enum SegmentedStyle {
  /// A neutral fill: status filters on a list screen, the theme picker.
  neutral,

  /// The accent fill: choosing a status in the entry details sheet.
  accent,
}

class SegmentOption<T> {
  const SegmentOption(this.value, this.label);
  final T value;
  final String label;
}

/// A row of equal-width segments, one selected. 44 px tall.
class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.style = SegmentedStyle.neutral,
    this.inset = false,
  });

  final List<SegmentOption<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final SegmentedStyle style;

  /// True inside a sheet, where the track uses the screen background instead
  /// of the surface color.
  final bool inset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = LibraryColors.of(context);
    final accent = style == SegmentedStyle.accent;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: inset ? theme.scaffoldBackgroundColor : scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: inset ? null : Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          for (final (i, segment) in segments.indexed) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: _Segment(
                label: segment.label,
                selected: segment.value == selected,
                background: accent
                    ? scheme.primaryContainer
                    : colors.selectedFill,
                foreground: accent
                    ? scheme.onPrimaryContainer
                    : scheme.onSurface,
                onTap: () => onChanged(segment.value),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? background : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 44,
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium!.copyWith(
                  fontSize: 13.5,
                  color: selected
                      ? foreground
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The status segments. With [includeAll] a null selection means "All".
class StatusSegmentedControl extends StatelessWidget {
  const StatusSegmentedControl({
    super.key,
    required this.selected,
    required this.onChanged,
    this.includeAll = false,
    this.style = SegmentedStyle.neutral,
    this.inset = false,
  });

  final EntryStatus? selected;
  final ValueChanged<EntryStatus?> onChanged;
  final bool includeAll;
  final SegmentedStyle style;
  final bool inset;

  @override
  Widget build(BuildContext context) {
    return SegmentedControl<EntryStatus?>(
      segments: [
        if (includeAll) const SegmentOption(null, 'All'),
        for (final status in EntryStatus.values)
          SegmentOption(status, status.label),
      ],
      selected: selected,
      onChanged: onChanged,
      style: style,
      inset: inset,
    );
  }
}
