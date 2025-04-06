import 'package:json_annotation/json_annotation.dart';
part 'metadata.g.dart';

@JsonSerializable()
class PodiumAppMetadata {
  final bool force_update;
  final Movement_Aptos_Metadata movement_aptos_metadata;
  final bool referrals_enabled;
  final String va;
  final String version;
  final bool version_check;

  const PodiumAppMetadata({
    required this.force_update,
    required this.movement_aptos_metadata,
    required this.referrals_enabled,
    required this.va,
    required this.version,
    required this.version_check,
  });

  factory PodiumAppMetadata.fromJson(Map<String, dynamic> json) =>
      _$PodiumAppMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$PodiumAppMetadataToJson(this);
}

@JsonSerializable()
class Movement_Aptos_Metadata {
  final String chain_id;
  final String cheer_boo_address;
  final String name;
  final String podium_protocol_address;
  final String rpc_url;

  const Movement_Aptos_Metadata({
    required this.chain_id,
    required this.cheer_boo_address,
    required this.name,
    required this.podium_protocol_address,
    required this.rpc_url,
  });
  factory Movement_Aptos_Metadata.fromJson(Map<String, dynamic> json) =>
      _$Movement_Aptos_MetadataFromJson(json);
  Map<String, dynamic> toJson() => _$Movement_Aptos_MetadataToJson(this);
}
