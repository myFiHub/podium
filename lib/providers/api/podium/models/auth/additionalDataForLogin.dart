import 'package:json_annotation/json_annotation.dart';

part 'additionalDataForLogin.g.dart';

@JsonSerializable()
class AdditionalDataForLogin {
  final String? email;
  final String? name;
  final String? image;
  final String? loginType;

  AdditionalDataForLogin({
    this.email,
    this.name,
    this.image,
    this.loginType,
  });

  factory AdditionalDataForLogin.fromJson(Map<String, dynamic> json) =>
      _$AdditionalDataForLoginFromJson(json);

  Map<String, dynamic> toJson() => _$AdditionalDataForLoginToJson(this);
}
