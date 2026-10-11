import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/models/plan.dart';
import 'package:library_app/data/models/plan_item.dart';
import 'package:library_app/features/plans/plan_builders.dart';
import 'package:library_app/features/plans/plan_dates.dart';
import 'package:library_app/features/plans/plan_season.dart';
import 'package:library_app/features/plans/plan_timeline.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/sample_library.dart';

PlanWhen when(int fm, int fd, [int? tm, int? td]) => PlanWhen(
  from: DateTime(2026, fm, fd),
  to: DateTime(2026, tm ?? fm, td ?? fd),
);

void main() {
  group('dates', () {
    test('formatWhen', () {
      expect(formatWhen(when(10, 19, 10, 31)), 'Oct 19–31');
      expect(formatWhen(when(10, 28, 11, 2)), 'Oct 28 – Nov 2');
      expect(formatWhen(when(10, 17)), 'Sat Oct 17');
      expect(formatWhen(when(10, 19, 10, 31), year: 2025), 'Oct 19–31 2026');
    });
  });

  group('timeline', () {
    final plan = Plan(
      id: 'p',
      name: 'Halloween',
      year: 2026,
      items: [
        const PlanItem(entry: 'z'),
        PlanItem(entry: 'd', when: when(10, 19, 10, 31)),
        PlanItem(entry: 'a', when: when(10, 1, 10, 4)),
        PlanItem(entry: 'b', when: when(10, 5, 10, 11)),
        PlanItem(entry: 'c', when: when(10, 17)),
        PlanItem(entry: 'b2', when: when(10, 5, 10, 11)),
      ],
    );

    test('groups by time: last week, this week, days, later, whenever', () {
      final groups = timelineGroups(plan, today: DateTime(2026, 10, 7));
      expect(groups.map((g) => g.title), [
        'Last week',
        'This week',
        'Sat Oct 17',
        'Later',
        'Whenever',
      ]);
      expect(groups.map((g) => g.dates), [
        'Oct 1–4',
        'Oct 5–11',
        'One day',
        'Oct 19–31',
        'No date',
      ]);
      expect(groups[1].items.map((i) => i.entry), ['b', 'b2']);
      expect(groups[1].state, TimelineState.current);
      expect(groups[1].todayFraction, closeTo(2.5 / 7, 0.001));
      expect(groups[0].state, TimelineState.past);
      expect(groups[2].state, TimelineState.future);
      expect(groups[4].state, TimelineState.undated);
      expect(groups[4].items.single.entry, 'z');
    });

    test('older items are Earlier; a day in this week joins This week', () {
      final groups = timelineGroups(plan, today: DateTime(2026, 10, 17));
      expect(groups.map((g) => g.title), [
        'Earlier',
        'Last week',
        'This week',
        'Later',
        'Whenever',
      ]);
      expect(groups[2].items.single.entry, 'c');
      expect(groups[2].todayFraction, closeTo(5.5 / 7, 0.001));
    });

    test('every Later period shares one bucket, in type order', () {
      final later = Plan(
        id: 'l',
        name: 'L',
        items: [
          PlanItem(entry: 'show', when: when(10, 24, 10, 26)),
          PlanItem(entry: 'movie', when: when(10, 19, 10, 31)),
          PlanItem(entry: 'book', when: when(10, 20, 10, 22)),
        ],
      );
      const rank = {'movie': 0, 'show': 1, 'book': 2};
      final groups = timelineGroups(
        later,
        today: DateTime(2026, 10, 7),
        typeRank: (i) => rank[i.entry]!,
      );
      expect(groups.single.title, 'Later');
      expect(groups.single.dates, 'Oct 19–31');
      expect(groups.single.items.map((i) => i.entry), [
        'movie',
        'show',
        'book',
      ]);
    });
  });

  group('builders', () {
    test('ids, years, copies', () {
      expect(newPlanId('Summer vacation', null, const []), 'summer-vacation');
      expect(
        newPlanId('Halloween', 2026, const ['halloween-2026']),
        'halloween-2026-2',
      );
      expect(nextYearFor(halloweenPlan), 2027);
      expect(
        nextYearFor(
          const Plan(id: 'x', name: 'X'),
          today: DateTime(2026, 5, 1),
        ),
        2027,
      );
      final source = halloweenPlan.copyWith(
        items: [
          ...halloweenPlan.items,
          const PlanItem(entry: 'done-one', done: true),
        ],
      );
      final copy = copyPlan(
        source,
        id: 'halloween-2027',
        name: 'Halloween',
        year: 2027,
      );
      expect(copy.items.map((i) => i.entry), [mummy.id]);
      expect(copy.items.single.when, isNull);
      expect(copy.tags, ['halloween']);
      expect(copy.timeline, isTrue);
    });

    test('plan years are the same-named plans, newest first', () {
      final fixture = loadFixture();
      final plan = fixture.planById('halloween-2026')!;
      expect(planYears(fixture, plan).map((p) => p.id), [
        'halloween-2026',
        'halloween-2025',
      ]);
    });

    test('subtitles, next up and progress', () {
      final library = sampleLibrary();
      expect(planSubtitle(library.plans[1]), 'Empty, linked to #christmas');
      expect(planSubtitle(halloweenPlan), 'Linked to #halloween');
      expect(
        planSubtitle(
          const Plan(
            id: 'x',
            name: 'X',
            items: [PlanItem(entry: 'e')],
          ),
        ),
        '1 entry',
      );
      expect(nextUp(halloweenPlan, library), ['The Mummy']);
      expect(progressLabel(halloweenPlan), '0 of 1 done');
    });
  });

  test('seasons come from the linked tags, only with the theme on', () {
    expect(seasonOf(halloweenPlan), PlanSeason.halloween);
    expect(seasonOf(halloweenPlan.copyWith(seasonalTheme: false)), isNull);
    expect(seasonForTags(['cozy', 'christmas']), PlanSeason.christmas);
    expect(seasonForTags(['cozy']), isNull);
  });
}
