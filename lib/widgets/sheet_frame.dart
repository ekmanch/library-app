import 'package:flutter/material.dart';

/// The inside of a bottom sheet: grabber, optional title row, content.
/// Side padding is 20 px like the screens. The sheet itself comes from
/// [showAppSheet], which applies the theme's shape and scrim.
class SheetFrame extends StatelessWidget {
  const SheetFrame({
    super.key,
    this.title,
    this.action,
    required this.child,
    this.scrollable = false,
  });

  final String? title;

  /// Trailing widget on the title row, e.g. a "Reset" text button.
  final Widget? action;
  final Widget child;

  /// True when the content may be taller than the screen.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grabber = Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: theme.colorScheme.outline,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
    final header = title == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(title!, style: theme.textTheme.headlineSmall),
                ),
                ?action,
              ],
            ),
          );
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [grabber, ?header, const SizedBox(height: 12), child],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: scrollable ? SingleChildScrollView(child: body) : body,
    );
  }
}

/// Opens a modal bottom sheet styled by the theme.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => SafeArea(top: false, child: builder(context)),
  );
}
