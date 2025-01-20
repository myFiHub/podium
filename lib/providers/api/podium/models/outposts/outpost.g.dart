// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outpost.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OutpostModel _$OutpostModelFromJson(Map<String, dynamic> json) => OutpostModel(
      alarm_id: (json['alarm_id'] as num).toInt(),
      uuid: json['uuid'] as String,
      created_at: json['created_at'] as String,
      creator_joined: json['creator_joined'] as bool,
      creator_user_name: json['creator_user_name'] as String,
      creator_user_uuid: json['creator_user_uuid'] as String,
      creator_user_image: json['creator_user_image'] as String,
      enter_type: json['enter_type'] as String,
      has_adult_content: json['has_adult_content'] as bool,
      image: json['image'] as String,
      invites: (json['invites'] as List<dynamic>)
          .map((e) => _InviteModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      is_archived: json['is_archived'] as bool,
      is_recordable: json['is_recordable'] as bool,
      last_active_at: (json['last_active_at'] as num).toInt(),
      members: (json['members'] as List<dynamic>)
          .map((e) => OutpostMember.fromJson(e as Map<String, dynamic>))
          .toList(),
      members_count: (json['members_count'] as num).toInt(),
      name: json['name'] as String,
      scheduled_for: (json['scheduled_for'] as num).toInt(),
      speak_type: json['speak_type'] as String,
      subject: json['subject'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      tickets_to_enter: (json['tickets_to_enter'] as List<dynamic>)
          .map((e) => _TicketToEnterModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      tickets_to_speak: (json['tickets_to_speak'] as List<dynamic>)
          .map((e) => _TicketToSpeakModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      luma_event_id: json['luma_event_id'] as String?,
    );

Map<String, dynamic> _$OutpostModelToJson(OutpostModel instance) =>
    <String, dynamic>{
      'alarm_id': instance.alarm_id,
      'uuid': instance.uuid,
      'created_at': instance.created_at,
      'creator_joined': instance.creator_joined,
      'luma_event_id': instance.luma_event_id,
      'creator_user_name': instance.creator_user_name,
      'creator_user_uuid': instance.creator_user_uuid,
      'creator_user_image': instance.creator_user_image,
      'enter_type': instance.enter_type,
      'has_adult_content': instance.has_adult_content,
      'image': instance.image,
      'invites': instance.invites,
      'is_archived': instance.is_archived,
      'is_recordable': instance.is_recordable,
      'last_active_at': instance.last_active_at,
      'members': instance.members,
      'members_count': instance.members_count,
      'name': instance.name,
      'scheduled_for': instance.scheduled_for,
      'speak_type': instance.speak_type,
      'subject': instance.subject,
      'tags': instance.tags,
      'tickets_to_enter': instance.tickets_to_enter,
      'tickets_to_speak': instance.tickets_to_speak,
    };

OutpostMember _$OutpostMemberFromJson(Map<String, dynamic> json) =>
    OutpostMember(
      address: json['address'] as String,
      can_speak: json['can_speak'] as String,
      uuid: json['uuid'] as String,
      aptos_address: json['aptos_address'] as String,
      external_wallet_address: json['external_wallet_address'] as String?,
    );

Map<String, dynamic> _$OutpostMemberToJson(OutpostMember instance) =>
    <String, dynamic>{
      'address': instance.address,
      'can_speak': instance.can_speak,
      'uuid': instance.uuid,
      'aptos_address': instance.aptos_address,
      'external_wallet_address': instance.external_wallet_address,
    };

_TicketToEnterModel _$TicketToEnterModelFromJson(Map<String, dynamic> json) =>
    _TicketToEnterModel(
      access_type: json['access_type'] as String,
      address: json['address'] as String,
      user_uuid: json['user_uuid'] as String,
    );

Map<String, dynamic> _$TicketToEnterModelToJson(_TicketToEnterModel instance) =>
    <String, dynamic>{
      'access_type': instance.access_type,
      'address': instance.address,
      'user_uuid': instance.user_uuid,
    };

_TicketToSpeakModel _$TicketToSpeakModelFromJson(Map<String, dynamic> json) =>
    _TicketToSpeakModel(
      access_type: json['access_type'] as String,
      address: json['address'] as String,
      user_uuid: json['user_uuid'] as String,
    );

Map<String, dynamic> _$TicketToSpeakModelToJson(_TicketToSpeakModel instance) =>
    <String, dynamic>{
      'access_type': instance.access_type,
      'address': instance.address,
      'user_uuid': instance.user_uuid,
    };

_InviteModel _$InviteModelFromJson(Map<String, dynamic> json) => _InviteModel(
      invitee_uuid: json['invitee_uuid'] as String,
      can_speak: json['can_speak'] as String,
    );

Map<String, dynamic> _$InviteModelToJson(_InviteModel instance) =>
    <String, dynamic>{
      'invitee_uuid': instance.invitee_uuid,
      'can_speak': instance.can_speak,
    };
