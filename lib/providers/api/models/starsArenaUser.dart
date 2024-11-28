import 'package:json_annotation/json_annotation.dart';

part 'starsArenaUser.g.dart';

@JsonSerializable()
class StarsArenaUser {
  final String id;
  final String twitterName;
  final String twitterPicture;
  final String address;
  final String? addressBeforeDynamicMigration;
  final String? dynamicAddress;
  final String? ethereumAddress;
  final String? solanaAddress;
  final String? prevAddress;
  final String? keyPrice;
  String? lastKeyPrice;
  final bool addressConfirmed;
  final int followerCount;
  final int followingsCount;
  final int twitterFollowers;
  final bool userConfirmed;
  final bool twitterConfirmed;

  StarsArenaUser({
    required this.id,
    required this.twitterName,
    required this.twitterPicture,
    required this.address,
    this.addressBeforeDynamicMigration,
    this.dynamicAddress,
    this.ethereumAddress,
    this.solanaAddress,
    this.prevAddress,
    required this.addressConfirmed,
    required this.followerCount,
    required this.followingsCount,
    required this.twitterFollowers,
    required this.userConfirmed,
    required this.twitterConfirmed,
    this.keyPrice,
    this.lastKeyPrice,
  });
  get defaultAddress {
    return address;
  }

  get mainAddress {
    String? tmp = addressBeforeDynamicMigration;
    if (tmp == null) {
      tmp = dynamicAddress;
    }
    if (tmp == null) {
      tmp = address;
    }
    return tmp;
  }

// json annotation compatible tojson and fromjson
  factory StarsArenaUser.fromJson(Map<String, dynamic> json) =>
      _$StarsArenaUserFromJson(json);
  Map<String, dynamic> toJson() => _$StarsArenaUserToJson(this);
}
