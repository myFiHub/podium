import 'package:json_annotation/json_annotation.dart';

part 'setReminder.g.dart';

@JsonSerializable()
class SetOrRemoveReminderRequest {
  final String uuid;
  final int? reminder_offset_minutes;

  SetOrRemoveReminderRequest({
    required this.uuid,
    this.reminder_offset_minutes,
  });

  factory SetOrRemoveReminderRequest.fromJson(Map<String, dynamic> json) =>
      _$SetOrRemoveReminderRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetOrRemoveReminderRequestToJson(this);
}
