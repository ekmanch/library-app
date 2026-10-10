import '../../data/models/library.dart';
import '../../data/models/plan.dart';

/// Where a plan stands, as grouped on S5.
enum PlanState { active, notStarted, finished }

PlanState planState(Plan plan) {
  if (plan.items.isEmpty) return PlanState.notStarted;
  return plan.items.every((i) => i.done)
      ? PlanState.finished
      : PlanState.active;
}

int doneCount(Plan plan) => plan.items.where((i) => i.done).length;

/// "Halloween 2026", or just the name when there is no year.
String planTitle(Plan plan) =>
    plan.year == null ? plan.name : '${plan.name} ${plan.year}';

/// The plan shown on the library home card: the first active one.
Plan? activePlan(Library library) {
  for (final plan in library.plans) {
    if (planState(plan) == PlanState.active) return plan;
  }
  return null;
}
