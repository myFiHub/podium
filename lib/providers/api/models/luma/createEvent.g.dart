// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'createEvent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Luma_CreateEvent _$Luma_CreateEventFromJson(Map<String, dynamic> json) =>
    Luma_CreateEvent(
      name: json['name'] as String,
      start_at: json['start_at'] as String,
      meeting_url: json['meeting_url'] as String,
      timezone: json['timezone'] as String?,
      end_at: json['end_at'] as String?,
      require_rsvp_approval: json['require_rsvp_approval'] as bool? ?? false,
    );

Map<String, dynamic> _$Luma_CreateEventToJson(Luma_CreateEvent instance) =>
    <String, dynamic>{
      'name': instance.name,
      'start_at': instance.start_at,
      'meeting_url': instance.meeting_url,
      'timezone': instance.timezone,
      'end_at': instance.end_at,
      'require_rsvp_approval': instance.require_rsvp_approval,
    };
