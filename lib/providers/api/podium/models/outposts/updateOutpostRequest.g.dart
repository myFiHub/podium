// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'updateOutpostRequest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateOutpostRequest _$UpdateOutpostRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateOutpostRequest(
      luma_event_id: json['luma_event_id'] as String?,
      scheduled_for: (json['scheduled_for'] as num?)?.toInt(),
      image: json['image'] as String?,
      uuid: json['uuid'] as String,
    );

Map<String, dynamic> _$UpdateOutpostRequestToJson(
        UpdateOutpostRequest instance) =>
    <String, dynamic>{
      'luma_event_id': instance.luma_event_id,
      'scheduled_for': instance.scheduled_for,
      'image': instance.image,
      'uuid': instance.uuid,
    };
