import 'package:json_annotation/json_annotation.dart';

part 'eventModel.g.dart';

@JsonSerializable()
class Luma_EventModel {
  final Luma_EventDetailsModel event;
  final List<Luma_HostModel> hosts;

  Luma_EventModel({
    required this.event,
    required this.hosts,
  });

  factory Luma_EventModel.fromJson(Map<String, dynamic> json) =>
      _$Luma_EventModelFromJson(json);
  Map<String, dynamic> toJson() => _$Luma_EventModelToJson(this);
}

@JsonSerializable()
class Luma_HostModel {
  final String api_id;
  final String email;
  String name;
  final String avatar_url;

  Luma_HostModel({
    required this.api_id,
    required this.email,
    this.name = '',
    required this.avatar_url,
  });

  factory Luma_HostModel.fromJson(Map<String, dynamic> json) =>
      _$Luma_HostModelFromJson(json);
  Map<String, dynamic> toJson() => _$Luma_HostModelToJson(this);
}

@JsonSerializable()
class Luma_EventDetailsModel {
  final String api_id;
  final String created_at;
  final String cover_url;
  final String name;
  final String description;
  final String description_md;
  final String start_at;
  final String end_at;
  final String url;
  final String timezone;
  String? event_type;
  final String visibility;
  final String meeting_url;

  Luma_EventDetailsModel({
    required this.api_id,
    required this.created_at,
    required this.cover_url,
    required this.name,
    required this.description,
    required this.description_md,
    required this.start_at,
    required this.end_at,
    required this.url,
    required this.timezone,
    this.event_type,
    required this.visibility,
    required this.meeting_url,
  });

  factory Luma_EventDetailsModel.fromJson(Map<String, dynamic> json) =>
      _$Luma_EventDetailsModelFromJson(json);
  Map<String, dynamic> toJson() => _$Luma_EventDetailsModelToJson(this);
}
