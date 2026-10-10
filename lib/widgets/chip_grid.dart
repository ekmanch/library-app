import 'package:flutter/material.dart';

/// Equal-width chips in rows, like the CSS grids in A2 and A8. A last row
/// with fewer chips keeps the column widths.
class ChipGrid extends StatelessWidget {
  const ChipGrid({
    super.key,
    required this.columns,
    required this.children,
    this.gap = 6,
  });

  final int columns;
  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var start = 0; start < children.length; start += columns) {
      final row = children.sublist(
        start,
        (start + columns).clamp(0, children.length),
      );
      rows.add(
        Row(
          children: [
            for (var i = 0; i < columns; i++) ...[
              if (i > 0) SizedBox(width: gap),
              Expanded(child: i < row.length ? row[i] : const SizedBox()),
            ],
          ],
        ),
      );
    }
    return Column(
      children: [
        for (final (i, row) in rows.indexed) ...[
          if (i > 0) SizedBox(height: gap),
          row,
        ],
      ],
    );
  }
}
