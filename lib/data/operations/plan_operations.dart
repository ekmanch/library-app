import '../models/entry_id.dart';
import '../models/library.dart';
import '../models/plan.dart';
import '../models/plan_item.dart';
import 'library_operation.dart';

Library _replacePlan(Library library, Plan plan) {
  final index = library.plans.indexWhere((p) => p.id == plan.id);
  if (index < 0) return library;
  final plans = [...library.plans];
  plans[index] = plan;
  return library.copyWith(plans: plans);
}

/// Appends a plan. A taken id gets a numeric suffix.
class AddPlan extends LibraryOperation {
  const AddPlan(this.plan);

  final Plan plan;

  @override
  Library apply(Library library) {
    final id = EntryId.unique(plan.id, library.plans.map((p) => p.id));
    return library.copyWith(
      plans: [
        ...library.plans,
        plan.copyWith(id: id),
      ],
    );
  }
}

/// Replaces a plan in place, keeping its id and position.
class UpdatePlan extends LibraryOperation {
  const UpdatePlan(this.plan);

  final Plan plan;

  @override
  Library apply(Library library) {
    if (library.planById(plan.id) == null) return library;
    return _replacePlan(library, plan).withUnusedTagsRemoved();
  }
}

class DeletePlan extends LibraryOperation {
  const DeletePlan(this.planId);

  final String planId;

  @override
  Library apply(Library library) {
    if (library.planById(planId) == null) return library;
    return library
        .copyWith(plans: library.plans.where((p) => p.id != planId).toList())
        .withUnusedTagsRemoved();
  }
}

/// Adds an item to a plan, or replaces the item for the same entry in place.
class SetPlanItem extends LibraryOperation {
  const SetPlanItem(this.planId, this.item);

  final String planId;
  final PlanItem item;

  @override
  Library apply(Library library) {
    final plan = library.planById(planId);
    if (plan == null) return library;
    final items = [...plan.items];
    final index = items.indexWhere((i) => i.entry == item.entry);
    if (index < 0) {
      items.add(item);
    } else {
      items[index] = item;
    }
    return _replacePlan(library, plan.copyWith(items: items));
  }
}

/// Removes an entry from one plan. The entry itself stays.
class RemovePlanItem extends LibraryOperation {
  const RemovePlanItem(this.planId, this.entryId);

  final String planId;
  final String entryId;

  @override
  Library apply(Library library) {
    final plan = library.planById(planId);
    if (plan == null) return library;
    return _replacePlan(
      library,
      plan.copyWith(
        items: plan.items.where((i) => i.entry != entryId).toList(),
      ),
    );
  }
}

/// Turns a plan's Started switch on or off (S9). The app also turns it on
/// when the plan's first date arrives.
class SetPlanStarted extends LibraryOperation {
  const SetPlanStarted(this.planId, this.started);

  final String planId;
  final bool started;

  @override
  Library apply(Library library) {
    final plan = library.planById(planId);
    if (plan == null || plan.started == started) return library;
    return _replacePlan(library, plan.copyWith(started: started));
  }
}
