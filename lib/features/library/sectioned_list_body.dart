import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../shell/app_shell.dart';
import 'entry_sections.dart';

/// A run of consecutive items in a sorted list that share a heading: a
/// decade, a month added, a first letter (L1 to L6), or a type.
class ListSection<T> {
  const ListSection({
    required this.label,
    required this.railLabel,
    required this.bubbleLabel,
    required this.items,
    this.uppercaseHeader = true,
    this.color,
    this.dotColor,
  });

  /// The header above the rows: "2020s", "October 2026", "A".
  final String label;

  /// Headers are written in capitals like other section labels, except
  /// decades: "1990S" reads wrong, so they stay "1990s".
  final bool uppercaseHeader;

  /// The header as shown.
  String get headerText => uppercaseHeader ? label.toUpperCase() : label;

  /// Header color; the list's color when null.
  final Color? color;

  /// When set, the rail shows a dot of this color instead of [railLabel]
  /// (L6: one dot per type in filtered results).
  final Color? dotColor;

  /// The short form on the rail: "20s", "Oct", "A".
  final String railLabel;

  /// The grid's drag label: "2020s", "Oct 2026", "A".
  final String bubbleLabel;
  final List<T> items;
}

/// The scrolling part of a list of [T]. Short lists are plain. A list at
/// least three screens tall with two sections or more gets section headers
/// and a jump rail on the right (L1 to L3), or, in the grid, a draggable
/// thumb with a label bubble (L4). Rows have a fixed height so section
/// offsets can be computed without measuring.
class SectionedListBody<T> extends StatefulWidget {
  const SectionedListBody({
    super.key,
    required this.itemCount,
    required this.sections,
    this.plainSections,
    required this.grid,
    required this.rowExtent,
    required this.gridRowExtent,
    this.gridTopPadding = 0,
    this.gridColumns = 3,
    required this.rowBuilder,
    required this.flatSlivers,
    required this.color,
    this.bottomPadding = AppShell.contentBottomPadding,
    this.layoutKey,
  });

  final int itemCount;

  /// The sections behind the rail, in list order.
  final List<ListSection<T>> sections;

  /// Sections to show with headers when the list is too short for a rail
  /// (L6 groups filtered results by type). Null means a flat list.
  final List<ListSection<T>>? plainSections;

  /// True for the grid: no headers, a thumb instead of a rail.
  final bool grid;

  /// Row height in the text and list views.
  final double rowExtent;

  /// Height of one grid row, tile plus spacing, for a list of that width.
  final double Function(double width) gridRowExtent;
  final double gridTopPadding;
  final int gridColumns;

  /// A row for one item in the sectioned text or list view.
  final Widget Function(BuildContext context, T item) rowBuilder;

  /// The whole list in the chosen view, used when there are no headers:
  /// short lists, and the grid.
  final List<Widget> flatSlivers;

  /// The color of the section headers.
  final Color color;

  /// Space kept clear of the floating navigation; the rail ends above it.
  final double bottomPadding;

  /// When this changes, the sections were laid out afresh and the rail
  /// follows the scroll position again instead of the last jump.
  final Object? layoutKey;

  static const thumbKey = Key('fast-scroll-thumb');
  static const railKey = Key('jump-rail');
  static const thumbHeight = 44.0;
  static const headerHeight = 40.0;

  @override
  State<SectionedListBody<T>> createState() => _SectionedListBodyState<T>();
}

class _SectionedListBodyState<T> extends State<SectionedListBody<T>> {
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
  void didUpdateWidget(SectionedListBody<T> old) {
    super.didUpdateWidget(old);
    if (old.layoutKey != widget.layoutKey) _pinned = false;
  }

  void _dragThumbTo(double localY, double trackHeight) {
    if (!_controller.hasClients) return;
    _pinned = false;
    final travel = trackHeight - SectionedListBody.thumbHeight;
    final ratio = ((localY - SectionedListBody.thumbHeight / 2) / travel).clamp(
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
        final sections = widget.sections;
        final isGrid = widget.grid;
        final count = widget.itemCount;
        final rowExtent = isGrid
            ? widget.gridRowExtent(width)
            : widget.rowExtent;
        final contentHeight = isGrid
            ? widget.gridTopPadding +
                  (count / widget.gridColumns).ceil() * rowExtent
            : count * rowExtent +
                  sections.length * SectionedListBody.headerHeight;
        final rail = showJumpRail(
          sectionCount: sections.length,
          contentHeight: contentHeight,
          viewportHeight: constraints.maxHeight,
        );

        if (!rail) {
          _sectionTops = const [];
          final plain = widget.plainSections;
          return _scrollView(
            rightPadding: 20,
            slivers: plain == null || isGrid
                ? widget.flatSlivers
                : _sectionedSlivers(plain, rowExtent),
          );
        }

        _sectionTops = _tops(sections, isGrid, rowExtent);
        final current = sections[_current.clamp(0, sections.length - 1)];
        if (isGrid) {
          return Stack(
            children: [
              _scrollView(rightPadding: 20, slivers: widget.flatSlivers),
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
              slivers: _sectionedSlivers(sections, rowExtent),
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

  /// A header and fixed-height rows per section.
  List<Widget> _sectionedSlivers(
    List<ListSection<T>> sections,
    double rowExtent,
  ) {
    return [
      for (final section in sections) ...[
        SliverToBoxAdapter(
          child: _SectionHeader(
            section.headerText,
            color: section.color ?? widget.color,
          ),
        ),
        SliverFixedExtentList.builder(
          itemExtent: rowExtent,
          itemCount: section.items.length,
          itemBuilder: (context, i) =>
              widget.rowBuilder(context, section.items[i]),
        ),
      ],
    ];
  }

  List<double> _tops(
    List<ListSection<T>> sections,
    bool isGrid,
    double rowExtent,
  ) {
    final tops = <double>[];
    var y = 0.0;
    var index = 0;
    for (final section in sections) {
      if (isGrid) {
        final row = index ~/ widget.gridColumns;
        tops.add(widget.gridTopPadding + row * rowExtent);
        index += section.items.length;
      } else {
        tops.add(y);
        y += SectionedListBody.headerHeight + section.items.length * rowExtent;
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

  Widget _rail(List<ListSection<T>> sections) {
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
            key: SectionedListBody.railKey,
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => jump(d.localPosition),
            onVerticalDragStart: (d) => jump(d.localPosition),
            onVerticalDragUpdate: (d) => jump(d.localPosition),
            child: Column(
              children: [
                for (var i = 0; i < sections.length; i++)
                  Expanded(
                    child: Semantics(
                      label: sections[i].label,
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
                          child: _railCell(sections[i], i == _current),
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

  /// A short label, or a type dot that grows a little when current (L6).
  Widget _railCell(ListSection<T> section, bool current) {
    final theme = Theme.of(context);
    final colors = LibraryColors.of(context);
    final dot = section.dotColor;
    if (dot != null) {
      final size = current ? 12.0 : 10.0;
      return Container(
        key: ValueKey('rail-dot-${section.label}'),
        width: size,
        height: size,
        decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
      );
    }
    return Text(
      section.railLabel,
      maxLines: 1,
      softWrap: false,
      style: theme.textTheme.labelSmall!.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: current ? theme.colorScheme.onSurface : colors.muted,
      ),
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
        final thumbTop = ratio * (trackHeight - SectionedListBody.thumbHeight);
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
                    key: SectionedListBody.thumbKey,
                    width: 5,
                    height: SectionedListBody.thumbHeight,
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
                top: thumbTop + SectionedListBody.thumbHeight / 2 - 18,
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

/// "2020s", "OCTOBER 2026", "A": 40 px tall, text at the bottom, in the
/// list's color. The caller decides the case.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: SectionedListBody.headerHeight,
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
