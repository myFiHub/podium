// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'podiumDefinedEntryAddress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PodiumDefinedEntryAddress _$PodiumDefinedEntryAddressFromJson(
        Map<String, dynamic> json) =>
    PodiumDefinedEntryAddress(
      handle: json['handle'] as String?,
      type: json['type'] as String,
      address: json['address'] as String?,
    );

Map<String, dynamic> _$PodiumDefinedEntryAddressToJson(
        PodiumDefinedEntryAddress instance) =>
    <String, dynamic>{
      'handle': instance.handle,
      'address': instance.address,
      'type': instance.type,
    };
