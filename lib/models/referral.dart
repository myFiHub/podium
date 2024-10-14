import 'package:json_annotation/json_annotation.dart';

part 'referral.g.dart';

@JsonSerializable()
class Referral {
  final String? usedBy;
  static const String usedByKey = 'usedBy';
  Referral({
    this.usedBy,
  });

// json annotation compatible tojson and fromjson
  factory Referral.fromJson(Map<String, dynamic> json) =>
      _$ReferralFromJson(json);
  Map<String, dynamic> toJson() => _$ReferralToJson(this);
}
