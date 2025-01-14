import 'package:json_annotation/json_annotation.dart';

part 'outpost.g.dart';

@JsonSerializable()
class OutpostModel {
  final int alarm_id;
  final String uuid;
  final String created_at;
  final bool creator_joined;
  final String creator_user_name;
  final String creator_user_uuid;
  final String enter_type;
  final bool has_adult_content;
  final String image;
  final List<_InviteModel> invites;
  final bool is_archived;
  final bool is_recordable;
  final int last_active_at;
  final List<_MemberModel> members;
  final int members_count;
  final String name;
  final int scheduled_for;
  final String speak_type;
  final String subject;
  final List<String> tags;
  final List<_TicketToEnterModel> tickets_to_enter;
  final List<_TicketToSpeakModel> tickets_to_speak;

  OutpostModel({
    required this.alarm_id,
    required this.uuid,
    required this.created_at,
    required this.creator_joined,
    required this.creator_user_name,
    required this.creator_user_uuid,
    required this.enter_type,
    required this.has_adult_content,
    required this.image,
    required this.invites,
    required this.is_archived,
    required this.is_recordable,
    required this.last_active_at,
    required this.members,
    required this.members_count,
    required this.name,
    required this.scheduled_for,
    required this.speak_type,
    required this.subject,
    required this.tags,
    required this.tickets_to_enter,
    required this.tickets_to_speak,
  });

  factory OutpostModel.fromJson(Map<String, dynamic> json) =>
      _$OutpostModelFromJson(json);
  Map<String, dynamic> toJson() => _$OutpostModelToJson(this);
}

@JsonSerializable()
class _MemberModel {
  final String address;
  final String can_speak;
  final String uuid;

  _MemberModel({
    required this.address,
    required this.can_speak,
    required this.uuid,
  });

  factory _MemberModel.fromJson(Map<String, dynamic> json) =>
      _$MemberModelFromJson(json);
  Map<String, dynamic> toJson() => _$MemberModelToJson(this);
}

@JsonSerializable()
class _TicketToEnterModel {
  final String access_type;
  final String address;
  final String user_uuid;

  _TicketToEnterModel({
    required this.access_type,
    required this.address,
    required this.user_uuid,
  });

  factory _TicketToEnterModel.fromJson(Map<String, dynamic> json) =>
      _$TicketToEnterModelFromJson(json);
  Map<String, dynamic> toJson() => _$TicketToEnterModelToJson(this);
}

@JsonSerializable()
class _TicketToSpeakModel {
  final String access_type;
  final String address;
  final String user_uuid;

  _TicketToSpeakModel({
    required this.access_type,
    required this.address,
    required this.user_uuid,
  });

  factory _TicketToSpeakModel.fromJson(Map<String, dynamic> json) =>
      _$TicketToSpeakModelFromJson(json);
  Map<String, dynamic> toJson() => _$TicketToSpeakModelToJson(this);
}

@JsonSerializable()
class _InviteModel {
  final String invitee_uuid;
  final String can_speak;

  _InviteModel({
    required this.invitee_uuid,
    required this.can_speak,
  });

  factory _InviteModel.fromJson(Map<String, dynamic> json) =>
      _$InviteModelFromJson(json);
  Map<String, dynamic> toJson() => _$InviteModelToJson(this);
}
