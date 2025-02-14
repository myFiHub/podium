// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notificationModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationModel _$NotificationModelFromJson(Map<String, dynamic> json) =>
    NotificationModel(
      created_at: (json['created_at'] as num).toInt(),
      is_read: json['is_read'] as bool,
      message: json['message'] as String,
      metadata: json['metadata'] as String,
      notification_type: json['notification_type'] as String,
      uuid: json['uuid'] as String,
    );

Map<String, dynamic> _$NotificationModelToJson(NotificationModel instance) =>
    <String, dynamic>{
      'created_at': instance.created_at,
      'is_read': instance.is_read,
      'message': instance.message,
      'metadata': instance.metadata,
      'notification_type': instance.notification_type,
      'uuid': instance.uuid,
    };
