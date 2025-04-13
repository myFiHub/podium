import 'package:json_annotation/json_annotation.dart';

part 'loginRequest.g.dart';

@JsonSerializable()
class LoginRequest {
  final String signature;
  final String username;
  final String aptos_address;
  final bool has_ticket;
  final String login_type_identifier;
  String? referrer_user_uuid;

  LoginRequest({
    required this.signature,
    required this.username,
    required this.aptos_address,
    required this.has_ticket,
    required this.login_type_identifier,
    required this.referrer_user_uuid,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}
