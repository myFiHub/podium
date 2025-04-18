// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setReminder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetOrRemoveReminderRequest _$SetOrRemoveReminderRequestFromJson(
        Map<String, dynamic> json) =>
    SetOrRemoveReminderRequest(
      uuid: json['uuid'] as String,
      minutes_before: (json['minutes_before'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SetOrRemoveReminderRequestToJson(
        SetOrRemoveReminderRequest instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'minutes_before': instance.minutes_before,
    };
