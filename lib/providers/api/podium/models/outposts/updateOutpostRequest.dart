import 'package:json_annotation/json_annotation.dart';
part 'updateOutpostRequest.g.dart';

@JsonSerializable()
class UpdateOutpostRequest {
  final String? luma_event_id;
  final int? scheduled_for;
  final String? image;
  final String uuid;

  const UpdateOutpostRequest({
    this.luma_event_id,
    this.scheduled_for,
    this.image,
    required this.uuid,
  });

  factory UpdateOutpostRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateOutpostRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateOutpostRequestToJson(this);
}
