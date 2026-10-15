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
