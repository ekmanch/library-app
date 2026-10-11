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
    this.detail,
    this.onTap,
    this.minHeight = 52,
  });

  final String label;
  final String? value;

  /// A second line under the label, left-aligned in the secondary color,
  /// for a value too long to sit on the right ("When you open Libri, then
  /// every 5 minutes").
  final String? detail;
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
          // so a short value stays on one line where it can.
          Flexible(
            child: detail == null
                ? Text(
                    label,
                    style: theme.textTheme.bodyLarge!.copyWith(fontSize: 16),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: theme.textTheme.bodyLarge!.copyWith(
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          detail!,
                          style: theme.textTheme.bodyMedium!.copyWith(
                            fontSize: 14,
                            height: 1.35,
                            color: colors.muted,
                          ),
                        ),
                      ],
                    ),
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
