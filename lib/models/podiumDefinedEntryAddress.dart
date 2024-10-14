import 'package:json_annotation/json_annotation.dart';

part 'podiumDefinedEntryAddress.g.dart';

@JsonSerializable()
class PodiumDefinedEntryAddress {
  final String? handle;
  final String? address;
  final String type;
  static const String handleKey = 'handle';
  static const String typeKey = 'type';
  PodiumDefinedEntryAddress({
    required this.handle,
    required this.type,
    required this.address,
  });

  Map<String, dynamic> toJson() => _$PodiumDefinedEntryAddressToJson(this);
}
