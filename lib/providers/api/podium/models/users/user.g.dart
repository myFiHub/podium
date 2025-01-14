// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      address: json['address'] as String,
      uuid: json['uuid'] as String,
      aptos_address: json['aptos_address'] as String?,
      email: json['email'] as String?,
      external_wallet_address: json['external_wallet_address'] as String?,
      followed_by_me: json['followed_by_me'] as bool?,
      followers_count: (json['followers_count'] as num?)?.toInt(),
      followings_count: (json['followings_count'] as num?)?.toInt(),
      image: json['image'] as String?,
      login_type: json['login_type'] as String?,
      login_type_identifier: json['login_type_identifier'] as String?,
      name: json['name'] as String?,
      referer_user_uuid: json['referer_user_uuid'] as String?,
      is_over_18: json['is_over_18'] as bool?,
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'address': instance.address,
      'uuid': instance.uuid,
      'aptos_address': instance.aptos_address,
      'email': instance.email,
      'external_wallet_address': instance.external_wallet_address,
      'followed_by_me': instance.followed_by_me,
      'followers_count': instance.followers_count,
      'followings_count': instance.followings_count,
      'image': instance.image,
      'login_type': instance.login_type,
      'login_type_identifier': instance.login_type_identifier,
      'name': instance.name,
      'referer_user_uuid': instance.referer_user_uuid,
      'is_over_18': instance.is_over_18,
    };
