// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outgoingMessage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WsOutgoingMessage _$WsOutgoingMessageFromJson(Map<String, dynamic> json) =>
    WsOutgoingMessage(
      messageType:
          $enumDecode(_$OutpostEventTypeEnumsEnumMap, json['messageType']),
      outpostUuid: json['outpostUuid'] as String,
      data: json['data'] == null
          ? null
          : WsOutgoingMessageData.fromJson(
              json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$WsOutgoingMessageToJson(WsOutgoingMessage instance) =>
    <String, dynamic>{
      'messageType': _$OutpostEventTypeEnumsEnumMap[instance.messageType]!,
      'outpostUuid': instance.outpostUuid,
      'data': instance.data,
    };

const _$OutpostEventTypeEnumsEnumMap = {
  OutgoingMessageTypeEnums.join: 'join',
  OutgoingMessageTypeEnums.leave: 'leave',
  OutgoingMessageTypeEnums.boo: 'boo',
  OutgoingMessageTypeEnums.cheer: 'cheer',
  OutgoingMessageTypeEnums.like: 'like',
  OutgoingMessageTypeEnums.dislike: 'dislike',
  OutgoingMessageTypeEnums.start_speaking: 'start_speaking',
  OutgoingMessageTypeEnums.stop_speaking: 'stop_speaking',
};

WsOutgoingMessageData _$WsOutgoingMessageDataFromJson(
        Map<String, dynamic> json) =>
    WsOutgoingMessageData(
      amount: (json['amount'] as num?)?.toDouble(),
      reactToUserAddress: json['reactToUserAddress'] as String,
    );

Map<String, dynamic> _$WsOutgoingMessageDataToJson(
        WsOutgoingMessageData instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'reactToUserAddress': instance.reactToUserAddress,
    };
