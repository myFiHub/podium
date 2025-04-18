// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outpost.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$OutpostModelCWProxy {
  OutpostModel uuid(String uuid);

  OutpostModel created_at(int created_at);

  OutpostModel creator_joined(bool creator_joined);

  OutpostModel creator_user_name(String creator_user_name);

  OutpostModel creator_user_uuid(String creator_user_uuid);

  OutpostModel creator_user_image(String creator_user_image);

  OutpostModel enter_type(String enter_type);

  OutpostModel has_adult_content(bool has_adult_content);

  OutpostModel image(String image);

  OutpostModel invites(List<InviteModel>? invites);

  OutpostModel is_archived(bool is_archived);

  OutpostModel is_recordable(bool is_recordable);

  OutpostModel last_active_at(int last_active_at);

  OutpostModel members(List<LiveMember>? members);

  OutpostModel members_count(int? members_count);

  OutpostModel name(String name);

  OutpostModel scheduled_for(int scheduled_for);

  OutpostModel speak_type(String speak_type);

  OutpostModel subject(String subject);

  OutpostModel tags(List<String> tags);

  OutpostModel tickets_to_enter(List<_TicketToEnterModel>? tickets_to_enter);

  OutpostModel tickets_to_speak(List<_TicketToSpeakModel>? tickets_to_speak);

  OutpostModel luma_event_id(String? luma_event_id);

  OutpostModel i_am_member(bool i_am_member);

  OutpostModel online_users_count(int? online_users_count);

  OutpostModel reminder_minutes_before(int? reminder_minutes_before);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `OutpostModel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// OutpostModel(...).copyWith(id: 12, name: "My name")
  /// ````
  OutpostModel call({
    String uuid,
    int created_at,
    bool creator_joined,
    String creator_user_name,
    String creator_user_uuid,
    String creator_user_image,
    String enter_type,
    bool has_adult_content,
    String image,
    List<InviteModel>? invites,
    bool is_archived,
    bool is_recordable,
    int last_active_at,
    List<LiveMember>? members,
    int? members_count,
    String name,
    int scheduled_for,
    String speak_type,
    String subject,
    List<String> tags,
    List<_TicketToEnterModel>? tickets_to_enter,
    List<_TicketToSpeakModel>? tickets_to_speak,
    String? luma_event_id,
    bool i_am_member,
    int? online_users_count,
    int? reminder_minutes_before,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfOutpostModel.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfOutpostModel.copyWith.fieldName(...)`
class _$OutpostModelCWProxyImpl implements _$OutpostModelCWProxy {
  const _$OutpostModelCWProxyImpl(this._value);

  final OutpostModel _value;

  @override
  OutpostModel uuid(String uuid) => this(uuid: uuid);

  @override
  OutpostModel created_at(int created_at) => this(created_at: created_at);

  @override
  OutpostModel creator_joined(bool creator_joined) =>
      this(creator_joined: creator_joined);

  @override
  OutpostModel creator_user_name(String creator_user_name) =>
      this(creator_user_name: creator_user_name);

  @override
  OutpostModel creator_user_uuid(String creator_user_uuid) =>
      this(creator_user_uuid: creator_user_uuid);

  @override
  OutpostModel creator_user_image(String creator_user_image) =>
      this(creator_user_image: creator_user_image);

  @override
  OutpostModel enter_type(String enter_type) => this(enter_type: enter_type);

  @override
  OutpostModel has_adult_content(bool has_adult_content) =>
      this(has_adult_content: has_adult_content);

  @override
  OutpostModel image(String image) => this(image: image);

  @override
  OutpostModel invites(List<InviteModel>? invites) => this(invites: invites);

  @override
  OutpostModel is_archived(bool is_archived) => this(is_archived: is_archived);

  @override
  OutpostModel is_recordable(bool is_recordable) =>
      this(is_recordable: is_recordable);

  @override
  OutpostModel last_active_at(int last_active_at) =>
      this(last_active_at: last_active_at);

  @override
  OutpostModel members(List<LiveMember>? members) => this(members: members);

  @override
  OutpostModel members_count(int? members_count) =>
      this(members_count: members_count);

  @override
  OutpostModel name(String name) => this(name: name);

  @override
  OutpostModel scheduled_for(int scheduled_for) =>
      this(scheduled_for: scheduled_for);

  @override
  OutpostModel speak_type(String speak_type) => this(speak_type: speak_type);

  @override
  OutpostModel subject(String subject) => this(subject: subject);

  @override
  OutpostModel tags(List<String> tags) => this(tags: tags);

  @override
  OutpostModel tickets_to_enter(List<_TicketToEnterModel>? tickets_to_enter) =>
      this(tickets_to_enter: tickets_to_enter);

  @override
  OutpostModel tickets_to_speak(List<_TicketToSpeakModel>? tickets_to_speak) =>
      this(tickets_to_speak: tickets_to_speak);

  @override
  OutpostModel luma_event_id(String? luma_event_id) =>
      this(luma_event_id: luma_event_id);

  @override
  OutpostModel i_am_member(bool i_am_member) => this(i_am_member: i_am_member);

  @override
  OutpostModel online_users_count(int? online_users_count) =>
      this(online_users_count: online_users_count);

  @override
  OutpostModel reminder_minutes_before(int? reminder_minutes_before) =>
      this(reminder_minutes_before: reminder_minutes_before);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `OutpostModel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// OutpostModel(...).copyWith(id: 12, name: "My name")
  /// ````
  OutpostModel call({
    Object? uuid = const $CopyWithPlaceholder(),
    Object? created_at = const $CopyWithPlaceholder(),
    Object? creator_joined = const $CopyWithPlaceholder(),
    Object? creator_user_name = const $CopyWithPlaceholder(),
    Object? creator_user_uuid = const $CopyWithPlaceholder(),
    Object? creator_user_image = const $CopyWithPlaceholder(),
    Object? enter_type = const $CopyWithPlaceholder(),
    Object? has_adult_content = const $CopyWithPlaceholder(),
    Object? image = const $CopyWithPlaceholder(),
    Object? invites = const $CopyWithPlaceholder(),
    Object? is_archived = const $CopyWithPlaceholder(),
    Object? is_recordable = const $CopyWithPlaceholder(),
    Object? last_active_at = const $CopyWithPlaceholder(),
    Object? members = const $CopyWithPlaceholder(),
    Object? members_count = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? scheduled_for = const $CopyWithPlaceholder(),
    Object? speak_type = const $CopyWithPlaceholder(),
    Object? subject = const $CopyWithPlaceholder(),
    Object? tags = const $CopyWithPlaceholder(),
    Object? tickets_to_enter = const $CopyWithPlaceholder(),
    Object? tickets_to_speak = const $CopyWithPlaceholder(),
    Object? luma_event_id = const $CopyWithPlaceholder(),
    Object? i_am_member = const $CopyWithPlaceholder(),
    Object? online_users_count = const $CopyWithPlaceholder(),
    Object? reminder_minutes_before = const $CopyWithPlaceholder(),
  }) {
    return OutpostModel(
      uuid: uuid == const $CopyWithPlaceholder()
          ? _value.uuid
          // ignore: cast_nullable_to_non_nullable
          : uuid as String,
      created_at: created_at == const $CopyWithPlaceholder()
          ? _value.created_at
          // ignore: cast_nullable_to_non_nullable
          : created_at as int,
      creator_joined: creator_joined == const $CopyWithPlaceholder()
          ? _value.creator_joined
          // ignore: cast_nullable_to_non_nullable
          : creator_joined as bool,
      creator_user_name: creator_user_name == const $CopyWithPlaceholder()
          ? _value.creator_user_name
          // ignore: cast_nullable_to_non_nullable
          : creator_user_name as String,
      creator_user_uuid: creator_user_uuid == const $CopyWithPlaceholder()
          ? _value.creator_user_uuid
          // ignore: cast_nullable_to_non_nullable
          : creator_user_uuid as String,
      creator_user_image: creator_user_image == const $CopyWithPlaceholder()
          ? _value.creator_user_image
          // ignore: cast_nullable_to_non_nullable
          : creator_user_image as String,
      enter_type: enter_type == const $CopyWithPlaceholder()
          ? _value.enter_type
          // ignore: cast_nullable_to_non_nullable
          : enter_type as String,
      has_adult_content: has_adult_content == const $CopyWithPlaceholder()
          ? _value.has_adult_content
          // ignore: cast_nullable_to_non_nullable
          : has_adult_content as bool,
      image: image == const $CopyWithPlaceholder()
          ? _value.image
          // ignore: cast_nullable_to_non_nullable
          : image as String,
      invites: invites == const $CopyWithPlaceholder()
          ? _value.invites
          // ignore: cast_nullable_to_non_nullable
          : invites as List<InviteModel>?,
      is_archived: is_archived == const $CopyWithPlaceholder()
          ? _value.is_archived
          // ignore: cast_nullable_to_non_nullable
          : is_archived as bool,
      is_recordable: is_recordable == const $CopyWithPlaceholder()
          ? _value.is_recordable
          // ignore: cast_nullable_to_non_nullable
          : is_recordable as bool,
      last_active_at: last_active_at == const $CopyWithPlaceholder()
          ? _value.last_active_at
          // ignore: cast_nullable_to_non_nullable
          : last_active_at as int,
      members: members == const $CopyWithPlaceholder()
          ? _value.members
          // ignore: cast_nullable_to_non_nullable
          : members as List<LiveMember>?,
      members_count: members_count == const $CopyWithPlaceholder()
          ? _value.members_count
          // ignore: cast_nullable_to_non_nullable
          : members_count as int?,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      scheduled_for: scheduled_for == const $CopyWithPlaceholder()
          ? _value.scheduled_for
          // ignore: cast_nullable_to_non_nullable
          : scheduled_for as int,
      speak_type: speak_type == const $CopyWithPlaceholder()
          ? _value.speak_type
          // ignore: cast_nullable_to_non_nullable
          : speak_type as String,
      subject: subject == const $CopyWithPlaceholder()
          ? _value.subject
          // ignore: cast_nullable_to_non_nullable
          : subject as String,
      tags: tags == const $CopyWithPlaceholder()
          ? _value.tags
          // ignore: cast_nullable_to_non_nullable
          : tags as List<String>,
      tickets_to_enter: tickets_to_enter == const $CopyWithPlaceholder()
          ? _value.tickets_to_enter
          // ignore: cast_nullable_to_non_nullable
          : tickets_to_enter as List<_TicketToEnterModel>?,
      tickets_to_speak: tickets_to_speak == const $CopyWithPlaceholder()
          ? _value.tickets_to_speak
          // ignore: cast_nullable_to_non_nullable
          : tickets_to_speak as List<_TicketToSpeakModel>?,
      luma_event_id: luma_event_id == const $CopyWithPlaceholder()
          ? _value.luma_event_id
          // ignore: cast_nullable_to_non_nullable
          : luma_event_id as String?,
      i_am_member: i_am_member == const $CopyWithPlaceholder()
          ? _value.i_am_member
          // ignore: cast_nullable_to_non_nullable
          : i_am_member as bool,
      online_users_count: online_users_count == const $CopyWithPlaceholder()
          ? _value.online_users_count
          // ignore: cast_nullable_to_non_nullable
          : online_users_count as int?,
      reminder_minutes_before:
          reminder_minutes_before == const $CopyWithPlaceholder()
              ? _value.reminder_minutes_before
              // ignore: cast_nullable_to_non_nullable
              : reminder_minutes_before as int?,
    );
  }
}

extension $OutpostModelCopyWith on OutpostModel {
  /// Returns a callable class that can be used as follows: `instanceOfOutpostModel.copyWith(...)` or like so:`instanceOfOutpostModel.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$OutpostModelCWProxy get copyWith => _$OutpostModelCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OutpostModel _$OutpostModelFromJson(Map<String, dynamic> json) => OutpostModel(
      uuid: json['uuid'] as String,
      created_at: (json['created_at'] as num).toInt(),
      creator_joined: json['creator_joined'] as bool,
      creator_user_name: json['creator_user_name'] as String,
      creator_user_uuid: json['creator_user_uuid'] as String,
      creator_user_image: json['creator_user_image'] as String,
      enter_type: json['enter_type'] as String,
      has_adult_content: json['has_adult_content'] as bool,
      image: json['image'] as String,
      invites: (json['invites'] as List<dynamic>?)
          ?.map((e) => InviteModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      is_archived: json['is_archived'] as bool,
      is_recordable: json['is_recordable'] as bool,
      last_active_at: (json['last_active_at'] as num).toInt(),
      members: (json['members'] as List<dynamic>?)
          ?.map((e) => LiveMember.fromJson(e as Map<String, dynamic>))
          .toList(),
      members_count: (json['members_count'] as num?)?.toInt(),
      name: json['name'] as String,
      scheduled_for: (json['scheduled_for'] as num).toInt(),
      speak_type: json['speak_type'] as String,
      subject: json['subject'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      tickets_to_enter: (json['tickets_to_enter'] as List<dynamic>?)
          ?.map((e) => _TicketToEnterModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      tickets_to_speak: (json['tickets_to_speak'] as List<dynamic>?)
          ?.map((e) => _TicketToSpeakModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      luma_event_id: json['luma_event_id'] as String?,
      i_am_member: json['i_am_member'] as bool,
      online_users_count: (json['online_users_count'] as num?)?.toInt(),
      reminder_minutes_before:
          (json['reminder_minutes_before'] as num?)?.toInt(),
    );

Map<String, dynamic> _$OutpostModelToJson(OutpostModel instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'created_at': instance.created_at,
      'creator_joined': instance.creator_joined,
      'luma_event_id': instance.luma_event_id,
      'creator_user_name': instance.creator_user_name,
      'creator_user_uuid': instance.creator_user_uuid,
      'creator_user_image': instance.creator_user_image,
      'enter_type': instance.enter_type,
      'has_adult_content': instance.has_adult_content,
      'image': instance.image,
      'invites': instance.invites,
      'is_archived': instance.is_archived,
      'is_recordable': instance.is_recordable,
      'last_active_at': instance.last_active_at,
      'members': instance.members,
      'members_count': instance.members_count,
      'name': instance.name,
      'scheduled_for': instance.scheduled_for,
      'speak_type': instance.speak_type,
      'subject': instance.subject,
      'tags': instance.tags,
      'tickets_to_enter': instance.tickets_to_enter,
      'tickets_to_speak': instance.tickets_to_speak,
      'online_users_count': instance.online_users_count,
      'i_am_member': instance.i_am_member,
      'reminder_minutes_before': instance.reminder_minutes_before,
    };

_TicketToEnterModel _$TicketToEnterModelFromJson(Map<String, dynamic> json) =>
    _TicketToEnterModel(
      access_type: json['access_type'] as String,
      address: json['address'] as String,
      user_uuid: json['user_uuid'] as String?,
    );

Map<String, dynamic> _$TicketToEnterModelToJson(_TicketToEnterModel instance) =>
    <String, dynamic>{
      'access_type': instance.access_type,
      'address': instance.address,
      'user_uuid': instance.user_uuid,
    };

_TicketToSpeakModel _$TicketToSpeakModelFromJson(Map<String, dynamic> json) =>
    _TicketToSpeakModel(
      access_type: json['access_type'] as String,
      address: json['address'] as String,
      user_uuid: json['user_uuid'] as String?,
    );

Map<String, dynamic> _$TicketToSpeakModelToJson(_TicketToSpeakModel instance) =>
    <String, dynamic>{
      'access_type': instance.access_type,
      'address': instance.address,
      'user_uuid': instance.user_uuid,
    };

InviteModel _$InviteModelFromJson(Map<String, dynamic> json) => InviteModel(
      invitee_uuid: json['invitee_uuid'] as String,
      can_speak: json['can_speak'] as bool,
    );

Map<String, dynamic> _$InviteModelToJson(InviteModel instance) =>
    <String, dynamic>{
      'invitee_uuid': instance.invitee_uuid,
      'can_speak': instance.can_speak,
    };
