// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'additionalDataForLogin.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdditionalDataForLogin _$AdditionalDataForLoginFromJson(
        Map<String, dynamic> json) =>
    AdditionalDataForLogin(
      email: json['email'] as String?,
      name: json['name'] as String?,
      image: json['image'] as String?,
      loginType: json['loginType'] as String?,
    );

Map<String, dynamic> _$AdditionalDataForLoginToJson(
        AdditionalDataForLogin instance) =>
    <String, dynamic>{
      'email': instance.email,
      'name': instance.name,
      'image': instance.image,
      'loginType': instance.loginType,
    };
