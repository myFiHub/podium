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
  bool? is_over_18;
  int? referrals_count;
  final String? referrer_user_uuid;
  final Map<String, double>? incomes;

  final double received_boo_amount;
  final int received_boo_count;
  final double received_cheer_amount;
  final int received_cheer_count;
  final int remaining_referrals_count;
  final double sent_boo_amount;
  final int sent_boo_count;
  final double sent_cheer_amount;
  final int sent_cheer_count;

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
    this.is_over_18,
    this.referrals_count = 0,
    this.remaining_referrals_count = 0,
    this.incomes,
    this.received_boo_amount = 0.0,
    this.received_boo_count = 0,
    this.received_cheer_amount = 0.0,
    this.received_cheer_count = 0,
    this.referrer_user_uuid,
    this.sent_boo_amount = 0.0,
    this.sent_boo_count = 0,
    this.sent_cheer_amount = 0.0,
    this.sent_cheer_count = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}
