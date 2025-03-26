import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:podium/providers/api/podium/models/outposts/liveData.dart';

part 'outpost.g.dart';

@JsonSerializable()
@CopyWith()
class OutpostModel {
  final int alarm_id;
  final String uuid;
  final int created_at;
  final bool creator_joined;
  String? luma_event_id;
  final String creator_user_name;
  final String creator_user_uuid;
  final String creator_user_image;
  final String enter_type;
  final bool has_adult_content;
  final String image;
  final List<InviteModel>? invites;
  final bool is_archived;
  final bool is_recordable;
  final int last_active_at;
  final List<LiveMember>? members;
  final int? members_count;
  final String name;
  final int scheduled_for;
  final String speak_type;
  final String subject;
  final List<String> tags;
  final List<_TicketToEnterModel>? tickets_to_enter;
  final List<_TicketToSpeakModel>? tickets_to_speak;
  final int? online_users_count;
  bool i_am_member;

  OutpostModel({
    required this.alarm_id,
    required this.uuid,
    required this.created_at,
    required this.creator_joined,
    required this.creator_user_name,
    required this.creator_user_uuid,
    required this.creator_user_image,
    required this.enter_type,
    required this.has_adult_content,
    required this.image,
    this.invites,
    required this.is_archived,
    required this.is_recordable,
    required this.last_active_at,
    this.members,
    required this.members_count,
    required this.name,
    required this.scheduled_for,
    required this.speak_type,
    required this.subject,
    required this.tags,
    this.tickets_to_enter,
    this.tickets_to_speak,
    this.luma_event_id,
    required this.i_am_member,
    required this.online_users_count,
  });

  factory OutpostModel.fromJson(Map<String, dynamic> json) =>
      _$OutpostModelFromJson(json);
  Map<String, dynamic> toJson() => _$OutpostModelToJson(this);
}

@JsonSerializable()
class _TicketToEnterModel {
  final String access_type;
  final String address;
  final String? user_uuid;

  _TicketToEnterModel({
    required this.access_type,
    required this.address,
    this.user_uuid,
  });

  factory _TicketToEnterModel.fromJson(Map<String, dynamic> json) =>
      _$TicketToEnterModelFromJson(json);
  Map<String, dynamic> toJson() => _$TicketToEnterModelToJson(this);
}

@JsonSerializable()
class _TicketToSpeakModel {
  final String access_type;
  final String address;
  final String? user_uuid;

  _TicketToSpeakModel({
    required this.access_type,
    required this.address,
    this.user_uuid,
  });

  factory _TicketToSpeakModel.fromJson(Map<String, dynamic> json) =>
      _$TicketToSpeakModelFromJson(json);
  Map<String, dynamic> toJson() => _$TicketToSpeakModelToJson(this);
}

@JsonSerializable()
class InviteModel {
  final String invitee_uuid;
  final bool can_speak;

  InviteModel({
    required this.invitee_uuid,
    required this.can_speak,
  });

  factory InviteModel.fromJson(Map<String, dynamic> json) =>
      _$InviteModelFromJson(json);
  Map<String, dynamic> toJson() => _$InviteModelToJson(this);
}
