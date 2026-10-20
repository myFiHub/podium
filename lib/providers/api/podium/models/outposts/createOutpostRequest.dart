import 'package:json_annotation/json_annotation.dart';

part 'createOutpostRequest.g.dart';

@JsonSerializable()
class CreateOutpostRequest {
  final String enter_type;
  final bool has_adult_content;
  final String? image;
  final bool is_recordable;
  final String name;
  final int scheduled_for;
  final String speak_type;
  final String subject;
  final List<String> tags;
  final List<String> tickets_to_enter;
  final List<String> tickets_to_speak;
  final List<String> cohost_user_uuids;
  final bool is_music_mode;

  CreateOutpostRequest({
    required this.enter_type,
    required this.has_adult_content,
    this.image,
    required this.is_recordable,
    required this.name,
    required this.scheduled_for,
    required this.speak_type,
    required this.subject,
    required this.tags,
    required this.tickets_to_enter,
    required this.tickets_to_speak,
    required this.cohost_user_uuids,
    this.is_music_mode = false,
  });

  factory CreateOutpostRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateOutpostRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateOutpostRequestToJson(this);
}
