import 'package:json_annotation/json_annotation.dart';

part 'podiumDefinedEntryAddress.g.dart';

@JsonSerializable()
class PodiumDefinedEntryAddress {
  final String address;
  final String type;
  static const String addressKey = 'usedBy';
  static const String typeKey = 'type';
  PodiumDefinedEntryAddress({
    required this.address,
    required this.type,
  });

  Map<String, dynamic> toJson() => _$PodiumDefinedEntryAddressToJson(this);
}
