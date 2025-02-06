// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'createOutpostRequest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateOutpostRequest _$CreateOutpostRequestFromJson(
        Map<String, dynamic> json) =>
    CreateOutpostRequest(
      enter_type: json['enter_type'] as String,
      has_adult_content: json['has_adult_content'] as bool,
      image: json['image'] as String?,
      is_recordable: json['is_recordable'] as bool,
      name: json['name'] as String,
      scheduled_for: (json['scheduled_for'] as num).toInt(),
      speak_type: json['speak_type'] as String,
      subject: json['subject'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      tickets_to_enter: (json['tickets_to_enter'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      tickets_to_speak: (json['tickets_to_speak'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$CreateOutpostRequestToJson(
        CreateOutpostRequest instance) =>
    <String, dynamic>{
      'enter_type': instance.enter_type,
      'has_adult_content': instance.has_adult_content,
      'image': instance.image,
      'is_recordable': instance.is_recordable,
      'name': instance.name,
      'scheduled_for': instance.scheduled_for,
      'speak_type': instance.speak_type,
      'subject': instance.subject,
      'tags': instance.tags,
      'tickets_to_enter': instance.tickets_to_enter,
      'tickets_to_speak': instance.tickets_to_speak,
    };
