/// Tag names as typed are cleaned up and checked against the existing tags
/// before a new one is created (DESIGN.md section 7).
library;

/// Lowercases, drops a leading "#", turns spaces and underscores into
/// hyphens and trims hyphens from the ends.
String normalizeTag(String raw) {
  var name = raw.trim().toLowerCase();
  if (name.startsWith('#')) name = name.substring(1);
  return name
      .replaceAll(RegExp(r'[\s_]+'), '-')
      .replaceAll(RegExp(r'-{2,}'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

/// The existing tag most like [candidate], or null when none is close.
///
/// Two names are similar when they are the same once hyphens are ignored,
/// when one is the plural of the other, or when they are one edit apart
/// (two for a candidate of six letters or more): a letter changed, added
/// or dropped, or two neighboring letters swapped. An exact match is not
/// similar, it is the same tag.
String? findSimilarTag(String candidate, Iterable<String> existing) {
  final name = normalizeTag(candidate);
  if (name.isEmpty) return null;
  String? best;
  var bestRank = 1 << 30;
  for (final other in existing) {
    if (other == name) continue;
    final rank = _similarityRank(name, other);
    if (rank != null && rank < bestRank) {
      best = other;
      bestRank = rank;
    }
  }
  return best;
}

/// Lower is closer; null means not similar.
int? _similarityRank(String a, String b) {
  if (a.replaceAll('-', '') == b.replaceAll('-', '')) return 0;
  if (_isPluralOf(a, b) || _isPluralOf(b, a)) return 1;
  final limit = a.length >= 6 ? 2 : 1;
  final distance = _editDistance(a, b);
  return distance <= limit ? 1 + distance : null;
}

bool _isPluralOf(String plural, String singular) {
  if (plural == '${singular}s' || plural == '${singular}es') return true;
  return singular.endsWith('y') &&
      plural == '${singular.substring(0, singular.length - 1)}ies';
}

/// Optimal string alignment distance: substitutions, insertions, deletions
/// and adjacent transpositions each cost one.
int _editDistance(String a, String b) {
  final rows = a.length + 1;
  final cols = b.length + 1;
  final d = List.generate(rows, (i) => List<int>.filled(cols, 0));
  for (var i = 0; i < rows; i++) {
    d[i][0] = i;
  }
  for (var j = 0; j < cols; j++) {
    d[0][j] = j;
  }
  for (var i = 1; i < rows; i++) {
    for (var j = 1; j < cols; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      var best = d[i - 1][j] + 1;
      if (d[i][j - 1] + 1 < best) best = d[i][j - 1] + 1;
      if (d[i - 1][j - 1] + cost < best) best = d[i - 1][j - 1] + cost;
      if (i > 1 &&
          j > 1 &&
          a[i - 1] == b[j - 2] &&
          a[i - 2] == b[j - 1] &&
          d[i - 2][j - 2] + 1 < best) {
        best = d[i - 2][j - 2] + 1;
      }
      d[i][j] = best;
    }
  }
  return d[a.length][b.length];
}
