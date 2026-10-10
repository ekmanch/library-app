import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/models/released.dart';
import 'package:library_app/features/library/entry_sections.dart';
import 'package:library_app/features/library/library_sort.dart';

import '../../helpers/sample_library.dart';

void main() {
  final today = DateTime(2026, 10, 10);

  test('year orders group by decade, Older first or last, undated last', () {
    final entries = sortEntries([
      mummy.copyWith(title: 'a', released: const Released(1999)),
      mummy.copyWith(title: 'b', released: const Released(2025)),
      mummy.copyWith(title: 'c', released: null),
      mummy.copyWith(title: 'd', released: const Released(1931)),
      mummy.copyWith(title: 'e', released: const Released(1991)),
      mummy.copyWith(title: 'f', released: const Released(2027, 3)),
    ], LibrarySort.yearNewest);
    final sections = sectionEntries(entries, LibrarySort.yearNewest);
    expect(sections.map((s) => s.label), [
      '2020s',
      '1990s',
      'Older',
      'Not released yet',
    ]);
    expect(sections.map((s) => s.railLabel), ['20s', '90s', 'Older', 'TBA']);
    expect(sections[1].entries.map((e) => e.title), ['a', 'e']);
    expect(sections[0].bubbleLabel, '2020s');

    final oldest = sectionEntries(
      sortEntries(entries, LibrarySort.yearOldest),
      LibrarySort.yearOldest,
    );
    expect(oldest.map((s) => s.label), [
      'Older',
      '1990s',
      '2020s',
      'Not released yet',
    ]);
  });

  test('newest added groups by month this year, then by year', () {
    final entries = sortEntries([
      mummy.copyWith(title: 'a', added: DateTime(2026, 10, 3)),
      mummy.copyWith(title: 'b', added: DateTime(2026, 10, 1)),
      mummy.copyWith(title: 'c', added: DateTime(2026, 3, 9)),
      mummy.copyWith(title: 'd', added: DateTime(2025, 12, 31)),
      mummy.copyWith(title: 'e', added: DateTime(2025, 1, 1)),
      mummy.copyWith(title: 'f', added: DateTime(2024, 6, 1)),
    ], LibrarySort.newestAdded);
    final sections = sectionEntries(
      entries,
      LibrarySort.newestAdded,
      today: today,
    );
    expect(sections.map((s) => s.label), [
      'October 2026',
      'March 2026',
      '2025',
      '2024',
    ]);
    expect(sections.map((s) => s.railLabel), ['Oct', 'Mar', '2025', '2024']);
    expect(sections.map((s) => s.bubbleLabel), [
      'Oct 2026',
      'Mar 2026',
      '2025',
      '2024',
    ]);
    expect(sections[0].entries.length, 2);
    expect(sections[2].entries.length, 2);
  });

  test('title order groups by first letter, digits and symbols under #', () {
    final entries = sortEntries([
      mummy.copyWith(title: 'Amélie'),
      mummy.copyWith(title: 'Élan'),
      mummy.copyWith(title: '28 Days Later'),
      mummy.copyWith(title: 'alien'),
      mummy.copyWith(title: '#1'),
    ], LibrarySort.titleAz);
    final sections = sectionEntries(entries, LibrarySort.titleAz);
    expect(sections.map((s) => s.label), ['#', 'A', 'E']);
    expect(sections[0].entries.length, 2);
    expect(sections[1].entries.length, 2);
  });

  test('the rail needs three screens and two sections', () {
    expect(
      showJumpRail(sectionCount: 2, contentHeight: 3000, viewportHeight: 1000),
      isTrue,
    );
    expect(
      showJumpRail(sectionCount: 1, contentHeight: 3000, viewportHeight: 1000),
      isFalse,
    );
    expect(
      showJumpRail(sectionCount: 5, contentHeight: 2999, viewportHeight: 1000),
      isFalse,
    );
  });
}
