import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_icons.dart';

/// A row in Settings (S6) and the connection screen (D6): a label on the
/// left, a muted value on the right, a hairline under it. With [onTap] the
/// row is a button and ends in a chevron.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.label,
    this.value,
    this.onTap,
    this.minHeight = 52,
  });

  final String label;
  final String? value;
  final VoidCallback? onTap;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = LibraryColors.of(context);
    final row = Container(
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          // The label keeps its natural width and the value gets the rest,
          // so "On open, then every 5 min" stays on one line where it can.
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodyLarge!.copyWith(fontSize: 16),
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value!,
                textAlign: TextAlign.end,
                style: theme.textTheme.bodyMedium!.copyWith(
                  fontSize: 14,
                  height: 1.3,
                  color: colors.muted,
                ),
              ),
            ),
          ],
          if (onTap != null) ...[
            const SizedBox(width: 6),
            StrokeIcon(AppIcons.chevronRight, size: 18, color: colors.muted),
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return Semantics(
      button: true,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}
