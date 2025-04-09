// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follower.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FollowerModel _$FollowerModelFromJson(Map<String, dynamic> json) =>
    FollowerModel(
      address: json['address'] as String,
      followed_by_me: json['followed_by_me'] as bool,
      image: json['image'] as String,
      name: json['name'] as String,
      uuid: json['uuid'] as String,
    );

Map<String, dynamic> _$FollowerModelToJson(FollowerModel instance) =>
    <String, dynamic>{
      'address': instance.address,
      'followed_by_me': instance.followed_by_me,
      'image': instance.image,
      'name': instance.name,
      'uuid': instance.uuid,
    };
