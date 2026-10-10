import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/models/plan.dart';
import 'package:library_app/data/models/plan_item.dart';
import 'package:library_app/features/plans/plan_progress.dart';

import '../../helpers/pump_app.dart';

void main() {
  test('plan state from its items', () {
    const empty = Plan(id: 'a', name: 'A');
    expect(planState(empty), PlanState.notStarted);
    const some = Plan(
      id: 'b',
      name: 'B',
      items: [
        PlanItem(entry: 'x', done: true),
        PlanItem(entry: 'y'),
      ],
    );
    expect(planState(some), PlanState.active);
    expect(doneCount(some), 1);
    const all = Plan(
      id: 'c',
      name: 'C',
      year: 2025,
      items: [PlanItem(entry: 'x', done: true)],
    );
    expect(planState(all), PlanState.finished);
    expect(planTitle(all), 'C 2025');
    expect(planTitle(empty), 'A');
  });

  test('the fixture has Halloween 2026 as the active plan', () {
    final plan = activePlan(loadFixture());
    expect(plan?.id, 'halloween-2026');
  });
}
