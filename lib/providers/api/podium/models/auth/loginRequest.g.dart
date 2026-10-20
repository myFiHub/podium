// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loginRequest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
      signature: json['signature'] as String,
      username: json['username'] as String,
      aptos_address: json['aptos_address'] as String,
      has_ticket: json['has_ticket'] as bool,
      timestamp: (json['timestamp'] as num).toInt(),
      login_type_identifier: json['login_type_identifier'] as String,
      referrer_user_uuid: json['referrer_user_uuid'] as String?,
      login_type: json['login_type'] as String,
    );

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{
      'signature': instance.signature,
      'username': instance.username,
      'aptos_address': instance.aptos_address,
      'has_ticket': instance.has_ticket,
      'timestamp': instance.timestamp,
      'login_type_identifier': instance.login_type_identifier,
      'login_type': instance.login_type,
      'referrer_user_uuid': instance.referrer_user_uuid,
    };
