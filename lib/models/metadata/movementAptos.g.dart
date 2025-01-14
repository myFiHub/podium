// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movementAptos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MovementAptosMetadata _$MovementAptosMetadataFromJson(
        Map<String, dynamic> json) =>
    MovementAptosMetadata(
      chainId: json['chainId'] as String,
      rpcUrl: json['rpcUrl'] as String,
      name: json['name'] as String,
      podiumProtocolAddress: json['podiumProtocolAddress'] as String,
      cheerBooAddress: json['cheerBooAddress'] as String,
    );

Map<String, dynamic> _$MovementAptosMetadataToJson(
        MovementAptosMetadata instance) =>
    <String, dynamic>{
      'chainId': instance.chainId,
      'rpcUrl': instance.rpcUrl,
      'name': instance.name,
      'podiumProtocolAddress': instance.podiumProtocolAddress,
      'cheerBooAddress': instance.cheerBooAddress,
    };
