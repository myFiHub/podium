import 'package:json_annotation/json_annotation.dart';

part 'follow_unfollow_request.g.dart';

enum FollowUnfollowAction {
  follow,
  unfollow,
}

@JsonSerializable()
class FollowUnfollowRequest {
  final String uuid;
  final FollowUnfollowAction action;

  FollowUnfollowRequest({required this.uuid, required this.action});

  factory FollowUnfollowRequest.fromJson(Map<String, dynamic> json) =>
      _$FollowUnfollowRequestFromJson(json);

  Map<String, dynamic> toJson() => _$FollowUnfollowRequestToJson(this);
}
