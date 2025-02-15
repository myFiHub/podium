// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notificationModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationModel _$NotificationModelFromJson(Map<String, dynamic> json) =>
    NotificationModel(
      created_at: (json['created_at'] as num).toInt(),
      is_read: json['is_read'] as bool,
      message: json['message'] as String,
      followMetadata: json['followMetadata'] == null
          ? null
          : FollowMetadata.fromJson(
              json['followMetadata'] as Map<String, dynamic>),
      inviteMetadata: json['inviteMetadata'] == null
          ? null
          : InviteMetadata.fromJson(
              json['inviteMetadata'] as Map<String, dynamic>),
      notification_type:
          $enumDecode(_$NotificationTypesEnumMap, json['notification_type']),
      uuid: json['uuid'] as String,
    );

Map<String, dynamic> _$NotificationModelToJson(NotificationModel instance) =>
    <String, dynamic>{
      'created_at': instance.created_at,
      'is_read': instance.is_read,
      'message': instance.message,
      'followMetadata': instance.followMetadata,
      'inviteMetadata': instance.inviteMetadata,
      'notification_type':
          _$NotificationTypesEnumMap[instance.notification_type]!,
      'uuid': instance.uuid,
    };

const _$NotificationTypesEnumMap = {
  NotificationTypes.follow: 'follow',
  NotificationTypes.invite: 'invite',
};

FollowMetadata _$FollowMetadataFromJson(Map<String, dynamic> json) =>
    FollowMetadata(
      follower_uuid: json['follower_uuid'] as String,
      follower_name: json['follower_name'] as String,
      follower_image: json['follower_image'] as String,
    );

Map<String, dynamic> _$FollowMetadataToJson(FollowMetadata instance) =>
    <String, dynamic>{
      'follower_uuid': instance.follower_uuid,
      'follower_name': instance.follower_name,
      'follower_image': instance.follower_image,
    };

InviteMetadata _$InviteMetadataFromJson(Map<String, dynamic> json) =>
    InviteMetadata(
      inviter_uuid: json['inviter_uuid'] as String,
      inviter_name: json['inviter_name'] as String,
      inviter_image: json['inviter_image'] as String,
      outpost_uuid: json['outpost_uuid'] as String,
      outpost_name: json['outpost_name'] as String,
      outpost_image: json['outpost_image'] as String,
      action: $enumDecode(_$InviteTypeEnumMap, json['action']),
    );

Map<String, dynamic> _$InviteMetadataToJson(InviteMetadata instance) =>
    <String, dynamic>{
      'inviter_uuid': instance.inviter_uuid,
      'inviter_name': instance.inviter_name,
      'inviter_image': instance.inviter_image,
      'outpost_uuid': instance.outpost_uuid,
      'outpost_name': instance.outpost_name,
      'outpost_image': instance.outpost_image,
      'action': _$InviteTypeEnumMap[instance.action]!,
    };

const _$InviteTypeEnumMap = {
  InviteType.enter: 'enter',
  InviteType.speak: 'speak',
};
