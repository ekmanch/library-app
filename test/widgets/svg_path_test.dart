import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/features/plans/seasonal_art_data.dart';
import 'package:library_app/widgets/svg_path.dart';

void main() {
  test('absolute and relative commands build the expected bounds', () {
    final square = parseSvgPath('M10 10h20v20h-20z');
    expect(square.getBounds(), const Rect.fromLTWH(10, 10, 20, 20));
    final curve = parseSvgPath(
      'M0 0C0 10 10 10 10 0S20 -10 20 0Q25 5 30 0T40 0',
    );
    expect(curve.getBounds().left, 0);
    expect(curve.getBounds().right, 40);
    final arc = parseSvgPath('M30 98V58a12 12 0 0 1 24 0v40z');
    final b = arc.getBounds();
    expect(b.left, closeTo(30, 0.01));
    expect(b.right, closeTo(54, 0.01));
    expect(b.top, closeTo(46, 0.01));
  });

  test('implicit line pairs after M, and compact number runs', () {
    final p = parseSvgPath('M1 1 5 1 5 5z');
    expect(p.getBounds(), const Rect.fromLTWH(1, 1, 4, 4));
    final q = parseSvgPath('M0 0l.5.5-1-1');
    expect(q.getBounds().width, closeTo(1.0, 0.001));
  });

  test('every shape in the seasonal artwork parses', () {
    for (final art in [
      halloweenStrip,
      halloweenIcon,
      halloweenMarker,
      halloweenWeb,
      christmasStrip,
      christmasIcon,
      christmasMarker,
    ]) {
      for (final shape in art.shapes) {
        if (shape.path != null) {
          expect(parseSvgPath(shape.path!).computeMetrics(), isNotEmpty);
        }
      }
    }
    expect(halloweenStrip.width, 390);
    expect(halloweenStrip.height, 88);
  });

  test('an unknown command is an error', () {
    expect(() => parseSvgPath('M0 0X5'), throwsFormatException);
  });
}
