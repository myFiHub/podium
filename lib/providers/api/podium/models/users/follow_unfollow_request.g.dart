// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_unfollow_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FollowUnfollowRequest _$FollowUnfollowRequestFromJson(
        Map<String, dynamic> json) =>
    FollowUnfollowRequest(
      uuid: json['uuid'] as String,
      action: $enumDecode(_$FollowUnfollowActionEnumMap, json['action']),
    );

Map<String, dynamic> _$FollowUnfollowRequestToJson(
        FollowUnfollowRequest instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'action': _$FollowUnfollowActionEnumMap[instance.action]!,
    };

const _$FollowUnfollowActionEnumMap = {
  FollowUnfollowAction.follow: 'follow',
  FollowUnfollowAction.unfollow: 'unfollow',
};
