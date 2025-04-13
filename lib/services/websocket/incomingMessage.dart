import 'package:json_annotation/json_annotation.dart';

part 'incomingMessage.g.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum IncomingMessageType {
  @JsonValue("user.joined")
  userJoined,
  @JsonValue("user.left")
  userLeft,
  @JsonValue("user.liked")
  userLiked,
  @JsonValue("user.disliked")
  userDisliked,
  @JsonValue("user.booed")
  userBooed,
  @JsonValue("user.cheered")
  userCheered,
  @JsonValue("user.started_speaking")
  userStartedSpeaking,
  @JsonValue("user.stopped_speaking")
  userStoppedSpeaking,
  @JsonValue("remaining_time.updated")
  remainingTimeUpdated,
  @JsonValue("user.time_is_up")
  timeIsUp,
  @JsonValue("user.followed")
  follow,
  @JsonValue("user.invited")
  invite,
  @JsonValue("waitlist.updated")
  waitlistUpdated,
  @JsonValue("creator.joined")
  creatorJoined,
  @JsonValue("user.started_recording")
  userStartedRecording,
  @JsonValue("user.stopped_recording")
  userStoppedRecording,
}

@JsonSerializable()
class IncomingMessage {
  final IncomingMessageType name;
  final IncomingMessageData data;

  IncomingMessage({
    required this.name,
    required this.data,
  });

  factory IncomingMessage.fromJson(Map<String, dynamic> json) =>
      _$IncomingMessageFromJson(json);

  Map<String, dynamic> toJson() => _$IncomingMessageToJson(this);
}

@JsonSerializable()
class IncomingMessageData {
  final String? address;
  final String? uuid;
  final String? name;
  final String? image;
  final String? react_to_user_address;
  final String? outpost_uuid;
  final int? amount;
  final int? remaining_time;

  IncomingMessageData({
    this.address,
    this.uuid,
    this.name,
    this.image,
    this.react_to_user_address,
    this.amount,
    this.remaining_time,
    this.outpost_uuid,
  });

  factory IncomingMessageData.fromJson(Map<String, dynamic> json) =>
      _$IncomingMessageDataFromJson(json);
  Map<String, dynamic> toJson() => _$IncomingMessageDataToJson(this);
}
