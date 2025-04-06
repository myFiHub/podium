// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outgoingMessage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WsOutgoingMessage _$WsOutgoingMessageFromJson(Map<String, dynamic> json) =>
    WsOutgoingMessage(
      message_type:
          $enumDecode(_$OutgoingMessageTypeEnumsEnumMap, json['message_type']),
      outpost_uuid: json['outpost_uuid'] as String,
      request_id: json['request_id'] as String?,
      data: json['data'] == null
          ? null
          : WsOutgoingMessageData.fromJson(
              json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$WsOutgoingMessageToJson(WsOutgoingMessage instance) =>
    <String, dynamic>{
      'message_type': _$OutgoingMessageTypeEnumsEnumMap[instance.message_type]!,
      'outpost_uuid': instance.outpost_uuid,
      'request_id': instance.request_id,
      'data': instance.data,
    };

const _$OutgoingMessageTypeEnumsEnumMap = {
  OutgoingMessageTypeEnums.join: 'join',
  OutgoingMessageTypeEnums.leave: 'leave',
  OutgoingMessageTypeEnums.boo: 'boo',
  OutgoingMessageTypeEnums.cheer: 'cheer',
  OutgoingMessageTypeEnums.like: 'like',
  OutgoingMessageTypeEnums.dislike: 'dislike',
  OutgoingMessageTypeEnums.start_speaking: 'start_speaking',
  OutgoingMessageTypeEnums.stop_speaking: 'stop_speaking',
  OutgoingMessageTypeEnums.wait_for_creator: 'wait_for_creator',
};

WsOutgoingMessageData _$WsOutgoingMessageDataFromJson(
        Map<String, dynamic> json) =>
    WsOutgoingMessageData(
      amount: (json['amount'] as num?)?.toDouble(),
      react_to_user_address: json['react_to_user_address'] as String,
      chain_id: (json['chain_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$WsOutgoingMessageDataToJson(
        WsOutgoingMessageData instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'react_to_user_address': instance.react_to_user_address,
      'chain_id': instance.chain_id,
    };
