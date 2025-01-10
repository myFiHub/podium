// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StarsArenaUser _$StarsArenaUserFromJson(Map<String, dynamic> json) =>
    StarsArenaUser(
      id: json['id'] as String,
      twitterName: json['twitterName'] as String,
      twitterPicture: json['twitterPicture'] as String,
      address: json['address'] as String,
      addressBeforeDynamicMigration:
          json['addressBeforeDynamicMigration'] as String?,
      dynamicAddress: json['dynamicAddress'] as String?,
      ethereumAddress: json['ethereumAddress'] as String?,
      solanaAddress: json['solanaAddress'] as String?,
      prevAddress: json['prevAddress'] as String?,
      addressConfirmed: json['addressConfirmed'] as bool,
      followerCount: (json['followerCount'] as num).toInt(),
      followingsCount: (json['followingsCount'] as num).toInt(),
      twitterFollowers: (json['twitterFollowers'] as num).toInt(),
      userConfirmed: json['userConfirmed'] as bool,
      twitterConfirmed: json['twitterConfirmed'] as bool,
      keyPrice: json['keyPrice'] as String?,
      lastKeyPrice: json['lastKeyPrice'] as String?,
    );

Map<String, dynamic> _$StarsArenaUserToJson(StarsArenaUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'twitterName': instance.twitterName,
      'twitterPicture': instance.twitterPicture,
      'address': instance.address,
      'addressBeforeDynamicMigration': instance.addressBeforeDynamicMigration,
      'dynamicAddress': instance.dynamicAddress,
      'ethereumAddress': instance.ethereumAddress,
      'solanaAddress': instance.solanaAddress,
      'prevAddress': instance.prevAddress,
      'keyPrice': instance.keyPrice,
      'lastKeyPrice': instance.lastKeyPrice,
      'addressConfirmed': instance.addressConfirmed,
      'followerCount': instance.followerCount,
      'followingsCount': instance.followingsCount,
      'twitterFollowers': instance.twitterFollowers,
      'userConfirmed': instance.userConfirmed,
      'twitterConfirmed': instance.twitterConfirmed,
    };
