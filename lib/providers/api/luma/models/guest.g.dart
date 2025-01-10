// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GuestModel _$GuestModelFromJson(Map<String, dynamic> json) => GuestModel(
      api_id: json['api_id'] as String,
      guest: GuestDataModel.fromJson(json['guest'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GuestModelToJson(GuestModel instance) =>
    <String, dynamic>{
      'api_id': instance.api_id,
      'guest': instance.guest,
    };

GuestDataModel _$GuestDataModelFromJson(Map<String, dynamic> json) =>
    GuestDataModel(
      api_id: json['api_id'] as String,
      approval_status: json['approval_status'] as String,
      registered_at: json['registered_at'] as String,
      user_api_id: json['user_api_id'] as String,
      user_name: json['user_name'] as String?,
      user_email: json['user_email'] as String,
    );

Map<String, dynamic> _$GuestDataModelToJson(GuestDataModel instance) =>
    <String, dynamic>{
      'api_id': instance.api_id,
      'approval_status': instance.approval_status,
      'registered_at': instance.registered_at,
      'user_api_id': instance.user_api_id,
      'user_name': instance.user_name,
      'user_email': instance.user_email,
    };
