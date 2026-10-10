import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/entry.dart';
import '../../data/models/media_type.dart';
import '../../theme/app_theme.dart';
import '../../widgets/entry_row.dart';
import '../settings/entry_view.dart';
import '../shell/app_shell.dart';
import 'cover_placeholder.dart';
import 'entry_list_views.dart';
import 'entry_sections.dart';
import 'library_sort.dart';

/// The scrolling part of a type's list. Short lists are plain. A list at
/// least three screens tall with two sections or more gets section headers
/// and a jump rail on the right (A23 to A25), or, in the grid, a draggable
/// thumb with a label bubble (A26).
class EntryListBody extends StatefulWidget {
  const EntryListBody({
    super.key,
    required this.entries,
    required this.sort,
    required this.view,
    required this.color,
    required this.onTap,
    this.today,
    this.bottomPadding = AppShell.contentBottomPadding,
  });

  /// Already sorted by [sort].
  final List<Entry> entries;
  final LibrarySort sort;
  final EntryView view;

  /// The type color, for the section headers.
  final Color color;
  final void Function(Entry entry) onTap;
  final DateTime? today;

  /// Space kept clear of the floating navigation; the rail ends above it.
  final double bottomPadding;

  static const thumbKey = Key('fast-scroll-thumb');
  static const railKey = Key('jump-rail');
  static const thumbHeight = 44.0;

  @override
  State<EntryListBody> createState() => _EntryListBodyState();
}

class _EntryListBodyState extends State<EntryListBody> {
  final _controller = ScrollController();

  /// Index of the section the rail highlights or the bubble names.
  int _current = 0;

  /// After a rail jump the highlight stays put until the user scrolls.
  bool _pinned = false;
  bool _dragging = false;
  bool _thumbShown = false;
  Timer? _hideThumb;
  List<double> _sectionTops = const [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _hideThumb?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    var next = _current;
    if (!_pinned) {
      final offset = _controller.offset + 1;
      for (var i = 0; i < _sectionTops.length; i++) {
        if (_sectionTops[i] <= offset) next = i;
      }
    }
    final thumbMoves = _thumbShown || _dragging;
    if (next != _current || thumbMoves) setState(() => _current = next);
  }

  bool _onNotification(ScrollNotification n) {
    if (n is ScrollStartNotification && n.dragDetails != null) {
      _pinned = false;
    }
    if (n is ScrollUpdateNotification && n.dragDetails != null) {
      _showThumbBriefly();
    }
    return false;
  }

  void _showThumbBriefly() {
    _hideThumb?.cancel();
    if (!_thumbShown) setState(() => _thumbShown = true);
    if (!_dragging) {
      _hideThumb = Timer(const Duration(seconds: 1), () {
        if (mounted) setState(() => _thumbShown = false);
      });
    }
  }

  void _jumpToSection(int i) {
    if (!_controller.hasClients) return;
    final max = _controller.position.maxScrollExtent;
    _pinned = true;
    setState(() => _current = i);
    _controller.jumpTo(math.min(_sectionTops[i], max));
  }

  @override
  void didUpdateWidget(EntryListBody old) {
    super.didUpdateWidget(old);
    // A new order or view lays the sections out afresh; follow the scroll
    // position again instead of a jump made in the old layout.
    if (old.sort != widget.sort ||
        old.view != widget.view ||
        old.entries != widget.entries) {
      _pinned = false;
    }
  }

  void _dragThumbTo(double localY, double trackHeight) {
    if (!_controller.hasClients) return;
    _pinned = false;
    final travel = trackHeight - EntryListBody.thumbHeight;
    final ratio = ((localY - EntryListBody.thumbHeight / 2) / travel).clamp(
      0.0,
      1.0,
    );
    _controller.jumpTo(ratio * _controller.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth - 40;
        final sections = sectionEntries(
          widget.entries,
          widget.sort,
          today: widget.today,
        );
        final isGrid = widget.view == EntryView.grid;
        final count = widget.entries.length;
        final rowExtent = isGrid
            ? EntryListMetrics.gridRowExtent(
                width,
                count == 0 ? MediaType.movies : widget.entries.first.type,
              )
            : EntryListMetrics.rowHeight(widget.view);
        final contentHeight = isGrid
            ? EntryListMetrics.gridTopPadding +
                  (count / EntryListMetrics.gridColumns).ceil() * rowExtent
            : count * rowExtent +
                  sections.length * EntryListMetrics.headerHeight;
        final rail = showJumpRail(
          sectionCount: sections.length,
          contentHeight: contentHeight,
          viewportHeight: constraints.maxHeight,
        );

        if (!rail) {
          _sectionTops = const [];
          return _scrollView(
            rightPadding: 20,
            slivers: entryListSlivers(
              entries: widget.entries,
              view: widget.view,
              onTap: widget.onTap,
              today: widget.today,
            ),
          );
        }

        _sectionTops = _tops(sections, isGrid, rowExtent);
        final current = sections[_current.clamp(0, sections.length - 1)];
        if (isGrid) {
          return Stack(
            children: [
              _scrollView(
                rightPadding: 20,
                slivers: entryListSlivers(
                  entries: widget.entries,
                  view: widget.view,
                  onTap: widget.onTap,
                  today: widget.today,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                bottom: widget.bottomPadding,
                width: 44,
                child: _thumbZone(current.bubbleLabel),
              ),
            ],
          );
        }
        return Stack(
          children: [
            _scrollView(
              rightPadding: 48,
              slivers: [
                for (final section in sections) ...[
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      section.headerText,
                      color: widget.color,
                    ),
                  ),
                  SliverFixedExtentList.builder(
                    itemExtent: rowExtent,
                    itemCount: section.entries.length,
                    itemBuilder: (context, i) {
                      final entry = section.entries[i];
                      return EntryRow.forEntry(
                        entry,
                        today: widget.today,
                        onTap: () => widget.onTap(entry),
                        leading: widget.view == EntryView.listWithPhotos
                            ? CoverPlaceholder(entry: entry, width: 40)
                            : null,
                      );
                    },
                  ),
                ],
              ],
            ),
            Positioned(
              top: 0,
              right: 2,
              bottom: widget.bottomPadding,
              width: 36,
              child: _rail(sections),
            ),
          ],
        );
      },
    );
  }

  List<double> _tops(
    List<EntrySection> sections,
    bool isGrid,
    double rowExtent,
  ) {
    final tops = <double>[];
    var y = 0.0;
    var index = 0;
    for (final section in sections) {
      if (isGrid) {
        final row = index ~/ EntryListMetrics.gridColumns;
        tops.add(EntryListMetrics.gridTopPadding + row * rowExtent);
        index += section.entries.length;
      } else {
        tops.add(y);
        y += EntryListMetrics.headerHeight + section.entries.length * rowExtent;
      }
    }
    return tops;
  }

  Widget _scrollView({
    required double rightPadding,
    required List<Widget> slivers,
  }) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      // No platform scrollbar: the rail or the thumb takes its place, and on
      // the phone there is none anyway.
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: CustomScrollView(
          controller: _controller,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                rightPadding,
                widget.bottomPadding,
              ),
              sliver: SliverMainAxisGroup(slivers: slivers),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rail(List<EntrySection> sections) {
    final theme = Theme.of(context);
    final colors = LibraryColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        void jump(Offset local) {
          final i = (local.dy / height * sections.length).floor();
          _jumpToSection(i.clamp(0, sections.length - 1));
        }

        final cell = height / sections.length;
        final pillHeight = math.min(22.0, cell);
        return Semantics(
          label: 'Jump to section',
          child: GestureDetector(
            key: EntryListBody.railKey,
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => jump(d.localPosition),
            onVerticalDragStart: (d) => jump(d.localPosition),
            onVerticalDragUpdate: (d) => jump(d.localPosition),
            child: Column(
              children: [
                for (var i = 0; i < sections.length; i++)
                  Expanded(
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 28),
                        height: pillHeight,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i == _current
                              ? colors.selectedFill
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          sections[i].railLabel,
                          maxLines: 1,
                          softWrap: false,
                          style: theme.textTheme.labelSmall!.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                            color: i == _current
                                ? theme.colorScheme.onSurface
                                : colors.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _thumbZone(String label) {
    final theme = Theme.of(context);
    final colors = LibraryColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackHeight = constraints.maxHeight;
        final max = _controller.hasClients
            ? _controller.position.maxScrollExtent
            : 0.0;
        final ratio = max > 0
            ? (_controller.offset / max).clamp(0.0, 1.0)
            : 0.0;
        final thumbTop = ratio * (trackHeight - EntryListBody.thumbHeight);
        final visible = _dragging || _thumbShown;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (d) {
            _hideThumb?.cancel();
            setState(() {
              _dragging = true;
              _thumbShown = true;
            });
            _dragThumbTo(d.localPosition.dy, trackHeight);
          },
          onVerticalDragUpdate: (d) =>
              _dragThumbTo(d.localPosition.dy, trackHeight),
          onVerticalDragEnd: (_) => _endDrag(),
          onVerticalDragCancel: _endDrag,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: thumbTop,
                right: 8,
                child: AnimatedOpacity(
                  opacity: visible ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    key: EntryListBody.thumbKey,
                    width: 5,
                    height: EntryListBody.thumbHeight,
                    decoration: BoxDecoration(
                      color: _dragging
                          ? theme.colorScheme.onSurface
                          : colors.muted,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              // The bubble names the section at the top of the screen
              // whenever the thumb is out, not only while dragging.
              Positioned(
                top: thumbTop + EntryListBody.thumbHeight / 2 - 18,
                right: 30,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: visible ? 1 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.surfaceHigh,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colors.navBorder),
                        boxShadow: colors.navShadow,
                      ),
                      child: Text(
                        label,
                        softWrap: false,
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _endDrag() {
    if (!_dragging) return;
    setState(() => _dragging = false);
    _showThumbBriefly();
  }
}

/// "2020s", "OCTOBER 2026", "A": 40 px tall, text at the bottom, in the type
/// color. The caller decides the case.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: EntryListMetrics.headerHeight,
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            text,
            style: theme.textTheme.labelSmall!.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.78,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
