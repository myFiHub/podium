// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PodiumAppMetadata _$PodiumAppMetadataFromJson(Map<String, dynamic> json) =>
    PodiumAppMetadata(
      force_update: json['force_update'] as bool,
      movement_aptos_metadata: Movement_Aptos_Metadata.fromJson(
          json['movement_aptos_metadata'] as Map<String, dynamic>),
      referrals_enabled: json['referrals_enabled'] as bool,
      va: json['va'] as String,
      version: json['version'] as String,
      version_check: json['version_check'] as bool,
    );

Map<String, dynamic> _$PodiumAppMetadataToJson(PodiumAppMetadata instance) =>
    <String, dynamic>{
      'force_update': instance.force_update,
      'movement_aptos_metadata': instance.movement_aptos_metadata,
      'referrals_enabled': instance.referrals_enabled,
      'va': instance.va,
      'version': instance.version,
      'version_check': instance.version_check,
    };

Movement_Aptos_Metadata _$Movement_Aptos_MetadataFromJson(
        Map<String, dynamic> json) =>
    Movement_Aptos_Metadata(
      chain_id: json['chain_id'] as String,
      cheer_boo_address: json['cheer_boo_address'] as String,
      name: json['name'] as String,
      podium_protocol_address: json['podium_protocol_address'] as String,
      rpc_url: json['rpc_url'] as String,
    );

Map<String, dynamic> _$Movement_Aptos_MetadataToJson(
        Movement_Aptos_Metadata instance) =>
    <String, dynamic>{
      'chain_id': instance.chain_id,
      'cheer_boo_address': instance.cheer_boo_address,
      'name': instance.name,
      'podium_protocol_address': instance.podium_protocol_address,
      'rpc_url': instance.rpc_url,
    };
