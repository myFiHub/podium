import 'package:json_annotation/json_annotation.dart';

part 'rejectInvitationRequest.g.dart';

@JsonSerializable()
class RejectInvitationRequest {
  final String inviter_uuid;
  final String outpost_uuid;

  RejectInvitationRequest({
    required this.inviter_uuid,
    required this.outpost_uuid,
  });

  factory RejectInvitationRequest.fromJson(Map<String, dynamic> json) =>
      _$RejectInvitationRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RejectInvitationRequestToJson(this);
}
