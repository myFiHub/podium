// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'myUserDataResponse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MyUserDataResponse _$MyUserDataResponseFromJson(Map<String, dynamic> json) =>
    MyUserDataResponse(
      json['address'] as String,
      json['aptosAddress'] as String?,
      json['email'] as String?,
      json['externalWalletAddress'] as String?,
      json['image'] as String?,
      json['name'] as String?,
      json['uuid'] as String,
    );

Map<String, dynamic> _$MyUserDataResponseToJson(MyUserDataResponse instance) =>
    <String, dynamic>{
      'address': instance.address,
      'aptosAddress': instance.aptosAddress,
      'email': instance.email,
      'externalWalletAddress': instance.externalWalletAddress,
      'image': instance.image,
      'name': instance.name,
      'uuid': instance.uuid,
    };
