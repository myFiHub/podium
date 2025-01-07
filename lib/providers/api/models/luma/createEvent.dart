import 'package:json_annotation/json_annotation.dart';

part 'createEvent.g.dart';

@JsonSerializable()
class Luma_CreateEvent {
  final String name;
  final String start_at;
  final String meeting_url;
  String? timezone;
  String? end_at;
  final bool
      require_rsvp_approval; //Require host approval for a guest to see meeting information.

  Luma_CreateEvent({
    required this.name,
    required this.start_at,
    required this.meeting_url,
    this.timezone,
    this.end_at,
    this.require_rsvp_approval = false,
  });

  factory Luma_CreateEvent.fromJson(Map<String, dynamic> json) =>
      _$Luma_CreateEventFromJson(json);
  Map<String, dynamic> toJson() => _$Luma_CreateEventToJson(this);
}
