// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'liveData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OutpostLiveData _$OutpostLiveDataFromJson(Map<String, dynamic> json) =>
    OutpostLiveData(
      members: (json['members'] as List<dynamic>)
          .map((e) => LiveMember.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OutpostLiveDataToJson(OutpostLiveData instance) =>
    <String, dynamic>{
      'members': instance.members,
    };

LiveMember _$LiveMemberFromJson(Map<String, dynamic> json) => LiveMember(
      address: json['address'] as String,
      can_speak: json['can_speak'] as bool,
      feedbacks: (json['feedbacks'] as List<dynamic>)
          .map((e) => Feedback.fromJson(e as Map<String, dynamic>))
          .toList(),
      image: json['image'] as String,
      is_present: json['is_present'] as bool,
      is_speaking: json['is_speaking'] as bool,
      name: json['name'] as String,
      reactions: (json['reactions'] as List<dynamic>)
          .map((e) => UserReaction.fromJson(e as Map<String, dynamic>))
          .toList(),
      remaining_time: (json['remaining_time'] as num).toInt(),
      uuid: json['uuid'] as String,
      last_speaked_at_timestamp:
          (json['last_speaked_at_timestamp'] as num?)?.toInt(),
      aptos_address: json['aptos_address'] as String,
      external_wallet_address: json['external_wallet_address'] as String?,
    );

Map<String, dynamic> _$LiveMemberToJson(LiveMember instance) =>
    <String, dynamic>{
      'address': instance.address,
      'can_speak': instance.can_speak,
      'feedbacks': instance.feedbacks,
      'image': instance.image,
      'is_present': instance.is_present,
      'is_speaking': instance.is_speaking,
      'name': instance.name,
      'reactions': instance.reactions,
      'remaining_time': instance.remaining_time,
      'last_speaked_at_timestamp': instance.last_speaked_at_timestamp,
      'aptos_address': instance.aptos_address,
      'external_wallet_address': instance.external_wallet_address,
      'uuid': instance.uuid,
    };

Feedback _$FeedbackFromJson(Map<String, dynamic> json) => Feedback(
      feedback_type: json['feedback_type'] as String,
      time: json['time'] as String,
      user_address: json['user_address'] as String,
    );

Map<String, dynamic> _$FeedbackToJson(Feedback instance) => <String, dynamic>{
      'feedback_type': instance.feedback_type,
      'time': instance.time,
      'user_address': instance.user_address,
    };

UserReaction _$UserReactionFromJson(Map<String, dynamic> json) => UserReaction(
      amount: (json['amount'] as num).toDouble(),
      reaction_type: json['reaction_type'] as String,
      time: json['time'] as String,
      user_address: json['user_address'] as String,
    );

Map<String, dynamic> _$UserReactionToJson(UserReaction instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'reaction_type': instance.reaction_type,
      'time': instance.time,
      'user_address': instance.user_address,
    };
