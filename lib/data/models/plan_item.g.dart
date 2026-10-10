// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlanWhen _$PlanWhenFromJson(Map<String, dynamic> json) => _PlanWhen(
  from: const DateOnlyConverter().fromJson(json['from'] as String),
  to: const DateOnlyConverter().fromJson(json['to'] as String),
);

Map<String, dynamic> _$PlanWhenToJson(_PlanWhen instance) => <String, dynamic>{
  'from': const DateOnlyConverter().toJson(instance.from),
  'to': const DateOnlyConverter().toJson(instance.to),
};

_PlanItem _$PlanItemFromJson(Map<String, dynamic> json) => _PlanItem(
  entry: json['entry'] as String,
  done: json['done'] as bool? ?? false,
  repeat: json['repeat'] as bool? ?? false,
  note: json['note'] as String? ?? '',
  when: json['when'] == null
      ? null
      : PlanWhen.fromJson(json['when'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PlanItemToJson(_PlanItem instance) => <String, dynamic>{
  'entry': instance.entry,
  'done': instance.done,
  'repeat': instance.repeat,
  'note': instance.note,
  'when': instance.when?.toJson(),
};
