import 'package:json_annotation/json_annotation.dart';
part 'myUserDataResponse.g.dart';

@JsonSerializable()
class MyUserDataResponse {
  final String address;
  final String? aptosAddress;
  final String? email;
  final String? externalWalletAddress;
  final String? image;
  final String? name;
  final String uuid;

  MyUserDataResponse(this.address, this.aptosAddress, this.email,
      this.externalWalletAddress, this.image, this.name, this.uuid);

  factory MyUserDataResponse.fromJson(Map<String, dynamic> json) =>
      _$MyUserDataResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MyUserDataResponseToJson(this);
}
