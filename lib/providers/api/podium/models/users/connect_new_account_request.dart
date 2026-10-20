import 'package:json_annotation/json_annotation.dart';

part 'connect_new_account_request.g.dart';

@JsonSerializable()
class ConnectNewAccountRequest {
  final String aptos_address;
  final String current_address_signature;
  final String image;
  final String login_type;
  final String login_type_identifier;
  final String new_address;
  final String new_address_signature;

  ConnectNewAccountRequest({
    required this.aptos_address,
    required this.current_address_signature,
    required this.image,
    required this.login_type,
    required this.login_type_identifier,
    required this.new_address,
    required this.new_address_signature,
  });

  factory ConnectNewAccountRequest.fromJson(Map<String, dynamic> json) =>
      _$ConnectNewAccountRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ConnectNewAccountRequestToJson(this);
}
