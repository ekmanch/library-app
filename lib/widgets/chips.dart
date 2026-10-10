import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_icons.dart';

/// How a selected [PillChip] is shown.
enum PillChipStyle {
  /// Neutral fill, muted when unselected: the type chips on the library home.
  neutral,

  /// Accent fill: choices in the filter sheet and the tag picker.
  accent,
}

/// A 44 px selectable pill with an optional color dot.
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.style = PillChipStyle.neutral,
    this.dotColor,
    this.horizontalPadding = 14,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final PillChipStyle style;
  final Color? dotColor;

  /// Smaller in tight grids, like the six "Released" chips in the filter
  /// sheet. With a bounded width the chip fills it and centers its label.
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = LibraryColors.of(context);
    final accent = style == PillChipStyle.accent;
    final background = selected
        ? (accent ? scheme.primaryContainer : colors.selectedFill)
        : Colors.transparent;
    final foreground = selected
        ? (accent ? scheme.onPrimaryContainer : scheme.onSurface)
        : (accent ? scheme.onSurface : scheme.onSurfaceVariant);
    final border = selected
        ? (accent ? scheme.primaryContainer : Colors.transparent)
        : scheme.outline;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: background,
        shape: StadiumBorder(side: BorderSide(color: border)),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Container(
            height: 44,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (dotColor != null) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium!.copyWith(
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small read-only tag, shown as "#name".
class TagChip extends StatelessWidget {
  const TagChip(this.name, {super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: LibraryColors.of(context).surfaceHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '#$name',
        style: theme.textTheme.bodySmall!.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// A 44 px chip for an active filter, with a cross that removes it.
class RemovableChip extends StatelessWidget {
  const RemovableChip({super.key, required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Remove $label',
      excludeSemantics: true,
      child: Material(
        color: LibraryColors.of(context).selectedFill,
        shape: const StadiumBorder(),
        child: InkWell(
          onTap: onRemove,
          customBorder: const StadiumBorder(),
          child: Container(
            height: 44,
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium,
                  ),
                ),
                const SizedBox(width: 6),
                StrokeIcon(
                  AppIcons.closeBold,
                  size: 14,
                  color: theme.colorScheme.onSurface,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
