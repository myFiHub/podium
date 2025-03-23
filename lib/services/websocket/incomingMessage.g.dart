// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'incomingMessage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IncomingMessage _$IncomingMessageFromJson(Map<String, dynamic> json) =>
    IncomingMessage(
      name: $enumDecode(_$IncomingMessageTypeEnumMap, json['name']),
      data: IncomingMessageData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$IncomingMessageToJson(IncomingMessage instance) =>
    <String, dynamic>{
      'name': _$IncomingMessageTypeEnumMap[instance.name]!,
      'data': instance.data,
    };

const _$IncomingMessageTypeEnumMap = {
  IncomingMessageType.userJoined: 'user.joined',
  IncomingMessageType.userLeft: 'user.left',
  IncomingMessageType.userLiked: 'user.liked',
  IncomingMessageType.userDisliked: 'user.disliked',
  IncomingMessageType.userBooed: 'user.booed',
  IncomingMessageType.userCheered: 'user.cheered',
  IncomingMessageType.userStartedSpeaking: 'user.started_speaking',
  IncomingMessageType.userStoppedSpeaking: 'user.stopped_speaking',
  IncomingMessageType.remainingTimeUpdated: 'remaining_time.updated',
  IncomingMessageType.timeIsUp: 'user.time_is_up',
};

IncomingMessageData _$IncomingMessageDataFromJson(Map<String, dynamic> json) =>
    IncomingMessageData(
      address: json['address'] as String?,
      uuid: json['uuid'] as String?,
      name: json['name'] as String?,
      image: json['image'] as String?,
      react_to_user_address: json['react_to_user_address'] as String?,
      amount: (json['amount'] as num?)?.toInt(),
      remaining_time: (json['remaining_time'] as num?)?.toInt(),
    );

Map<String, dynamic> _$IncomingMessageDataToJson(
        IncomingMessageData instance) =>
    <String, dynamic>{
      'address': instance.address,
      'uuid': instance.uuid,
      'name': instance.name,
      'image': instance.image,
      'react_to_user_address': instance.react_to_user_address,
      'amount': instance.amount,
      'remaining_time': instance.remaining_time,
    };
