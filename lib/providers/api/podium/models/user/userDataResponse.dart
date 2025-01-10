import 'package:json_annotation/json_annotation.dart';
part 'userDataResponse.g.dart';

@JsonSerializable()
class UserDataResponse {
  final String address;
  final bool followedByMe;
  final String image;
  final String name;
  final String uuid;

  UserDataResponse(
      this.address, this.followedByMe, this.image, this.name, this.uuid);

  factory UserDataResponse.fromJson(Map<String, dynamic> json) =>
      _$UserDataResponseFromJson(json);
  Map<String, dynamic> toJson() => _$UserDataResponseToJson(this);
}
