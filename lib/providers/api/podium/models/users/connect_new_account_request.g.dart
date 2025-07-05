// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connect_new_account_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConnectNewAccountRequest _$ConnectNewAccountRequestFromJson(
        Map<String, dynamic> json) =>
    ConnectNewAccountRequest(
      aptos_address: json['aptos_address'] as String,
      current_address_signature: json['current_address_signature'] as String,
      image: json['image'] as String,
      login_type: json['login_type'] as String,
      login_type_identifier: json['login_type_identifier'] as String,
      new_address: json['new_address'] as String,
      new_address_signature: json['new_address_signature'] as String,
    );

Map<String, dynamic> _$ConnectNewAccountRequestToJson(
        ConnectNewAccountRequest instance) =>
    <String, dynamic>{
      'aptos_address': instance.aptos_address,
      'current_address_signature': instance.current_address_signature,
      'image': instance.image,
      'login_type': instance.login_type,
      'login_type_identifier': instance.login_type_identifier,
      'new_address': instance.new_address,
      'new_address_signature': instance.new_address_signature,
    };
