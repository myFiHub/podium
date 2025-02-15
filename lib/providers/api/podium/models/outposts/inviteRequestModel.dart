import 'package:json_annotation/json_annotation.dart';

part 'inviteRequestModel.g.dart';

@JsonSerializable()
class InviteRequestModel {
  final bool can_speak;
  final String invitee_user_uuid;
  final String outpost_uuid;

  InviteRequestModel({
    required this.can_speak,
    required this.invitee_user_uuid,
    required this.outpost_uuid,
  });

  factory InviteRequestModel.fromJson(Map<String, dynamic> json) =>
      _$InviteRequestModelFromJson(json);
  Map<String, dynamic> toJson() => _$InviteRequestModelToJson(this);
}
