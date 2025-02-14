import 'package:json_annotation/json_annotation.dart';
part 'notificationModel.g.dart';

@JsonSerializable()
class NotificationModel {
  final int created_at;
  final bool is_read;
  final String message;
  final String metadata;
  final String notification_type;
  final String uuid;

  const NotificationModel({
    required this.created_at,
    required this.is_read,
    required this.message,
    required this.metadata,
    required this.notification_type,
    required this.uuid,
  });
  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);
}
