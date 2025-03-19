import 'package:json_annotation/json_annotation.dart';

part 'outgoingMessage.g.dart';

enum OutgoingMessageTypeEnums {
  join,
  leave,
  boo,
  cheer,
  like,
  dislike,
  start_speaking,
  stop_speaking,
}

@JsonSerializable()
class WsOutgoingMessage {
  final OutgoingMessageTypeEnums message_type;
  final String outpost_uuid;
  final WsOutgoingMessageData? data;

  WsOutgoingMessage(
      {required this.message_type, required this.outpost_uuid, this.data});

  factory WsOutgoingMessage.fromJson(Map<String, dynamic> json) =>
      _$WsOutgoingMessageFromJson(json);

  Map<String, dynamic> toJson() => _$WsOutgoingMessageToJson(this);
}

@JsonSerializable()
class WsOutgoingMessageData {
  final double? amount;
  final String react_to_user_address;

  WsOutgoingMessageData(
      {required this.amount, required this.react_to_user_address});

  factory WsOutgoingMessageData.fromJson(Map<String, dynamic> json) =>
      _$WsOutgoingMessageDataFromJson(json);
  Map<String, dynamic> toJson() => _$WsOutgoingMessageDataToJson(this);
}
