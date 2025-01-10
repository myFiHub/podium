// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'userDataResponse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDataResponse _$UserDataResponseFromJson(Map<String, dynamic> json) =>
    UserDataResponse(
      json['address'] as String,
      json['followedByMe'] as bool,
      json['image'] as String,
      json['name'] as String,
      json['uuid'] as String,
    );

Map<String, dynamic> _$UserDataResponseToJson(UserDataResponse instance) =>
    <String, dynamic>{
      'address': instance.address,
      'followedByMe': instance.followedByMe,
      'image': instance.image,
      'name': instance.name,
      'uuid': instance.uuid,
    };
