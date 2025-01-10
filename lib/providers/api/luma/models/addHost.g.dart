// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'addHost.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddHostModel _$AddHostModelFromJson(Map<String, dynamic> json) => AddHostModel(
      event_api_id: json['event_api_id'] as String?,
      email: json['email'] as String,
      access_level: json['access_level'] as String? ?? 'manager',
      is_visible: json['is_visible'] as bool? ?? true,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$AddHostModelToJson(AddHostModel instance) =>
    <String, dynamic>{
      'event_api_id': instance.event_api_id,
      'email': instance.email,
      'access_level': instance.access_level,
      'is_visible': instance.is_visible,
      'name': instance.name,
    };
