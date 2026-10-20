import 'package:json_annotation/json_annotation.dart';

part 'eventModel.g.dart';

@JsonSerializable()
class LumaEventModel {
  final LumaEventDetailsModel event;
  final List<LumaHostModel> hosts;

  LumaEventModel({
    required this.event,
    required this.hosts,
  });

  factory LumaEventModel.fromJson(Map<String, dynamic> json) =>
      _$LumaEventModelFromJson(json);
  Map<String, dynamic> toJson() => _$LumaEventModelToJson(this);
}

@JsonSerializable()
class LumaHostModel {
  final String api_id;
  final String email;
  String name;
  final String avatar_url;

  LumaHostModel({
    required this.api_id,
    required this.email,
    this.name = '',
    required this.avatar_url,
  });

  factory LumaHostModel.fromJson(Map<String, dynamic> json) =>
      _$LumaHostModelFromJson(json);
  Map<String, dynamic> toJson() => _$LumaHostModelToJson(this);
}

@JsonSerializable()
class LumaEventDetailsModel {
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

  LumaEventDetailsModel({
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

  factory LumaEventDetailsModel.fromJson(Map<String, dynamic> json) =>
      _$LumaEventDetailsModelFromJson(json);
  Map<String, dynamic> toJson() => _$LumaEventDetailsModelToJson(this);
}
