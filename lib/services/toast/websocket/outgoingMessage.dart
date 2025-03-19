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
  final OutgoingMessageTypeEnums messageType;
  final String outpostUuid;
  final WsOutgoingMessageData? data;

  WsOutgoingMessage(
      {required this.messageType, required this.outpostUuid, this.data});

  factory WsOutgoingMessage.fromJson(Map<String, dynamic> json) =>
      _$WsOutgoingMessageFromJson(json);

  Map<String, dynamic> toJson() => _$WsOutgoingMessageToJson(this);
}

@JsonSerializable()
class WsOutgoingMessageData {
  final double? amount;
  final String reactToUserAddress;

  WsOutgoingMessageData(
      {required this.amount, required this.reactToUserAddress});

  factory WsOutgoingMessageData.fromJson(Map<String, dynamic> json) =>
      _$WsOutgoingMessageDataFromJson(json);
  Map<String, dynamic> toJson() => _$WsOutgoingMessageDataToJson(this);
}
