/// Plain text from the HTML-ish descriptions AniList and Google Books
/// return: tags dropped, `<br>` and paragraph ends become line breaks,
/// common entities decoded, whitespace collapsed.
String stripHtml(String html) {
  var text = html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>|</div>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'<[^>]+>'), '');
  text = text
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&#x27;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAllMapped(
        RegExp(r'&#(\d+);'),
        (m) => String.fromCharCode(int.parse(m.group(1)!)),
      )
      .replaceAll('&amp;', '&');
  text = text
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r' ?\n ?'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return text.trim();
}

/// Whether two titles are the same once case, punctuation, diacritics and
/// a leading "The" are set aside: "Salem's Lot" is "Salems lot", "The
/// Mummy" is "Mummy".
bool sameTitle(String a, String b) => _titleKey(a) == _titleKey(b);

String _titleKey(String title) {
  var key = title
      .toLowerCase()
      .replaceAll(RegExp(r"['’]"), '')
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .trim();
  if (key.startsWith('the ')) key = key.substring(4);
  return key.replaceAll(' ', '');
}
