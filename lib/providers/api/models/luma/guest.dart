import 'package:json_annotation/json_annotation.dart';

part 'guest.g.dart';

@JsonSerializable()
class GuestModel {
  final String api_id;
  final GuestDataModel data;

  GuestModel({
    required this.api_id,
    required this.data,
  });

  factory GuestModel.fromJson(Map<String, dynamic> json) =>
      _$GuestModelFromJson(json);
  Map<String, dynamic> toJson() => _$GuestModelToJson(this);
}

@JsonSerializable()
class GuestDataModel {
  final String api_id;
  final String approval_status;
  final String registered_at;
  final String invited_at;
  final String checked_in_at;
  final String joined_at;
  final String user_api_id;
  final String created_at;
  final String user_name;
  final String user_email;

  GuestDataModel({
    required this.api_id,
    required this.approval_status,
    required this.registered_at,
    required this.invited_at,
    required this.checked_in_at,
    required this.joined_at,
    required this.user_api_id,
    required this.created_at,
    required this.user_name,
    required this.user_email,
  });

  factory GuestDataModel.fromJson(Map<String, dynamic> json) =>
      _$GuestDataModelFromJson(json);
  Map<String, dynamic> toJson() => _$GuestDataModelToJson(this);
}
