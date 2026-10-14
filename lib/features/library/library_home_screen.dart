import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/library_providers.dart';
import '../../data/models/entry.dart';
import '../../data/models/library.dart';
import '../../data/models/media_type.dart';
import '../../data/models/plan.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_icons.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/chips.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/entry_row.dart';
import '../../widgets/labels.dart';
import '../../widgets/page_header.dart';
import '../../widgets/section_heading.dart';
import '../../widgets/segmented_control.dart';
import '../music/music_tab.dart';
import '../music/artist_screen.dart';
import '../music/music_type_body.dart';
import '../plans/plan_progress.dart';
import '../plans/plan_screen.dart';
import '../settings/display_preferences.dart';
import '../settings/settings_screen.dart';
import '../sync/sync_banner.dart';
import 'library_skeleton.dart';
import '../settings/entry_view.dart';
import '../shell/app_shell.dart';
import '../shell/floating_nav_bar.dart';
import 'active_plan_card.dart';
import 'entry_list_body.dart';
import 'entry_sections.dart';
import 'filter_sheet.dart';
import 'home_return_provider.dart';
import 'home_type_provider.dart';
import 'library_filter.dart';
import 'library_filter_provider.dart';
import 'library_sort.dart';
import 'search_screen.dart';
import 'sort_sheet.dart';
import 'view_menu.dart';

/// The library home (A1). On All it shows the active plan and two rows per
/// type under tappable headings. With a type chip or heading picked it
/// becomes that type's list in place (A4, A20, A21): status segments, count,
/// sort and view; Music gets its artist, album and song tabs instead (A14).
/// Also shows filtered results (L5, L6) and the empty states of A10.
class LibraryHomeScreen extends ConsumerStatefulWidget {
  const LibraryHomeScreen({
    super.key,
    this.onOpenEntry,
    this.onOpenSettings,
    this.onOpenPlan,
    this.onAddEntry,
  });

  final void Function(Entry entry)? onOpenEntry;
  final VoidCallback? onOpenSettings;

  /// Opens the active plan. The shell switches to the Plans tab (DESIGN.md
  /// section 3); without a shell, e.g. in tests, it opens in place.
  final void Function(Plan plan)? onOpenPlan;

  /// Starts a new entry, for the picked [type] and with a [title] already
  /// typed (from search).
  final void Function({MediaType? type, String? title})? onAddEntry;

  @override
  ConsumerState<LibraryHomeScreen> createState() => _LibraryHomeScreenState();
}

class _LibraryHomeScreenState extends ConsumerState<LibraryHomeScreen> {
  /// The All list's position, so a return to the home can scroll it up.
  final _allScroll = ScrollController();

  @override
  void dispose() {
    _allScroll.dispose();
    super.dispose();
  }

  /// Library tapped in the pill while on the Library tab: the providers are
  /// already back on All, so only the scroll position is left. The list may
  /// be replaced this frame (a type view giving way to All), so wait for it.
  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_allScroll.hasClients) _allScroll.jumpTo(0);
    });
  }

  void _pickType(MediaType? type) {
    ref.read(homeTypeProvider.notifier).set(type);
    ref.read(homeStatusProvider.notifier).set(null);
    ref.read(homeMusicTabProvider.notifier).set(MusicTab.artists);
  }

  /// Opens the filter sheet. With no filter active it starts with what the
  /// home shows: the picked type and its status segment or music tab (A3).
  Future<void> _openFilters(Library library) async {
    final filter = ref.read(libraryFilterProvider);
    final result = await showFilterSheet(
      context,
      library: library,
      initial: filter.isActive
          ? filter
          : LibraryFilter.ofTypeView(
              ref.read(homeTypeProvider),
              status: ref.read(homeStatusProvider),
              kind: ref.read(homeMusicTabProvider).kind,
            ),
    );
    if (result != null) ref.read(libraryFilterProvider.notifier).set(result);
  }

  void _openSettings() =>
      (widget.onOpenSettings ?? () => openSettingsScreen(context))();

  Future<void> _openSearch() async {
    // The chip row is hidden while a filter is active, so search is scoped
    // to the picked type only when the chip can be seen.
    final type = ref.read(libraryFilterProvider).isActive
        ? null
        : ref.read(homeTypeProvider);
    // Full screen, above the floating navigation (A5 has none).
    final tag = await Navigator.of(context, rootNavigator: true).push<String>(
      MaterialPageRoute(
        builder: (searchContext) => SearchScreen(
          type: type,
          onOpenEntry: widget.onOpenEntry,
          onAddEntry: (title) {
            Navigator.pop(searchContext);
            widget.onAddEntry?.call(type: type, title: title);
          },
        ),
      ),
    );
    if (tag != null && mounted) {
      ref
          .read(libraryFilterProvider.notifier)
          .set(LibraryFilter(types: {?type}, tags: {tag}));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = LibraryColors.of(context);
    final filter = ref.watch(libraryFilterProvider);
    final prefs = ref.watch(displayPreferencesProvider);
    final type = ref.watch(homeTypeProvider);
    final libraryAsync = ref.watch(libraryProvider);
    final library = libraryAsync.value;
    ref.listen(homeReturnProvider, (_, _) => _scrollToTop());

    final Widget body;
    if (library == null && !libraryAsync.hasError) {
      // D7: the first load.
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: 'Library',
                actions: [SettingsButton(onPressed: _openSettings)],
              ),
              const SyncBannerCard(),
              const Expanded(child: LibrarySkeleton()),
            ],
          ),
        ),
      );
    } else if (library == null) {
      // The first download failed (offline, a bad token): say so, and let
      // a pull or the button try again.
      body = ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Could not load the library: ${libraryAsync.error}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Try again',
            kind: AppButtonKind.outline,
            onPressed: _refresh,
          ),
        ],
      );
    } else if (filter.isActive) {
      body = _filtered(library, filter, prefs, colors);
    } else if (type == null) {
      body = _allTypes(library, filter, colors);
    } else {
      body = _oneType(library, type, filter, prefs);
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: 'Library',
              actions: [SettingsButton(onPressed: _openSettings)],
            ),
            const SyncBannerCard(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: _SearchRow(
                hint: searchHint(filter.isActive ? null : type),
                filterCount: filter.count,
                onSearch: _openSearch,
                onFilters: library == null ? null : () => _openFilters(library),
              ),
            ),
            if (library != null && !filter.isActive)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    children: [
                      PillChip(
                        label: 'All',
                        selected: type == null,
                        onTap: () => _pickType(null),
                      ),
                      for (final t in MediaType.values) ...[
                        const SizedBox(width: 8),
                        PillChip(
                          label: t.label,
                          selected: type == t,
                          dotColor: colors.forType(t),
                          onTap: () => _pickType(t),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            Expanded(
              child: RefreshIndicator(onRefresh: _refresh, child: body),
            ),
          ],
        ),
      ),
    );
  }

  /// Pull-to-refresh: asks GitHub for changes. A library that failed to
  /// load is loaded again.
  Future<void> _refresh() async {
    if (ref.read(libraryProvider).hasError) ref.invalidate(libraryProvider);
    await ref.read(librarySyncProvider)?.checkForChanges();
  }

  /// All: the active plan, then two rows per type under a heading that
  /// opens the type.
  Widget _allTypes(
    Library library,
    LibraryFilter filter,
    LibraryColors colors,
  ) {
    final plan = activePlan(library);
    final sections = <Widget>[];
    for (final type in MediaType.values) {
      final entries = homeOrder(filter.apply(library.entriesOfType(type)));
      if (entries.isEmpty) continue;
      sections.add(
        SectionHeading(
          type.label,
          color: colors.forType(type),
          trailing: '${entries.length}',
          semanticsLabel: 'Show all ${type.label.toLowerCase()}',
          onTap: () => _pickType(type),
          padding: const EdgeInsets.only(top: 10),
        ),
      );
      for (final entry in entries.take(2)) {
        sections.add(
          EntryRow.forEntry(
            entry,
            onTap: () => widget.onOpenEntry?.call(entry),
          ),
        );
      }
    }

    return ListView(
      controller: _allScroll,
      padding: const EdgeInsets.only(bottom: AppShell.contentBottomPadding),
      children: [
        if (plan != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: ActivePlanCard(
              plan: plan,
              onTap: () => widget.onOpenPlan != null
                  ? widget.onOpenPlan!(plan)
                  : openPlanScreen(context, plan.id, tab: ShellTab.library),
            ),
          ),
        if (sections.isEmpty)
          const EmptyState(
            icon: AppIcons.library,
            title: 'Your library is empty',
            body: 'Entries you add will show up here.',
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: sections,
            ),
          ),
      ],
    );
  }

  /// One type picked: status segments, count, sort, view and the list in
  /// the remembered view. The segments stay put while the list scrolls.
  Widget _oneType(
    Library library,
    MediaType type,
    LibraryFilter filter,
    DisplayPreferences prefs,
  ) {
    final theme = Theme.of(context);
    final visible = filter.apply(library.entriesOfType(type));
    if (visible.isEmpty) {
      return EmptyState(
        icon: AppIcons.library,
        title: 'No ${type.label.toLowerCase()} yet',
        body: type == MediaType.music
            ? 'Albums and songs you add will show up here.'
            : '${type.label} you add will show up here.',
        actionLabel: 'Add ${type.singular.toLowerCase()}',
        onAction: () => widget.onAddEntry?.call(type: type),
      );
    }
    if (type == MediaType.music) {
      return MusicTypeBody(
        entries: visible,
        onOpenEntry: (entry) => widget.onOpenEntry?.call(entry),
        onOpenArtist: (artist) =>
            openArtistScreen(context, artist, onOpenEntry: widget.onOpenEntry),
      );
    }
    final status = ref.watch(homeStatusProvider);
    final shown = sortEntries(
      visible.where((e) => status == null || e.status == status),
      prefs.sortFor(type),
    );
    final view = prefs.viewFor(type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: StatusSegmentedControl(
            selected: status,
            type: type,
            includeAll: true,
            onChanged: ref.read(homeStatusProvider.notifier).set,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 10, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  countLabel(type, shown.length),
                  style: theme.textTheme.bodySmall!.copyWith(fontSize: 14),
                ),
              ),
              SortButton(
                current: prefs.sortFor(type),
                onChanged: (sort) => ref
                    .read(displayPreferencesProvider.notifier)
                    .setSort(type, sort),
              ),
              ViewMenuButton(
                current: view,
                onChanged: (v) => ref
                    .read(displayPreferencesProvider.notifier)
                    .setView(type, v),
              ),
            ],
          ),
        ),
        Expanded(
          child: shown.isEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                  child: Text(
                    'Nothing marked ${status!.lowerLabel} yet.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: LibraryColors.of(context).muted,
                    ),
                  ),
                )
              : EntryListBody(
                  // A new type starts at the top.
                  key: ValueKey(type),
                  entries: shown,
                  sort: prefs.sortFor(type),
                  view: view,
                  color: LibraryColors.of(context).forType(type),
                  onTap: (entry) => widget.onOpenEntry?.call(entry),
                ),
        ),
      ],
    );
  }

  /// Filtered results (L5, L6): removable chips and the count stay put, the
  /// rows scroll. Grouped by type; a long list gets a rail (L5, L6).
  Widget _filtered(
    Library library,
    LibraryFilter filter,
    DisplayPreferences prefs,
    LibraryColors colors,
  ) {
    final theme = Theme.of(context);
    final matching = sortEntries(
      filter.apply(library.entries),
      prefs.filteredSort,
    );
    final types = matching.map((e) => e.type).toSet();
    final byType = sectionEntriesByType(matching, colors.forType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final chip in filter.chips)
                RemovableChip(
                  label: chip.label,
                  onRemove: () =>
                      ref.read(libraryFilterProvider.notifier).remove(chip),
                ),
              // With no results the empty state's button clears the
              // filters, so the chip row has no link of its own (A10).
              if (matching.isNotEmpty)
                TextButton(
                  onPressed: () =>
                      ref.read(libraryFilterProvider.notifier).clear(),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    textStyle: theme.textTheme.labelMedium,
                  ),
                  child: const Text('Clear all'),
                ),
            ],
          ),
        ),
        if (matching.isEmpty)
          EmptyState(
            icon: AppIcons.filters,
            title: 'Nothing matches these filters',
            body: filter.noMatchesText,
            actionLabel: 'Clear filters',
            onAction: () => ref.read(libraryFilterProvider.notifier).clear(),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${matching.length} ${matching.length == 1 ? 'entry' : 'entries'}',
                    style: theme.textTheme.bodySmall!.copyWith(fontSize: 14),
                  ),
                ),
                SortButton(
                  current: prefs.filteredSort,
                  onChanged: (sort) => ref
                      .read(displayPreferencesProvider.notifier)
                      .setFilteredSort(sort),
                ),
              ],
            ),
          ),
          Expanded(
            child: EntryListBody(
              key: ValueKey(filter),
              entries: matching,
              sort: prefs.filteredSort,
              view: EntryView.text,
              // One type: sections follow the sort in that type's color
              // (L5). Several: one section per type with a dot rail (L6).
              color: types.length == 1
                  ? colors.forType(types.single)
                  : colors.muted,
              railSections: types.length == 1 ? null : byType,
              plainSections: byType,
              onTap: (entry) => widget.onOpenEntry?.call(entry),
            ),
          ),
        ],
      ],
    );
  }
}

/// The search field button and the filters button with its badge.
class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.hint,
    required this.filterCount,
    required this.onSearch,
    required this.onFilters,
  });

  final String hint;
  final int filterCount;
  final VoidCallback onSearch;
  final VoidCallback? onFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = LibraryColors.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: theme.colorScheme.outline),
    );
    return Row(
      children: [
        Expanded(
          child: Material(
            color: theme.colorScheme.surface,
            shape: shape,
            child: InkWell(
              onTap: onSearch,
              customBorder: shape,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    StrokeIcon(AppIcons.search, color: colors.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        hint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Badge(
          isLabelVisible: filterCount > 0,
          label: Text('$filterCount'),
          offset: const Offset(4, -4),
          child: Material(
            color: theme.colorScheme.surface,
            shape: shape,
            child: InkWell(
              onTap: onFilters,
              customBorder: shape,
              child: Tooltip(
                message: 'Filters',
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: Center(
                    child: StrokeIcon(
                      AppIcons.filters,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
