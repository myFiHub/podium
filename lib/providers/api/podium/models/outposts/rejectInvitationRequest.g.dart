// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rejectInvitationRequest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RejectInvitationRequest _$RejectInvitationRequestFromJson(
        Map<String, dynamic> json) =>
    RejectInvitationRequest(
      inviter_uuid: json['inviter_uuid'] as String,
      outpost_uuid: json['outpost_uuid'] as String,
    );

Map<String, dynamic> _$RejectInvitationRequestToJson(
        RejectInvitationRequest instance) =>
    <String, dynamic>{
      'inviter_uuid': instance.inviter_uuid,
      'outpost_uuid': instance.outpost_uuid,
    };
