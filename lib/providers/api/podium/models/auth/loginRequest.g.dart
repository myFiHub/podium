// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loginRequest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
      signature: json['signature'] as String,
      username: json['username'] as String,
    );

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{
      'signature': instance.signature,
      'username': instance.username,
    };
