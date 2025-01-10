import 'package:json_annotation/json_annotation.dart';

part 'loginRequest.g.dart';

@JsonSerializable()
class LoginRequest {
  final String signature;
  final String username;

  LoginRequest({required this.signature, required this.username});

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}
