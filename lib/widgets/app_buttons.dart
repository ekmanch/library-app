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
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonKind kind;

  /// Shown before the label at 18 px.
  final Widget? icon;

  /// 44 px tall and only as wide as its label, e.g. "Done" on a sheet.
  final bool compact;

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
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
    final compactStyle = compact
        ? const ButtonStyle(
            minimumSize: WidgetStatePropertyAll(Size(0, 44)),
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 18),
            ),
          )
        : null;
    ButtonStyle? style(ButtonStyle? kindStyle) => compactStyle == null
        ? kindStyle
        : (kindStyle ?? const ButtonStyle()).merge(compactStyle);
    return switch (kind) {
      AppButtonKind.primary => FilledButton(
        onPressed: onPressed,
        style: style(null),
        child: child,
      ),
      AppButtonKind.outline => OutlinedButton(
        onPressed: onPressed,
        style: style(null),
        child: child,
      ),
      AppButtonKind.neutral => FilledButton(
        onPressed: onPressed,
        style: style(
          FilledButton.styleFrom(
            backgroundColor: colors.neutralFill,
            foregroundColor: scheme.onSurface,
          ),
        ),
        child: child,
      ),
      AppButtonKind.destructive => FilledButton(
        onPressed: onPressed,
        style: style(
          FilledButton.styleFrom(
            backgroundColor: colors.neutralFill,
            foregroundColor: colors.dangerText,
          ),
        ),
        child: child,
      ),
      AppButtonKind.destructiveOutline => OutlinedButton(
        onPressed: onPressed,
        style: style(
          OutlinedButton.styleFrom(foregroundColor: colors.dangerText),
        ),
        child: child,
      ),
      AppButtonKind.text => TextButton(
        onPressed: onPressed,
        style: style(null),
        child: child,
      ),
    };
  }
}
