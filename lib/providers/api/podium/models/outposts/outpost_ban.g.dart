// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outpost_ban.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OutpostBanInfo _$OutpostBanInfoFromJson(Map<String, dynamic> json) =>
    OutpostBanInfo(
      kind: json['kind'] as String,
      expires_at: (json['expires_at'] as num?)?.toInt(),
    );

Map<String, dynamic> _$OutpostBanInfoToJson(OutpostBanInfo instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'expires_at': instance.expires_at,
    };

OutpostBanItem _$OutpostBanItemFromJson(Map<String, dynamic> json) =>
    OutpostBanItem(
      user_uuid: json['user_uuid'] as String,
      name: json['name'] as String?,
      image: json['image'] as String?,
      address: json['address'] as String,
      aptos_address: json['aptos_address'] as String?,
      kind: json['kind'] as String,
      reason: json['reason'] as String?,
      expires_at: (json['expires_at'] as num?)?.toInt(),
      created_at: (json['created_at'] as num).toInt(),
      banned_by_user_uuid: json['banned_by_user_uuid'] as String,
      banned_by_user_name: json['banned_by_user_name'] as String?,
    );

Map<String, dynamic> _$OutpostBanItemToJson(OutpostBanItem instance) =>
    <String, dynamic>{
      'user_uuid': instance.user_uuid,
      'name': instance.name,
      'image': instance.image,
      'address': instance.address,
      'aptos_address': instance.aptos_address,
      'kind': instance.kind,
      'reason': instance.reason,
      'expires_at': instance.expires_at,
      'created_at': instance.created_at,
      'banned_by_user_uuid': instance.banned_by_user_uuid,
      'banned_by_user_name': instance.banned_by_user_name,
    };
