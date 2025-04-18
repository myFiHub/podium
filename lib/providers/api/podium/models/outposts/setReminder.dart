import 'package:json_annotation/json_annotation.dart';

part 'setReminder.g.dart';

@JsonSerializable()
class SetOrRemoveReminderRequest {
  final String uuid;
  final int? minutes_before;

  SetOrRemoveReminderRequest({
    required this.uuid,
    this.minutes_before,
  });

  factory SetOrRemoveReminderRequest.fromJson(Map<String, dynamic> json) =>
      _$SetOrRemoveReminderRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetOrRemoveReminderRequestToJson(this);
}
