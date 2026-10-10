import 'package:freezed_annotation/freezed_annotation.dart';

import 'plan_item.dart';

part 'plan.freezed.dart';
part 'plan.g.dart';

/// A named list of entries, for example "Halloween 2026". An entry matches
/// the plan's tags if it has any of them.
@freezed
abstract class Plan with _$Plan {
  const Plan._();

  const factory Plan({
    required String id,
    required String name,
    int? year,
    @Default([]) List<String> tags,
    @Default(false) bool timeline,
    @JsonKey(name: 'seasonal_theme') @Default(false) bool seasonalTheme,
    @Default([]) List<PlanItem> items,
  }) = _Plan;

  factory Plan.fromJson(Map<String, Object?> json) => _$PlanFromJson(json);

  PlanItem? itemFor(String entryId) {
    for (final item in items) {
      if (item.entry == entryId) return item;
    }
    return null;
  }
}
