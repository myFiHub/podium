import 'package:json_annotation/json_annotation.dart';

part 'additionalDataForLogin.g.dart';

@JsonSerializable()
class AdditionalDataForLogin {
  final String? email;
  final String? name;
  final String? image;

  AdditionalDataForLogin({
    this.email,
    this.name,
    this.image,
  });

  factory AdditionalDataForLogin.fromJson(Map<String, dynamic> json) =>
      _$AdditionalDataForLoginFromJson(json);

  Map<String, dynamic> toJson() => _$AdditionalDataForLoginToJson(this);
}
