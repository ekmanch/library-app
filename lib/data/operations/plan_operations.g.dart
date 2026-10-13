// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_operations.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddPlan _$AddPlanFromJson(Map<String, dynamic> json) =>
    AddPlan(Plan.fromJson(json['plan'] as Map<String, dynamic>));

Map<String, dynamic> _$AddPlanToJson(AddPlan instance) => <String, dynamic>{
  'plan': instance.plan.toJson(),
};

UpdatePlan _$UpdatePlanFromJson(Map<String, dynamic> json) =>
    UpdatePlan(Plan.fromJson(json['plan'] as Map<String, dynamic>));

Map<String, dynamic> _$UpdatePlanToJson(UpdatePlan instance) =>
    <String, dynamic>{'plan': instance.plan.toJson()};

DeletePlan _$DeletePlanFromJson(Map<String, dynamic> json) =>
    DeletePlan(json['planId'] as String);

Map<String, dynamic> _$DeletePlanToJson(DeletePlan instance) =>
    <String, dynamic>{'planId': instance.planId};

SetPlanItem _$SetPlanItemFromJson(Map<String, dynamic> json) => SetPlanItem(
  json['planId'] as String,
  PlanItem.fromJson(json['item'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SetPlanItemToJson(SetPlanItem instance) =>
    <String, dynamic>{
      'planId': instance.planId,
      'item': instance.item.toJson(),
    };

RemovePlanItem _$RemovePlanItemFromJson(Map<String, dynamic> json) =>
    RemovePlanItem(json['planId'] as String, json['entryId'] as String);

Map<String, dynamic> _$RemovePlanItemToJson(RemovePlanItem instance) =>
    <String, dynamic>{'planId': instance.planId, 'entryId': instance.entryId};

SetPlanStarted _$SetPlanStartedFromJson(Map<String, dynamic> json) =>
    SetPlanStarted(json['planId'] as String, json['started'] as bool);

Map<String, dynamic> _$SetPlanStartedToJson(SetPlanStarted instance) =>
    <String, dynamic>{'planId': instance.planId, 'started': instance.started};
