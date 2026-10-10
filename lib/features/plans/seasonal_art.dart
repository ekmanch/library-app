import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'svg_path.dart';

/// One shape of a [SeasonalArt] picture, in the picture's own units.
@immutable
class ArtShape {
  const ArtShape.circle(
    this.a,
    this.b,
    this.c, {
    this.fill,
    this.stroke,
    this.strokeWidth = 1,
    this.transform,
  }) : kind = ArtKind.circle,
       d = 0,
       e = 0,
       path = null;

  const ArtShape.ellipse(
    this.a,
    this.b,
    this.c,
    this.d, {
    this.fill,
    this.stroke,
    this.strokeWidth = 1,
    this.transform,
  }) : kind = ArtKind.ellipse,
       e = 0,
       path = null;

  const ArtShape.rect(
    this.a,
    this.b,
    this.c,
    this.d,
    this.e, {
    this.fill,
    this.stroke,
    this.strokeWidth = 1,
    this.transform,
  }) : kind = ArtKind.rect,
       path = null;

  const ArtShape.path(
    String this.path, {
    this.fill,
    this.stroke,
    this.strokeWidth = 1,
    this.transform,
  }) : kind = ArtKind.path,
       a = 0,
       b = 0,
       c = 0,
       d = 0,
       e = 0;

  final ArtKind kind;

  /// Circle: cx, cy, r. Ellipse: cx, cy, rx, ry. Rect: x, y, w, h, rx.
  final double a, b, c, d, e;
  final String? path;
  final Color? fill;
  final Color? stroke;
  final double strokeWidth;

  /// An SVG affine matrix [a, b, c, d, e, f], or null for none.
  final List<double>? transform;
}

/// What an [ArtShape] draws.
enum ArtKind { circle, ellipse, rect, path }

/// A small picture made of [ArtShape]s, drawn from the canvas's SVG.
@immutable
class SeasonalArt {
  const SeasonalArt({
    required this.width,
    required this.height,
    required this.shapes,
  });

  final double width;
  final double height;
  final List<ArtShape> shapes;
}

/// Draws a [SeasonalArt] scaled to fit its box, keeping the aspect ratio
/// and anchored at the top left (the strips are as wide as the screen).
class SeasonalArtView extends StatelessWidget {
  const SeasonalArtView(
    this.art, {
    super.key,
    this.width,
    this.height,
    this.opacity = 1,
  });

  final SeasonalArt art;
  final double? width;
  final double? height;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: height ?? (width == null ? art.height : null),
        child: CustomPaint(
          painter: _SeasonalArtPainter(art, opacity),
          size: Size(width ?? art.width, height ?? art.height),
        ),
      ),
    );
  }
}

class _SeasonalArtPainter extends CustomPainter {
  _SeasonalArtPainter(this.art, this.opacity);

  final SeasonalArt art;
  final double opacity;

  static final _pathCache = <String, Path>{};

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / art.width;
    canvas.save();
    if (opacity < 1) {
      canvas.saveLayer(
        Offset.zero & size,
        Paint()..color = Color.fromRGBO(0, 0, 0, opacity),
      );
    }
    canvas.scale(scale);
    for (final shape in art.shapes) {
      canvas.save();
      final t = shape.transform;
      if (t != null) {
        canvas.transform(
          Float64List.fromList([
            t[0], t[1], 0, 0, //
            t[2], t[3], 0, 0, //
            0, 0, 1, 0, //
            t[4], t[5], 0, 1,
          ]),
        );
      }
      final path = switch (shape.kind) {
        ArtKind.circle =>
          Path()..addOval(
            Rect.fromCircle(center: Offset(shape.a, shape.b), radius: shape.c),
          ),
        ArtKind.ellipse =>
          Path()..addOval(
            Rect.fromCenter(
              center: Offset(shape.a, shape.b),
              width: shape.c * 2,
              height: shape.d * 2,
            ),
          ),
        ArtKind.rect =>
          Path()..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(shape.a, shape.b, shape.c, shape.d),
              Radius.circular(shape.e),
            ),
          ),
        ArtKind.path => _pathCache.putIfAbsent(
          shape.path!,
          () => parseSvgPath(shape.path!),
        ),
      };
      if (shape.fill != null) {
        canvas.drawPath(path, Paint()..color = shape.fill!);
      }
      if (shape.stroke != null) {
        canvas.drawPath(
          path,
          Paint()
            ..color = shape.stroke!
            ..style = PaintingStyle.stroke
            ..strokeWidth = shape.strokeWidth
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
      canvas.restore();
    }
    if (opacity < 1) canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SeasonalArtPainter old) =>
      old.art != art || old.opacity != opacity;
}
