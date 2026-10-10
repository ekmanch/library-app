import 'package:flutter/material.dart';

/// Uppercase section label, in the type color on the library home, muted
/// elsewhere. An optional trailing link such as "See all".
class SectionHeading extends StatelessWidget {
  const SectionHeading(
    this.label, {
    super.key,
    this.color,
    this.trailing,
    this.onTrailingTap,
    this.padding = const EdgeInsets.fromLTRB(0, 14, 0, 2),
  });

  final String label;

  /// Defaults to the muted label color.
  final Color? color;
  final String? trailing;
  final VoidCallback? onTrailingTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall!.copyWith(color: color);
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Text(label.toUpperCase(), style: style)),
          if (trailing != null)
            TextButton(
              onPressed: onTrailingTap,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
              child: Text(trailing!),
            ),
        ],
      ),
    );
  }
}
