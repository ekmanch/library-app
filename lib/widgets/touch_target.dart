import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Gives a small control a touch area of at least [minSize] without
/// changing its size or the layout around it: a 40 dp chip stays 40 dp on
/// screen but answers taps, and reports a semantics rect, 48 dp across.
///
/// The extra area reaches into the space around the control, so it only
/// works where the parent hit-tests its children past their bounds, as
/// Row, Wrap and Column do.
class TouchTarget extends SingleChildRenderObjectWidget {
  const TouchTarget({super.key, this.minSize = 48, required super.child});

  final double minSize;

  @override
  RenderTouchTarget createRenderObject(BuildContext context) =>
      RenderTouchTarget(minSize);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderTouchTarget renderObject,
  ) => renderObject.minSize = minSize;
}

class RenderTouchTarget extends RenderProxyBox {
  RenderTouchTarget(this._minSize);

  double _minSize;
  double get minSize => _minSize;
  set minSize(double value) {
    if (value == _minSize) return;
    _minSize = value;
    markNeedsSemanticsUpdate();
  }

  Rect get _area {
    final dx = math.max(0.0, (minSize - size.width) / 2);
    final dy = math.max(0.0, (minSize - size.height) / 2);
    return Rect.fromLTRB(-dx, -dy, size.width + dx, size.height + dy);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!_area.contains(position)) return false;
    // A tap in the extra margin counts as a tap on the nearest point of
    // the control.
    final inside = Offset(
      position.dx.clamp(0.0, math.max(0.0, size.width - 0.01)),
      position.dy.clamp(0.0, math.max(0.0, size.height - 0.01)),
    );
    if (hitTestChildren(result, position: inside)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  @override
  Rect get semanticBounds => _area;

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    // Own the control's semantics node, so its rect is the touch area.
    config
      ..isSemanticBoundary = true
      ..isMergingSemanticsOfDescendants = true;
  }
}
