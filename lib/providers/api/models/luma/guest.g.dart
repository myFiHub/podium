// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GuestModel _$GuestModelFromJson(Map<String, dynamic> json) => GuestModel(
      api_id: json['api_id'] as String,
      data: GuestDataModel.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GuestModelToJson(GuestModel instance) =>
    <String, dynamic>{
      'api_id': instance.api_id,
      'data': instance.data,
    };

GuestDataModel _$GuestDataModelFromJson(Map<String, dynamic> json) =>
    GuestDataModel(
      api_id: json['api_id'] as String,
      approval_status: json['approval_status'] as String,
      registered_at: json['registered_at'] as String,
      invited_at: json['invited_at'] as String,
      checked_in_at: json['checked_in_at'] as String,
      joined_at: json['joined_at'] as String,
      user_api_id: json['user_api_id'] as String,
      created_at: json['created_at'] as String,
      user_name: json['user_name'] as String,
      user_email: json['user_email'] as String,
    );

Map<String, dynamic> _$GuestDataModelToJson(GuestDataModel instance) =>
    <String, dynamic>{
      'api_id': instance.api_id,
      'approval_status': instance.approval_status,
      'registered_at': instance.registered_at,
      'invited_at': instance.invited_at,
      'checked_in_at': instance.checked_in_at,
      'joined_at': instance.joined_at,
      'user_api_id': instance.user_api_id,
      'created_at': instance.created_at,
      'user_name': instance.user_name,
      'user_email': instance.user_email,
    };
