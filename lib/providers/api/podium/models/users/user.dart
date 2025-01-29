import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class UserModel {
  final String address;
  final String uuid;
  final String? aptos_address;
  final String? email;
  String? external_wallet_address;
  final bool? followed_by_me;
  final int? followers_count;
  final int? followings_count;
  final String? image;
  final String? login_type;
  String? login_type_identifier;
    String? name;
  final String? referer_user_uuid;
  bool? is_over_18;

  String get defaultWalletAddress => external_wallet_address ?? address;

  UserModel({
    required this.address,
    required this.uuid,
    this.aptos_address,
    this.email,
    this.external_wallet_address,
    this.followed_by_me,
    this.followers_count,
    this.followings_count,
    this.image,
    this.login_type,
    this.login_type_identifier,
    this.name,
    this.referer_user_uuid,
    this.is_over_18,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}
