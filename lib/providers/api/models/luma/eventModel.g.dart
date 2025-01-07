// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eventModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Luma_EventModel _$Luma_EventModelFromJson(Map<String, dynamic> json) =>
    Luma_EventModel(
      event: Luma_EventDetailsModel.fromJson(
          json['event'] as Map<String, dynamic>),
      hosts: (json['hosts'] as List<dynamic>)
          .map((e) => Luma_HostModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$Luma_EventModelToJson(Luma_EventModel instance) =>
    <String, dynamic>{
      'event': instance.event,
      'hosts': instance.hosts,
    };

Luma_HostModel _$Luma_HostModelFromJson(Map<String, dynamic> json) =>
    Luma_HostModel(
      api_id: json['api_id'] as String,
      email: json['email'] as String,
      name: json['name'] as String? ?? '',
      avatar_url: json['avatar_url'] as String,
    );

Map<String, dynamic> _$Luma_HostModelToJson(Luma_HostModel instance) =>
    <String, dynamic>{
      'api_id': instance.api_id,
      'email': instance.email,
      'name': instance.name,
      'avatar_url': instance.avatar_url,
    };

Luma_EventDetailsModel _$Luma_EventDetailsModelFromJson(
        Map<String, dynamic> json) =>
    Luma_EventDetailsModel(
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
      event_type: json['event_type'] as String,
      visibility: json['visibility'] as String,
      meeting_url: json['meeting_url'] as String,
    );

Map<String, dynamic> _$Luma_EventDetailsModelToJson(
        Luma_EventDetailsModel instance) =>
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
