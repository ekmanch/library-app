import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entry/entry_details_sheet.dart';
import '../entry/new_entry_screen.dart';
import '../plans/plan_form_screen.dart';
import '../library/home_return_provider.dart';
import '../library/home_type_provider.dart';
import '../library/library_home_screen.dart';
import '../settings/display_preferences.dart';
import '../../theme/app_theme.dart';
import '../../data/models/plan.dart';
import '../plans/plan_screen.dart';
import '../plans/plan_progress.dart';
import '../plans/plans_screen.dart';
import '../sync/sync_scheduler.dart';
import '../../data/images/artwork_providers.dart';
import '../../data/library_providers.dart';
import 'fab_action.dart';
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

  /// Navigation height (60: 48 dp items in a 6 dp padded pill) plus its
  /// 20 px margin and 20 px of air.
  static const contentBottomPadding = 100.0;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  ShellTab _tab = ShellTab.library;
  final _keys = {
    ShellTab.library: GlobalKey<NavigatorState>(),
    ShellTab.plans: GlobalKey<NavigatorState>(),
  };

  late final SyncScheduler _scheduler;

  NavigatorState? get _current => _keys[_tab]!.currentState;

  @override
  void initState() {
    super.initState();
    _scheduler = SyncScheduler(sync: () => ref.read(librarySyncProvider))
      ..start();
    // Covers and photos of entries that are gone get cleaned up once per
    // session, a little after the library loads.
    ref.listenManual(artworkPrunerProvider, (_, _) {});
    // A plan whose first date has come turns its Started switch on, so the
    // switch always shows the real state (S9). Plans never stop on their
    // own.
    ref.listenManual(libraryProvider, (_, next) {
      final library = next.value;
      if (library == null) return;
      final repository = ref.read(libraryRepositoryProvider);
      for (final start in dueStarts(library)) {
        repository.apply(start);
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _scheduler.dispose();
    super.dispose();
  }

  /// The current tab's item returns to its overview: Plans to S5, Library
  /// to the home on All, scrolled to the top (A1).
  void _select(ShellTab tab) {
    if (tab == _tab) {
      _current?.popUntil((route) => route.isFirst);
      if (tab == ShellTab.library) {
        ref.read(homeReturnProvider.notifier).goHome();
      }
      return;
    }
    setState(() => _tab = tab);
    _scheduler.onTabSwitch();
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

  /// The active plan card on the home (A1) opens the plan in the Plans
  /// tab, so the pill says where you are and back lands on the overview.
  void _openPlan(Plan plan) {
    setState(() => _tab = ShellTab.plans);
    final plans = _keys[ShellTab.plans]!.currentState!;
    plans.popUntil((route) => route.isFirst);
    openPlanScreen(plans.context, plan.id, tab: ShellTab.plans);
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
        if (widget.onAddPlan case final onAdd?) {
          onAdd(context);
        } else {
          openNewPlanForm(context);
        }
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
                        onOpenPlan: _openPlan,
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
                  Builder(
                    builder: (context) {
                      // A screen inside the tab may claim the button (S1, S4).
                      final fab = ref.watch(fabActionProvider);
                      final claimed = fab != null && fab.tab == _tab;
                      final button = AddButton(
                        label: claimed
                            ? fab.label
                            : _tab == ShellTab.library
                            ? newEntryLabel(ref.watch(homeTypeProvider))
                            : 'New plan',
                        onPressed: claimed ? fab.onPressed : _add,
                      );
                      final seasonal = claimed ? fab.accent : null;
                      if (seasonal == null) return button;
                      // Inside a themed plan the button wears its accent.
                      final theme = Theme.of(context);
                      return Theme(
                        data: buildTheme(
                          brightness: theme.brightness,
                          accent: ref.watch(displayPreferencesProvider).accent,
                          seasonal: seasonal,
                        ),
                        child: button,
                      );
                    },
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
