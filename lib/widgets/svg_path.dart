import 'dart:ui';

/// Turns an SVG path `d` string into a [Path]. Supports the commands the
/// seasonal artwork uses: M, L, H, V, C, S, Q, T, A and Z, absolute and
/// relative. Good enough for hand-drawn illustrations; not a full parser.
Path parseSvgPath(String d) {
  final path = Path();
  final tokens = RegExp(r'[A-Za-z]|-?(?:\d+\.?\d*|\.\d+)(?:e-?\d+)?')
      .allMatches(d)
      .map((m) => m.group(0)!)
      .toList();
  var i = 0;
  var cmd = '';
  var x = 0.0, y = 0.0; // Current point.
  var sx = 0.0, sy = 0.0; // Subpath start.
  double? cx2, cy2; // Last cubic control point, for S.
  double? qx, qy; // Last quadratic control point, for T.

  double num() {
    if (i >= tokens.length || RegExp('[A-Za-z]').hasMatch(tokens[i])) {
      throw FormatException('Missing number after "$cmd" in "$d"');
    }
    return double.parse(tokens[i++]);
  }

  while (i < tokens.length) {
    final t = tokens[i];
    if (RegExp('[A-Za-z]').hasMatch(t)) {
      cmd = t;
      i++;
      if (cmd == 'Z' || cmd == 'z') {
        path.close();
        x = sx;
        y = sy;
        cx2 = cy2 = qx = qy = null;
        continue;
      }
    }
    final rel = cmd.toLowerCase() == cmd;
    switch (cmd.toUpperCase()) {
      case 'M':
        var nx = num(), ny = num();
        if (rel) {
          nx += x;
          ny += y;
        }
        path.moveTo(nx, ny);
        x = sx = nx;
        y = sy = ny;
        // Further pairs after M are implicit L.
        cmd = rel ? 'l' : 'L';
        cx2 = cy2 = qx = qy = null;
      case 'L':
        var nx = num(), ny = num();
        if (rel) {
          nx += x;
          ny += y;
        }
        path.lineTo(nx, ny);
        x = nx;
        y = ny;
        cx2 = cy2 = qx = qy = null;
      case 'H':
        var nx = num();
        if (rel) nx += x;
        path.lineTo(nx, y);
        x = nx;
        cx2 = cy2 = qx = qy = null;
      case 'V':
        var ny = num();
        if (rel) ny += y;
        path.lineTo(x, ny);
        y = ny;
        cx2 = cy2 = qx = qy = null;
      case 'C':
        var x1 = num(), y1 = num(), x2 = num(), y2 = num();
        var nx = num(), ny = num();
        if (rel) {
          x1 += x;
          y1 += y;
          x2 += x;
          y2 += y;
          nx += x;
          ny += y;
        }
        path.cubicTo(x1, y1, x2, y2, nx, ny);
        cx2 = x2;
        cy2 = y2;
        x = nx;
        y = ny;
        qx = qy = null;
      case 'S':
        var x2 = num(), y2 = num(), nx = num(), ny = num();
        if (rel) {
          x2 += x;
          y2 += y;
          nx += x;
          ny += y;
        }
        final x1 = cx2 == null ? x : 2 * x - cx2;
        final y1 = cy2 == null ? y : 2 * y - cy2;
        path.cubicTo(x1, y1, x2, y2, nx, ny);
        cx2 = x2;
        cy2 = y2;
        x = nx;
        y = ny;
        qx = qy = null;
      case 'Q':
        var x1 = num(), y1 = num(), nx = num(), ny = num();
        if (rel) {
          x1 += x;
          y1 += y;
          nx += x;
          ny += y;
        }
        path.quadraticBezierTo(x1, y1, nx, ny);
        qx = x1;
        qy = y1;
        x = nx;
        y = ny;
        cx2 = cy2 = null;
      case 'T':
        var nx = num(), ny = num();
        if (rel) {
          nx += x;
          ny += y;
        }
        final x1 = qx == null ? x : 2 * x - qx;
        final y1 = qy == null ? y : 2 * y - qy;
        path.quadraticBezierTo(x1, y1, nx, ny);
        qx = x1;
        qy = y1;
        x = nx;
        y = ny;
        cx2 = cy2 = null;
      case 'A':
        final rx = num(), ry = num(), rot = num();
        final large = num() != 0, sweep = num() != 0;
        var nx = num(), ny = num();
        if (rel) {
          nx += x;
          ny += y;
        }
        path.arcToPoint(
          Offset(nx, ny),
          radius: Radius.elliptical(rx, ry),
          rotation: rot,
          largeArc: large,
          clockwise: sweep,
        );
        x = nx;
        y = ny;
        cx2 = cy2 = qx = qy = null;
      default:
        throw FormatException('Unsupported SVG path command "$cmd"');
    }
  }
  return path;
}
