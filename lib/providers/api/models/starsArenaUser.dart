import 'package:json_annotation/json_annotation.dart';

part 'starsArenaUser.g.dart';

@JsonSerializable()
class StarsArenaUser {
  final String id;
  final DateTime createdOn;
  final String twitterId;
  final String twitterHandle;
  final String twitterName;
  final String twitterPicture;
  final String lastLoginTwitterPicture;
  final String? bannerUrl;
  final String address;
  final String addressBeforeDynamicMigration;
  final String dynamicAddress;
  final String? ethereumAddress;
  final String? solanaAddress;
  final String prevAddress;
  final bool addressConfirmed;
  final String twitterDescription;
  final bool signedUp;
  final String subscriptionCurrency;
  final String? subscriptionCurrencyAddress;
  final String subscriptionPrice;
  final String keyPrice;
  final String lastKeyPrice;
  final int threadCount;
  final int followerCount;
  final int followingsCount;
  final int twitterFollowers;
  final bool subscriptionsEnabled;
  final bool userConfirmed;
  final bool twitterConfirmed;
  final int flag;
  final String ixHandle;
  final String? handle;

  StarsArenaUser({
    required this.id,
    required this.createdOn,
    required this.twitterId,
    required this.twitterHandle,
    required this.twitterName,
    required this.twitterPicture,
    required this.lastLoginTwitterPicture,
    this.bannerUrl,
    required this.address,
    required this.addressBeforeDynamicMigration,
    required this.dynamicAddress,
    this.ethereumAddress,
    this.solanaAddress,
    required this.prevAddress,
    required this.addressConfirmed,
    required this.twitterDescription,
    required this.signedUp,
    required this.subscriptionCurrency,
    this.subscriptionCurrencyAddress,
    required this.subscriptionPrice,
    required this.keyPrice,
    required this.lastKeyPrice,
    required this.threadCount,
    required this.followerCount,
    required this.followingsCount,
    required this.twitterFollowers,
    required this.subscriptionsEnabled,
    required this.userConfirmed,
    required this.twitterConfirmed,
    required this.flag,
    required this.ixHandle,
    this.handle,
  });
  get defaultAddress {
    return address;
  }

// json annotation compatible tojson and fromjson
  factory StarsArenaUser.fromJson(Map<String, dynamic> json) =>
      _$StarsArenaUserFromJson(json);
  Map<String, dynamic> toJson() => _$StarsArenaUserToJson(this);
}
