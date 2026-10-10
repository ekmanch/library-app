import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entry/entry_details_sheet.dart';
import '../entry/new_entry_screen.dart';
import '../library/home_type_provider.dart';
import '../library/library_home_screen.dart';
import '../plans/plans_screen.dart';
import 'floating_nav_bar.dart';

/// The app frame: one navigator per tab, the floating pill navigation and
/// the round "+" button laid over the content.
///
/// Screens inside a tab keep the pill visible (A4), so lists add
/// [contentBottomPadding] at the end to scroll clear of it.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({
    super.key,
    this.libraryHome,
    this.plansHome,
    this.onAddEntry,
    this.onAddPlan,
  });

  /// Override the tab roots, mainly for tests.
  final Widget? libraryHome;
  final Widget? plansHome;

  /// Called with the Library tab's navigator context when "+" is pressed.
  /// By default "+" starts the new-entry flow (A13).
  final void Function(BuildContext context)? onAddEntry;
  final void Function(BuildContext context)? onAddPlan;

  /// Navigation height (56) plus its 20 px margins.
  static const contentBottomPadding = 96.0;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  ShellTab _tab = ShellTab.library;
  final _keys = {
    ShellTab.library: GlobalKey<NavigatorState>(),
    ShellTab.plans: GlobalKey<NavigatorState>(),
  };

  NavigatorState? get _current => _keys[_tab]!.currentState;

  void _select(ShellTab tab) {
    if (tab == _tab) {
      _current?.popUntil((route) => route.isFirst);
      return;
    }
    setState(() => _tab = tab);
  }

  /// Android back: pop inside the tab, then return to Library, then leave.
  void _onPop(bool didPop, Object? result) {
    if (didPop) return;
    final navigator = _current;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
    } else if (_tab != ShellTab.library) {
      setState(() => _tab = ShellTab.library);
    } else {
      SystemNavigator.pop();
    }
  }

  void _add() {
    final context = _current?.context ?? this.context;
    switch (_tab) {
      case ShellTab.library:
        if (widget.onAddEntry case final onAdd?) {
          onAdd(context);
        } else {
          openNewEntryScreen(context, type: ref.read(homeTypeProvider));
        }
      case ShellTab.plans:
        widget.onAddPlan?.call(context);
    }
  }

  Widget _tabNavigator(ShellTab tab, Widget home) {
    return Navigator(
      key: _keys[tab],
      onGenerateRoute: (settings) =>
          MaterialPageRoute(builder: (_) => home, settings: settings),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPop,
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(
              index: _tab.index,
              children: [
                _tabNavigator(
                  ShellTab.library,
                  widget.libraryHome ??
                      LibraryHomeScreen(
                        onOpenEntry: (entry) =>
                            showEntryDetailsSheet(context, entry.id),
                        onAddEntry: ({type, title}) => openNewEntryScreen(
                          context,
                          type: type,
                          title: title,
                        ),
                      ),
                ),
                _tabNavigator(
                  ShellTab.plans,
                  widget.plansHome ?? const PlansScreen(),
                ),
              ],
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20 + MediaQuery.paddingOf(context).bottom,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FloatingNavBar(selected: _tab, onSelect: _select),
                  AddButton(
                    label: _tab == ShellTab.library
                        ? newEntryLabel(ref.watch(homeTypeProvider))
                        : 'New plan',
                    onPressed: _add,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
