// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setReminder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetOrRemoveReminderRequest _$SetOrRemoveReminderRequestFromJson(
        Map<String, dynamic> json) =>
    SetOrRemoveReminderRequest(
      uuid: json['uuid'] as String,
      reminder_offset_minutes:
          (json['reminder_offset_minutes'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SetOrRemoveReminderRequestToJson(
        SetOrRemoveReminderRequest instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'reminder_offset_minutes': instance.reminder_offset_minutes,
    };
