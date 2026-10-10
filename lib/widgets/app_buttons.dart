import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppButtonKind {
  /// Accent fill. At most one per screen or dialog.
  primary,

  /// Outline, main text color.
  outline,

  /// Neutral fill, main text color.
  neutral,

  /// Neutral fill with red text. Never a red fill, and never next to an
  /// accent-colored button.
  destructive,

  /// Outline with red text, for a second destructive choice (D4).
  destructiveOutline,

  /// Plain text, 44 px tall: "Cancel" under a stack of choices.
  text,
}

/// A 48 px stadium button. Use the theme's styles; never set colors here.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = AppButtonKind.primary,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonKind kind;

  /// Shown before the label at 18 px.
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final colors = LibraryColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTheme.merge(
                data: const IconThemeData(size: 18),
                child: icon!,
              ),
              const SizedBox(width: 8),
              Text(label),
            ],
          );
    return switch (kind) {
      AppButtonKind.primary => FilledButton(onPressed: onPressed, child: child),
      AppButtonKind.outline => OutlinedButton(
        onPressed: onPressed,
        child: child,
      ),
      AppButtonKind.neutral => FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: colors.neutralFill,
          foregroundColor: scheme.onSurface,
        ),
        child: child,
      ),
      AppButtonKind.destructive => FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: colors.neutralFill,
          foregroundColor: colors.dangerText,
        ),
        child: child,
      ),
      AppButtonKind.destructiveOutline => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(foregroundColor: colors.dangerText),
        child: child,
      ),
      AppButtonKind.text => TextButton(onPressed: onPressed, child: child),
    };
  }
}
