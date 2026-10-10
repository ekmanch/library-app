import 'package:flutter/material.dart';

import '../../widgets/app_icons.dart';
import '../settings/entry_view.dart';

StrokeIconData viewIcon(EntryView view) => switch (view) {
  EntryView.text => AppIcons.textView,
  EntryView.listWithPhotos => AppIcons.listView,
  EntryView.grid => AppIcons.gridView,
};

/// The 44 px button showing the current view; opens the view menu (A16)
/// anchored under it.
class ViewMenuButton extends StatelessWidget {
  const ViewMenuButton({
    super.key,
    required this.current,
    required this.onChanged,
  });

  final EntryView current;
  final ValueChanged<EntryView> onChanged;

  Future<void> _open(BuildContext context) async {
    final theme = Theme.of(context);
    final button = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final origin = button.localToGlobal(Offset.zero, ancestor: overlay);
    final position = RelativeRect.fromLTRB(
      origin.dx + button.size.width - 240,
      origin.dy + button.size.height + 4,
      overlay.size.width - origin.dx - button.size.width,
      0,
    );
    final picked = await showMenu<EntryView>(
      context: context,
      useRootNavigator: true,
      position: position,
      // Material's default 300 ms reveal feels sluggish for a small menu.
      popUpAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 150),
        reverseDuration: Duration(milliseconds: 100),
      ),
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 240),
      items: [
        PopupMenuItem<EntryView>(
          enabled: false,
          height: 32,
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
          child: Text('VIEW', style: theme.textTheme.labelSmall),
        ),
        for (final view in EntryView.values)
          PopupMenuItem<EntryView>(
            value: view,
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                StrokeIcon(
                  viewIcon(view),
                  size: 20,
                  color: theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(view.label, style: theme.textTheme.titleMedium),
                ),
                if (view == current)
                  StrokeIcon(
                    AppIcons.check,
                    size: 20,
                    color: theme.colorScheme.primary,
                    semanticLabel: 'Selected',
                  ),
              ],
            ),
          ),
      ],
    );
    if (picked != null && picked != current) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _open(context),
      tooltip: 'Change view',
      color: Theme.of(context).colorScheme.onSurface,
      icon: StrokeIcon(viewIcon(current), size: 20),
    );
  }
}
