// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'liveData.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LiveMemberCWProxy {
  LiveMember address(String address);

  LiveMember can_speak(bool can_speak);

  LiveMember feedbacks(List<FeedbackModel> feedbacks);

  LiveMember image(String? image);

  LiveMember is_present(bool is_present);

  LiveMember is_speaking(bool is_speaking);

  LiveMember name(String? name);

  LiveMember reactions(List<UserReaction> reactions);

  LiveMember remaining_time(int remaining_time);

  LiveMember uuid(String uuid);

  LiveMember last_speaked_at_timestamp(int? last_speaked_at_timestamp);

  LiveMember aptos_address(String aptos_address);

  LiveMember external_wallet_address(String? external_wallet_address);

  LiveMember followed_by_me(bool? followed_by_me);

  LiveMember is_recording(bool is_recording);

  LiveMember joined_at(int joined_at);

  LiveMember primary_aptos_address(String? primary_aptos_address);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `LiveMember(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LiveMember(...).copyWith(id: 12, name: "My name")
  /// ```
  LiveMember call({
    String address,
    bool can_speak,
    List<FeedbackModel> feedbacks,
    String? image,
    bool is_present,
    bool is_speaking,
    String? name,
    List<UserReaction> reactions,
    int remaining_time,
    String uuid,
    int? last_speaked_at_timestamp,
    String aptos_address,
    String? external_wallet_address,
    bool? followed_by_me,
    bool is_recording,
    int joined_at,
    String? primary_aptos_address,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLiveMember.copyWith(...)` or call `instanceOfLiveMember.copyWith.fieldName(value)` for a single field.
class _$LiveMemberCWProxyImpl implements _$LiveMemberCWProxy {
  const _$LiveMemberCWProxyImpl(this._value);

  final LiveMember _value;

  @override
  LiveMember address(String address) => call(address: address);

  @override
  LiveMember can_speak(bool can_speak) => call(can_speak: can_speak);

  @override
  LiveMember feedbacks(List<FeedbackModel> feedbacks) =>
      call(feedbacks: feedbacks);

  @override
  LiveMember image(String? image) => call(image: image);

  @override
  LiveMember is_present(bool is_present) => call(is_present: is_present);

  @override
  LiveMember is_speaking(bool is_speaking) => call(is_speaking: is_speaking);

  @override
  LiveMember name(String? name) => call(name: name);

  @override
  LiveMember reactions(List<UserReaction> reactions) =>
      call(reactions: reactions);

  @override
  LiveMember remaining_time(int remaining_time) =>
      call(remaining_time: remaining_time);

  @override
  LiveMember uuid(String uuid) => call(uuid: uuid);

  @override
  LiveMember last_speaked_at_timestamp(int? last_speaked_at_timestamp) =>
      call(last_speaked_at_timestamp: last_speaked_at_timestamp);

  @override
  LiveMember aptos_address(String aptos_address) =>
      call(aptos_address: aptos_address);

  @override
  LiveMember external_wallet_address(String? external_wallet_address) =>
      call(external_wallet_address: external_wallet_address);

  @override
  LiveMember followed_by_me(bool? followed_by_me) =>
      call(followed_by_me: followed_by_me);

  @override
  LiveMember is_recording(bool is_recording) =>
      call(is_recording: is_recording);

  @override
  LiveMember joined_at(int joined_at) => call(joined_at: joined_at);

  @override
  LiveMember primary_aptos_address(String? primary_aptos_address) =>
      call(primary_aptos_address: primary_aptos_address);

  @override

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `LiveMember(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LiveMember(...).copyWith(id: 12, name: "My name")
  /// ```
  LiveMember call({
    Object? address = const $CopyWithPlaceholder(),
    Object? can_speak = const $CopyWithPlaceholder(),
    Object? feedbacks = const $CopyWithPlaceholder(),
    Object? image = const $CopyWithPlaceholder(),
    Object? is_present = const $CopyWithPlaceholder(),
    Object? is_speaking = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? reactions = const $CopyWithPlaceholder(),
    Object? remaining_time = const $CopyWithPlaceholder(),
    Object? uuid = const $CopyWithPlaceholder(),
    Object? last_speaked_at_timestamp = const $CopyWithPlaceholder(),
    Object? aptos_address = const $CopyWithPlaceholder(),
    Object? external_wallet_address = const $CopyWithPlaceholder(),
    Object? followed_by_me = const $CopyWithPlaceholder(),
    Object? is_recording = const $CopyWithPlaceholder(),
    Object? joined_at = const $CopyWithPlaceholder(),
    Object? primary_aptos_address = const $CopyWithPlaceholder(),
  }) {
    return LiveMember(
      address: address == const $CopyWithPlaceholder() || address == null
          ? _value.address
          // ignore: cast_nullable_to_non_nullable
          : address as String,
      can_speak: can_speak == const $CopyWithPlaceholder() || can_speak == null
          ? _value.can_speak
          // ignore: cast_nullable_to_non_nullable
          : can_speak as bool,
      feedbacks: feedbacks == const $CopyWithPlaceholder() || feedbacks == null
          ? _value.feedbacks
          // ignore: cast_nullable_to_non_nullable
          : feedbacks as List<FeedbackModel>,
      image: image == const $CopyWithPlaceholder()
          ? _value.image
          // ignore: cast_nullable_to_non_nullable
          : image as String?,
      is_present:
          is_present == const $CopyWithPlaceholder() || is_present == null
              ? _value.is_present
              // ignore: cast_nullable_to_non_nullable
              : is_present as bool,
      is_speaking:
          is_speaking == const $CopyWithPlaceholder() || is_speaking == null
              ? _value.is_speaking
              // ignore: cast_nullable_to_non_nullable
              : is_speaking as bool,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String?,
      reactions: reactions == const $CopyWithPlaceholder() || reactions == null
          ? _value.reactions
          // ignore: cast_nullable_to_non_nullable
          : reactions as List<UserReaction>,
      remaining_time: remaining_time == const $CopyWithPlaceholder() ||
              remaining_time == null
          ? _value.remaining_time
          // ignore: cast_nullable_to_non_nullable
          : remaining_time as int,
      uuid: uuid == const $CopyWithPlaceholder() || uuid == null
          ? _value.uuid
          // ignore: cast_nullable_to_non_nullable
          : uuid as String,
      last_speaked_at_timestamp:
          last_speaked_at_timestamp == const $CopyWithPlaceholder()
              ? _value.last_speaked_at_timestamp
              // ignore: cast_nullable_to_non_nullable
              : last_speaked_at_timestamp as int?,
      aptos_address:
          aptos_address == const $CopyWithPlaceholder() || aptos_address == null
              ? _value.aptos_address
              // ignore: cast_nullable_to_non_nullable
              : aptos_address as String,
      external_wallet_address:
          external_wallet_address == const $CopyWithPlaceholder()
              ? _value.external_wallet_address
              // ignore: cast_nullable_to_non_nullable
              : external_wallet_address as String?,
      followed_by_me: followed_by_me == const $CopyWithPlaceholder()
          ? _value.followed_by_me
          // ignore: cast_nullable_to_non_nullable
          : followed_by_me as bool?,
      is_recording:
          is_recording == const $CopyWithPlaceholder() || is_recording == null
              ? _value.is_recording
              // ignore: cast_nullable_to_non_nullable
              : is_recording as bool,
      joined_at: joined_at == const $CopyWithPlaceholder() || joined_at == null
          ? _value.joined_at
          // ignore: cast_nullable_to_non_nullable
          : joined_at as int,
      primary_aptos_address:
          primary_aptos_address == const $CopyWithPlaceholder()
              ? _value.primary_aptos_address
              // ignore: cast_nullable_to_non_nullable
              : primary_aptos_address as String?,
    );
  }
}

extension $LiveMemberCopyWith on LiveMember {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLiveMember.copyWith(...)` or `instanceOfLiveMember.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LiveMemberCWProxy get copyWith => _$LiveMemberCWProxyImpl(this);
}

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
      feedbacks: (json['feedbacks'] as List<dynamic>?)
              ?.map((e) => FeedbackModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      image: json['image'] as String? ?? '',
      is_present: json['is_present'] as bool? ?? false,
      is_speaking: json['is_speaking'] as bool? ?? false,
      name: json['name'] as String? ?? '',
      reactions: (json['reactions'] as List<dynamic>?)
              ?.map((e) => UserReaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      remaining_time: (json['remaining_time'] as num?)?.toInt() ?? 0,
      uuid: json['uuid'] as String,
      last_speaked_at_timestamp:
          (json['last_speaked_at_timestamp'] as num?)?.toInt(),
      aptos_address: json['aptos_address'] as String,
      external_wallet_address: json['external_wallet_address'] as String?,
      followed_by_me: json['followed_by_me'] as bool?,
      is_recording: json['is_recording'] as bool? ?? false,
      joined_at: (json['joined_at'] as num?)?.toInt() ?? 0,
      primary_aptos_address: json['primary_aptos_address'] as String?,
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
      'followed_by_me': instance.followed_by_me,
      'is_recording': instance.is_recording,
      'joined_at': instance.joined_at,
      'primary_aptos_address': instance.primary_aptos_address,
    };

FeedbackModel _$FeedbackModelFromJson(Map<String, dynamic> json) =>
    FeedbackModel(
      feedback_type: json['feedback_type'] as String,
      time: json['time'] as String,
      user_address: json['user_address'] as String,
    );

Map<String, dynamic> _$FeedbackModelToJson(FeedbackModel instance) =>
    <String, dynamic>{
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
