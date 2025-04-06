import 'package:json_annotation/json_annotation.dart';

part 'movementAptos.g.dart';

@JsonSerializable()
class MovementAptosMetadata {
  final String chainId;
  final String rpcUrl;
  final String name;
  final String podiumProtocolAddress;
  final String cheerBooAddress;

  MovementAptosMetadata({
    required this.chainId,
    required this.rpcUrl,
    required this.name,
    required this.podiumProtocolAddress,
    required this.cheerBooAddress,
  });

  factory MovementAptosMetadata.fromJson(Map<String, dynamic> json) =>
      _$MovementAptosMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$MovementAptosMetadataToJson(this);
}
