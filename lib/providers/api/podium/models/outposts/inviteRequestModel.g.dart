// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inviteRequestModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InviteRequestModel _$InviteRequestModelFromJson(Map<String, dynamic> json) =>
    InviteRequestModel(
      can_speak: json['can_speak'] as bool,
      invitee_user_uuid: json['invitee_user_uuid'] as String,
      outpost_uuid: json['outpost_uuid'] as String,
    );

Map<String, dynamic> _$InviteRequestModelToJson(InviteRequestModel instance) =>
    <String, dynamic>{
      'can_speak': instance.can_speak,
      'invitee_user_uuid': instance.invitee_user_uuid,
      'outpost_uuid': instance.outpost_uuid,
    };
