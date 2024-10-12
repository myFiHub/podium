// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'starsArenaUser.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StarsArenaUser _$StarsArenaUserFromJson(Map<String, dynamic> json) =>
    StarsArenaUser(
      id: json['id'] as String,
      createdOn: DateTime.parse(json['createdOn'] as String),
      twitterId: json['twitterId'] as String,
      twitterHandle: json['twitterHandle'] as String,
      twitterName: json['twitterName'] as String,
      twitterPicture: json['twitterPicture'] as String,
      lastLoginTwitterPicture: json['lastLoginTwitterPicture'] as String,
      bannerUrl: json['bannerUrl'] as String?,
      address: json['address'] as String,
      addressBeforeDynamicMigration:
          json['addressBeforeDynamicMigration'] as String,
      dynamicAddress: json['dynamicAddress'] as String,
      ethereumAddress: json['ethereumAddress'] as String?,
      solanaAddress: json['solanaAddress'] as String?,
      prevAddress: json['prevAddress'] as String,
      addressConfirmed: json['addressConfirmed'] as bool,
      twitterDescription: json['twitterDescription'] as String,
      signedUp: json['signedUp'] as bool,
      subscriptionCurrency: json['subscriptionCurrency'] as String,
      subscriptionCurrencyAddress:
          json['subscriptionCurrencyAddress'] as String?,
      subscriptionPrice: json['subscriptionPrice'] as String,
      keyPrice: json['keyPrice'] as String,
      lastKeyPrice: json['lastKeyPrice'] as String,
      threadCount: (json['threadCount'] as num).toInt(),
      followerCount: (json['followerCount'] as num).toInt(),
      followingsCount: (json['followingsCount'] as num).toInt(),
      twitterFollowers: (json['twitterFollowers'] as num).toInt(),
      subscriptionsEnabled: json['subscriptionsEnabled'] as bool,
      userConfirmed: json['userConfirmed'] as bool,
      twitterConfirmed: json['twitterConfirmed'] as bool,
      flag: (json['flag'] as num).toInt(),
      ixHandle: json['ixHandle'] as String,
      handle: json['handle'] as String?,
    );

Map<String, dynamic> _$StarsArenaUserToJson(StarsArenaUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'createdOn': instance.createdOn.toIso8601String(),
      'twitterId': instance.twitterId,
      'twitterHandle': instance.twitterHandle,
      'twitterName': instance.twitterName,
      'twitterPicture': instance.twitterPicture,
      'lastLoginTwitterPicture': instance.lastLoginTwitterPicture,
      'bannerUrl': instance.bannerUrl,
      'address': instance.address,
      'addressBeforeDynamicMigration': instance.addressBeforeDynamicMigration,
      'dynamicAddress': instance.dynamicAddress,
      'ethereumAddress': instance.ethereumAddress,
      'solanaAddress': instance.solanaAddress,
      'prevAddress': instance.prevAddress,
      'addressConfirmed': instance.addressConfirmed,
      'twitterDescription': instance.twitterDescription,
      'signedUp': instance.signedUp,
      'subscriptionCurrency': instance.subscriptionCurrency,
      'subscriptionCurrencyAddress': instance.subscriptionCurrencyAddress,
      'subscriptionPrice': instance.subscriptionPrice,
      'keyPrice': instance.keyPrice,
      'lastKeyPrice': instance.lastKeyPrice,
      'threadCount': instance.threadCount,
      'followerCount': instance.followerCount,
      'followingsCount': instance.followingsCount,
      'twitterFollowers': instance.twitterFollowers,
      'subscriptionsEnabled': instance.subscriptionsEnabled,
      'userConfirmed': instance.userConfirmed,
      'twitterConfirmed': instance.twitterConfirmed,
      'flag': instance.flag,
      'ixHandle': instance.ixHandle,
      'handle': instance.handle,
    };
