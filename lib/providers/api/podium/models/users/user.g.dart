// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      address: json['address'] as String,
      uuid: json['uuid'] as String,
      aptos_address: json['aptos_address'] as String?,
      email: json['email'] as String?,
      external_wallet_address: json['external_wallet_address'] as String?,
      followed_by_me: json['followed_by_me'] as bool?,
      followers_count: (json['followers_count'] as num?)?.toInt(),
      followings_count: (json['followings_count'] as num?)?.toInt(),
      image: json['image'] as String?,
      login_type: json['login_type'] as String?,
      login_type_identifier: json['login_type_identifier'] as String?,
      name: json['name'] as String?,
      is_over_18: json['is_over_18'] as bool?,
      referrals_count: (json['referrals_count'] as num?)?.toInt(),
      incomes: (json['incomes'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      received_boo_amount:
          (json['received_boo_amount'] as num?)?.toDouble() ?? 0.0,
      received_boo_count: (json['received_boo_count'] as num?)?.toInt() ?? 0,
      received_cheer_amount:
          (json['received_cheer_amount'] as num?)?.toDouble() ?? 0.0,
      received_cheer_count:
          (json['received_cheer_count'] as num?)?.toInt() ?? 0,
      referrer_user_uuid: json['referrer_user_uuid'] as String?,
      remaining_referrals_count:
          (json['remaining_referrals_count'] as num?)?.toInt() ?? 0,
      sent_boo_amount: (json['sent_boo_amount'] as num?)?.toDouble() ?? 0.0,
      sent_boo_count: (json['sent_boo_count'] as num?)?.toInt() ?? 0,
      sent_cheer_amount: (json['sent_cheer_amount'] as num?)?.toDouble() ?? 0.0,
      sent_cheer_count: (json['sent_cheer_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'address': instance.address,
      'uuid': instance.uuid,
      'aptos_address': instance.aptos_address,
      'email': instance.email,
      'external_wallet_address': instance.external_wallet_address,
      'followed_by_me': instance.followed_by_me,
      'followers_count': instance.followers_count,
      'followings_count': instance.followings_count,
      'image': instance.image,
      'login_type': instance.login_type,
      'login_type_identifier': instance.login_type_identifier,
      'name': instance.name,
      'is_over_18': instance.is_over_18,
      'referrals_count': instance.referrals_count,
      'referrer_user_uuid': instance.referrer_user_uuid,
      'incomes': instance.incomes,
      'received_boo_amount': instance.received_boo_amount,
      'received_boo_count': instance.received_boo_count,
      'received_cheer_amount': instance.received_cheer_amount,
      'received_cheer_count': instance.received_cheer_count,
      'remaining_referrals_count': instance.remaining_referrals_count,
      'sent_boo_amount': instance.sent_boo_amount,
      'sent_boo_count': instance.sent_boo_count,
      'sent_cheer_amount': instance.sent_cheer_amount,
      'sent_cheer_count': instance.sent_cheer_count,
    };
