import 'package:json_annotation/json_annotation.dart';
part 'notificationModel.g.dart';

enum NotificationTypes {
  follow,
  invite,
}

@JsonSerializable()
class NotificationModel {
  final int created_at;
  final bool is_read;
  final String message;
  final FollowMetadata? followMetadata;
  final InviteMetadata? inviteMetadata;
  final NotificationTypes notification_type;
  final String uuid;

  const NotificationModel({
    required this.created_at,
    required this.is_read,
    required this.message,
    this.followMetadata,
    this.inviteMetadata,
    required this.notification_type,
    required this.uuid,
  });
  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);
}

@JsonSerializable()
class FollowMetadata {
  final String follower_uuid;
  final String follower_name;
  final String follower_image;
  const FollowMetadata({
    required this.follower_uuid,
    required this.follower_name,
    required this.follower_image,
  });
  factory FollowMetadata.fromJson(Map<String, dynamic> json) =>
      _$FollowMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$FollowMetadataToJson(this);
}

enum InviteType {
  enter,
  speak,
}

@JsonSerializable()
class InviteMetadata {
  final String inviter_uuid;
  final String inviter_name;
  final String inviter_image;
  final String outpost_uuid;
  final String outpost_name;
  final String outpost_image;
  final InviteType action;

  const InviteMetadata({
    required this.inviter_uuid,
    required this.inviter_name,
    required this.inviter_image,
    required this.outpost_uuid,
    required this.outpost_name,
    required this.outpost_image,
    required this.action,
  });

  factory InviteMetadata.fromJson(Map<String, dynamic> json) =>
      _$InviteMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$InviteMetadataToJson(this);
}
