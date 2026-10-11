// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Plan _$PlanFromJson(Map<String, dynamic> json) => _Plan(
  id: json['id'] as String,
  name: json['name'] as String,
  year: (json['year'] as num?)?.toInt(),
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  timeline: json['timeline'] as bool? ?? false,
  seasonalTheme: json['seasonal_theme'] as bool? ?? false,
  started: json['started'] as bool? ?? false,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => PlanItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$PlanToJson(_Plan instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'year': instance.year,
  'tags': instance.tags,
  'timeline': instance.timeline,
  'seasonal_theme': instance.seasonalTheme,
  'started': instance.started,
  'items': instance.items.map((e) => e.toJson()).toList(),
};
