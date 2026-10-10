import 'package:flutter/material.dart';

import '../../data/models/entry.dart';
import '../../data/models/plan.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_dialog.dart';
import 'plan_builders.dart';
import 'plan_progress.dart';

enum RemoveChoice { fromPlan, everywhere }

/// D4: remove an entry from this plan, or delete it everywhere. [plan] is
/// the one open; [otherPlans] are the other plans it is in. Null means
/// cancel.
Future<RemoveChoice?> showRemoveFromPlanDialog(
  BuildContext context, {
  required Entry entry,
  required Plan plan,
  required List<Plan> otherPlans,
}) {
  final names = [plan, ...otherPlans].map(planTitle).toList();
  final where = names.length == 1
      ? 'the plan ${names.single}'
      : 'the plans ${names.sublist(0, names.length - 1).join(', ')} '
            'and ${names.last}';
  return showAppDialog<RemoveChoice>(
    context,
    inheritTheme: true,
    builder: (context) => AppDialog(
      title: 'Remove ${entry.title}?',
      body: 'It is in $where and in your library.',
      actionsLayout: DialogActionsLayout.column,
      actions: [
        AppButton(
          label: 'Remove from this plan',
          kind: AppButtonKind.neutral,
          onPressed: () => Navigator.pop(context, RemoveChoice.fromPlan),
        ),
        AppButton(
          label: 'Delete everywhere',
          kind: AppButtonKind.destructiveOutline,
          onPressed: () => Navigator.pop(context, RemoveChoice.everywhere),
        ),
        AppButton(
          label: 'Cancel',
          kind: AppButtonKind.text,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}

/// D5: delete a plan. Its entries stay. Resolves true when confirmed.
Future<bool> confirmDeletePlan(BuildContext context, Plan plan) async {
  final n = plan.items.length;
  final ok = await showAppDialog<bool>(
    context,
    inheritTheme: true,
    builder: (context) => AppDialog(
      title: 'Delete ${planTitle(plan)}?',
      body: 'The plan and its checkmarks are removed.',
      note: n == 0
          ? 'It has no entries yet.'
          : 'Its ${n == 1 ? 'entry stays' : '$n entries stay'} in your library.',
      actions: [
        AppButton(
          label: 'Cancel',
          kind: AppButtonKind.outline,
          onPressed: () => Navigator.pop(context, false),
        ),
        AppButton(
          label: 'Delete plan',
          kind: AppButtonKind.destructive,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );
  return ok ?? false;
}

enum PlanMenuAction { edit, copy, delete }

/// D3: the plan menu under the "⋮" button, anchored to [anchor].
Future<PlanMenuAction?> showPlanMenu(
  BuildContext context,
  BuildContext anchor, {
  required Plan plan,
}) {
  final theme = Theme.of(context);
  final button = anchor.findRenderObject() as RenderBox;
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final origin = button.localToGlobal(Offset.zero, ancestor: overlay);
  final position = RelativeRect.fromLTRB(
    origin.dx + button.size.width - 230,
    origin.dy + button.size.height + 4,
    overlay.size.width - origin.dx - button.size.width,
    0,
  );
  PopupMenuItem<PlanMenuAction> item(
    PlanMenuAction action,
    String label, {
    Color? color,
  }) => PopupMenuItem(
    value: action,
    height: 52,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Text(
      label,
      style: theme.textTheme.titleMedium!.copyWith(color: color),
    ),
  );
  return showMenu<PlanMenuAction>(
    context: context,
    useRootNavigator: true,
    position: position,
    constraints: const BoxConstraints(minWidth: 230, maxWidth: 230),
    popUpAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 150),
      reverseDuration: Duration(milliseconds: 100),
    ),
    items: [
      item(PlanMenuAction.edit, 'Edit plan'),
      item(PlanMenuAction.copy, 'Copy to a new year'),
      const PopupMenuDivider(height: 9),
      item(
        PlanMenuAction.delete,
        'Delete plan',
        color: theme.colorScheme.error,
      ),
    ],
  );
}

/// "Halloween 2026", for the labels around a plan.
String planLabel(Plan plan) => planTitle(plan);

/// Keeps [progressLabel] reachable from the dialogs' importers.
String planProgress(Plan plan) => progressLabel(plan);
