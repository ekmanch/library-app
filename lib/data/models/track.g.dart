// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Track _$TrackFromJson(Map<String, dynamic> json) => _Track(
  title: json['title'] as String,
  id: json['id'] as String?,
  rating: (json['rating'] as num).toInt(),
);

Map<String, dynamic> _$TrackToJson(_Track instance) => <String, dynamic>{
  'title': instance.title,
  'id': ?instance.id,
  'rating': instance.rating,
};
