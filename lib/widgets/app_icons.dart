import 'package:flutter/material.dart';

/// A stroked line icon drawn on a 24 by 24 grid, matching the icons in the
/// design canvas (round caps and joins, no fill).
@immutable
class StrokeIconData {
  const StrokeIconData({
    this.polylines = const [],
    this.circles = const [],
    this.strokeWidth = 2,
  });

  final List<List<Offset>> polylines;
  final List<StrokeCircle> circles;

  /// In grid units; scaled with the icon.
  final double strokeWidth;
}

@immutable
class StrokeCircle {
  const StrokeCircle(this.center, this.radius);
  final Offset center;
  final double radius;
}

class AppIcons {
  AppIcons._();

  /// Three book spines.
  static const library = StrokeIconData(
    polylines: [
      [Offset(5, 4), Offset(5, 20)],
      [Offset(10, 4), Offset(10, 20)],
      [Offset(15, 5), Offset(19, 20)],
    ],
  );

  /// A checklist.
  static const plans = StrokeIconData(
    polylines: [
      [Offset(9, 6), Offset(20, 6)],
      [Offset(9, 12), Offset(20, 12)],
      [Offset(9, 18), Offset(20, 18)],
      [Offset(4, 6), Offset(5, 7), Offset(7, 5)],
      [Offset(4, 12), Offset(5, 13), Offset(7, 11)],
      [Offset(4, 18), Offset(5, 19), Offset(7, 17)],
    ],
  );

  static const plus = StrokeIconData(
    strokeWidth: 2.5,
    polylines: [
      [Offset(12, 5), Offset(12, 19)],
      [Offset(5, 12), Offset(19, 12)],
    ],
  );

  static const check = StrokeIconData(
    strokeWidth: 2.5,
    polylines: [
      [Offset(5, 12.5), Offset(9.5, 17), Offset(19, 7.5)],
    ],
  );

  static const settings = StrokeIconData(
    circles: [StrokeCircle(Offset(12, 12), 3.5)],
    polylines: [
      [Offset(12, 2.5), Offset(12, 5.5)],
      [Offset(12, 18.5), Offset(12, 21.5)],
      [Offset(2.5, 12), Offset(5.5, 12)],
      [Offset(18.5, 12), Offset(21.5, 12)],
      [Offset(5.3, 5.3), Offset(7.4, 7.4)],
      [Offset(16.6, 16.6), Offset(18.7, 18.7)],
      [Offset(5.3, 18.7), Offset(7.4, 16.6)],
      [Offset(16.6, 7.4), Offset(18.7, 5.3)],
    ],
  );

  static const back = StrokeIconData(
    polylines: [
      [Offset(15, 18), Offset(9, 12), Offset(15, 6)],
    ],
  );

  static const chevronDown = StrokeIconData(
    polylines: [
      [Offset(6, 9), Offset(12, 15), Offset(18, 9)],
    ],
  );

  static const search = StrokeIconData(
    circles: [StrokeCircle(Offset(11, 11), 7)],
    polylines: [
      [Offset(16.5, 16.5), Offset(21, 21)],
    ],
  );

  static const filters = StrokeIconData(
    polylines: [
      [Offset(4, 7), Offset(14, 7)],
      [Offset(18, 7), Offset(20, 7)],
      [Offset(4, 17), Offset(6, 17)],
      [Offset(10, 17), Offset(20, 17)],
      [Offset(16, 5), Offset(16, 9)],
      [Offset(8, 15), Offset(8, 19)],
    ],
  );
}

class StrokeIcon extends StatelessWidget {
  const StrokeIcon(
    this.data, {
    super.key,
    this.size = 20,
    this.color,
    this.semanticLabel,
  });

  final StrokeIconData data;
  final double size;

  /// Defaults to the surrounding icon color.
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? IconTheme.of(context).color ?? Colors.black;
    return Semantics(
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _StrokeIconPainter(data, resolved)),
      ),
    );
  }
}

class _StrokeIconPainter extends CustomPainter {
  const _StrokeIconPainter(this.data, this.color);

  final StrokeIconData data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = data.strokeWidth * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final line in data.polylines) {
      final path = Path()..moveTo(line.first.dx * scale, line.first.dy * scale);
      for (final point in line.skip(1)) {
        path.lineTo(point.dx * scale, point.dy * scale);
      }
      canvas.drawPath(path, paint);
    }
    for (final circle in data.circles) {
      canvas.drawCircle(circle.center * scale, circle.radius * scale, paint);
    }
  }

  @override
  bool shouldRepaint(_StrokeIconPainter old) =>
      old.data != data || old.color != color;
}
