import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// How the dialog's buttons are laid out.
enum DialogActionsLayout {
  /// Two buttons side by side: Cancel on the left, the action on the right.
  row,

  /// A vertical stack of choices, usually ending in a text "Cancel".
  column,
}

/// A centered dialog: title, body, optional note, buttons.
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    this.body,
    this.content,
    this.note,
    required this.actions,
    this.actionsLayout = DialogActionsLayout.row,
  });

  final String title;
  final String? body;

  /// Anything between the body and the note: a rich-text body (D9) or the
  /// category chips of D10.
  final Widget? content;

  /// A quieter second paragraph, e.g. what happens in the GitHub history.
  final String? note;
  final List<Widget> actions;
  final DialogActionsLayout actionsLayout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = LibraryColors.of(context);
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            if (body != null) ...[
              const SizedBox(height: 12),
              Text(
                body!,
                style: theme.textTheme.bodyMedium!.copyWith(color: colors.soft),
              ),
            ],
            if (content != null) ...[const SizedBox(height: 12), content!],
            if (note != null) ...[
              const SizedBox(height: 12),
              Text(
                note!,
                style: theme.textTheme.bodyMedium!.copyWith(
                  fontSize: 14,
                  color: colors.muted,
                ),
              ),
            ],
            const SizedBox(height: 20),
            switch (actionsLayout) {
              DialogActionsLayout.row => Row(
                children: [
                  for (final (i, action) in actions.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: action),
                  ],
                ],
              ),
              DialogActionsLayout.column => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, action) in actions.indexed) ...[
                    if (i > 0) const SizedBox(height: 8),
                    action,
                  ],
                ],
              ),
            },
          ],
        ),
      ),
    );
  }
}

/// Opens a dialog styled by the theme, on the root navigator so it covers
/// the floating navigation.
Future<T?> showAppDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showDialog<T>(
    context: context,
    useRootNavigator: true,
    builder: builder,
  );
}
