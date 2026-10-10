import 'package:freezed_annotation/freezed_annotation.dart';

import 'date_only_converter.dart';

part 'plan_item.freezed.dart';
part 'plan_item.g.dart';

/// When a plan item is scheduled: a single day ([from] equals [to]) or a
/// period.
@freezed
abstract class PlanWhen with _$PlanWhen {
  const PlanWhen._();

  const factory PlanWhen({
    @DateOnlyConverter() required DateTime from,
    @DateOnlyConverter() required DateTime to,
  }) = _PlanWhen;

  factory PlanWhen.fromJson(Map<String, Object?> json) =>
      _$PlanWhenFromJson(json);

  bool get isSingleDay => from == to;
}

/// One entry inside a plan. [entry] is the entry id. [repeat] is set when the
/// entry was already done when it was added, so it is a rewatch or re-read.
@freezed
abstract class PlanItem with _$PlanItem {
  const factory PlanItem({
    required String entry,
    @Default(false) bool done,
    @Default(false) bool repeat,
    @Default('') String note,
    PlanWhen? when,
  }) = _PlanItem;

  factory PlanItem.fromJson(Map<String, Object?> json) =>
      _$PlanItemFromJson(json);
}
