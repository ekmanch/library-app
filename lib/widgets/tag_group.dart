import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_icons.dart';
import 'chips.dart';

/// One collapsible tag category: a 44 px header with the number picked and
/// a chevron, and the tags as accent chips when open. Used by the filter
/// sheet (A2) and the entry form's tag picker (A8).
class TagGroup extends StatelessWidget {
  const TagGroup({
    super.key,
    required this.label,
    required this.tags,
    required this.selected,
    required this.open,
    required this.onToggleOpen,
    required this.onToggleTag,
  });

  final String label;
  final List<String> tags;
  final Iterable<String> selected;
  final bool open;
  final VoidCallback onToggleOpen;
  final ValueChanged<String> onToggleTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = LibraryColors.of(context);
    final picked = tags.where(selected.contains).length;
    if (tags.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider)),
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
              // Room for the chips' 48 dp touch area above the first row.
              padding: const EdgeInsets.only(top: 4, bottom: 10),
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
