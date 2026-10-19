// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eventModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LumaEventModel _$LumaEventModelFromJson(Map<String, dynamic> json) =>
    LumaEventModel(
      event: LumaEventDetailsModel.fromJson(
          json['event'] as Map<String, dynamic>),
      hosts: (json['hosts'] as List<dynamic>)
          .map((e) => LumaHostModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LumaEventModelToJson(LumaEventModel instance) =>
    <String, dynamic>{
      'event': instance.event,
      'hosts': instance.hosts,
    };

LumaHostModel _$LumaHostModelFromJson(Map<String, dynamic> json) =>
    LumaHostModel(
      api_id: json['api_id'] as String,
      email: json['email'] as String,
      name: json['name'] as String? ?? '',
      avatar_url: json['avatar_url'] as String,
    );

Map<String, dynamic> _$LumaHostModelToJson(LumaHostModel instance) =>
    <String, dynamic>{
      'api_id': instance.api_id,
      'email': instance.email,
      'name': instance.name,
      'avatar_url': instance.avatar_url,
    };

LumaEventDetailsModel _$LumaEventDetailsModelFromJson(
        Map<String, dynamic> json) =>
    LumaEventDetailsModel(
      api_id: json['api_id'] as String,
      created_at: json['created_at'] as String,
      cover_url: json['cover_url'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      description_md: json['description_md'] as String,
      start_at: json['start_at'] as String,
      end_at: json['end_at'] as String,
      url: json['url'] as String,
      timezone: json['timezone'] as String,
      event_type: json['event_type'] as String?,
      visibility: json['visibility'] as String,
      meeting_url: json['meeting_url'] as String,
    );

Map<String, dynamic> _$LumaEventDetailsModelToJson(
        LumaEventDetailsModel instance) =>
    <String, dynamic>{
      'api_id': instance.api_id,
      'created_at': instance.created_at,
      'cover_url': instance.cover_url,
      'name': instance.name,
      'description': instance.description,
      'description_md': instance.description_md,
      'start_at': instance.start_at,
      'end_at': instance.end_at,
      'url': instance.url,
      'timezone': instance.timezone,
      'event_type': instance.event_type,
      'visibility': instance.visibility,
      'meeting_url': instance.meeting_url,
    };
