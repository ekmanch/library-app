import 'package:flutter/material.dart';

import '../../data/models/entry.dart';
import '../../data/models/media_type.dart';
import '../../theme/app_theme.dart';

/// Stands in for a cover until images arrive in phase 5: a colored box
/// with the title in it. Albums and songs are square, everything else is a
/// 2:3 poster (the games shape is still open in DESIGN.md).
class CoverPlaceholder extends StatelessWidget {
  const CoverPlaceholder({
    super.key,
    required this.entry,
    required this.width,
    this.fontSize = 7,
  });

  final Entry entry;
  final double width;
  final double fontSize;

  static double aspectRatio(MediaType type) =>
      type == MediaType.music ? 1 : 2 / 3;

  /// Same title, same color, on every run and platform.
  static int paletteIndex(String title, int paletteLength) =>
      title.codeUnits.fold(0, (sum, c) => sum + c) % paletteLength;

  @override
  Widget build(BuildContext context) {
    final palette = LibraryColors.of(context).coverPlaceholders;
    final color = palette[paletteIndex(entry.title, palette.length)];
    return Semantics(
      excludeSemantics: true,
      child: Container(
        width: width,
        height: width / aspectRatio(entry.type),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: Text(
          entry.title,
          textAlign: TextAlign.center,
          overflow: TextOverflow.clip,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: const Color(0xCCFFFFFF),
          ),
        ),
      ),
    );
  }
}
