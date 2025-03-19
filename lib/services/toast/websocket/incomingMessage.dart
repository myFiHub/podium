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
}

@JsonSerializable()
class IncomingMessage {
  final IncomingMessageType name;
  final IncomingMessageData data;

  IncomingMessage({required this.name, required this.data});

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
  final int? amount;

  IncomingMessageData(
      {this.address,
      this.uuid,
      this.name,
      this.image,
      this.react_to_user_address,
      this.amount});

  factory IncomingMessageData.fromJson(Map<String, dynamic> json) =>
      _$IncomingMessageDataFromJson(json);
  Map<String, dynamic> toJson() => _$IncomingMessageDataToJson(this);
}
