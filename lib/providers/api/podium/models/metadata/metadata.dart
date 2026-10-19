import 'package:json_annotation/json_annotation.dart';
part 'metadata.g.dart';

@JsonSerializable()
class PodiumAppMetadata {
  final bool force_update;
  final MovementAptosMetadata movement_aptos_metadata;
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
class MovementAptosMetadata {
  final String chain_id;
  final String cheer_boo_address;
  final String name;
  final String podium_protocol_address;
  final String rpc_url;

  const MovementAptosMetadata({
    required this.chain_id,
    required this.cheer_boo_address,
    required this.name,
    required this.podium_protocol_address,
    required this.rpc_url,
  });
  factory MovementAptosMetadata.fromJson(Map<String, dynamic> json) =>
      _$MovementAptosMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$MovementAptosMetadataToJson(this);
}
