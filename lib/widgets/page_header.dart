import 'package:flutter/material.dart';

import 'app_icons.dart';

/// Title row at the top of a screen: 34 px on top-level screens, 28 px with
/// a back arrow. [actions] sit at the trailing end, typically a settings
/// button. No tinted header bars.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.onBack,
    this.leading,
    this.actions = const [],
  });

  final String title;

  /// When set, a back arrow is shown and the title is one step smaller.
  final VoidCallback? onBack;

  /// Sits between the back arrow and the title, e.g. a type color dot.
  final Widget? leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasBack = onBack != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
      child: Row(
        children: [
          if (hasBack)
            Transform.translate(
              offset: const Offset(-12, 0),
              child: IconButton(
                onPressed: onBack,
                tooltip: 'Back',
                color: Theme.of(context).colorScheme.onSurface,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 44,
                  height: 44,
                ),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const StrokeIcon(AppIcons.back, size: 22),
              ),
            ),
          if (hasBack) const SizedBox(width: 4),
          if (leading != null) ...[leading!, const SizedBox(width: 6)],
          Expanded(
            child: Text(
              title,
              style: hasBack
                  ? textTheme.headlineMedium
                  : textTheme.headlineLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// The 44 px gear button that opens Settings from top-level screens.
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: 'Settings',
      icon: const StrokeIcon(AppIcons.settings, size: 22),
    );
  }
}
