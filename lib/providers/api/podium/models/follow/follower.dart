import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'follower.g.dart';

@JsonSerializable()
@CopyWith()
class FollowerModel {
  @JsonKey(defaultValue: '')
  final String address;
  final bool followed_by_me;
  @JsonKey(defaultValue: '')
  final String image;
  @JsonKey(defaultValue: '')
  final String name;
  final String uuid;

  FollowerModel({
    required this.address,
    required this.followed_by_me,
    required this.image,
    required this.name,
    required this.uuid,
  });

  factory FollowerModel.fromJson(Map<String, dynamic> json) =>
      _$FollowerModelFromJson(json);

  Map<String, dynamic> toJson() => _$FollowerModelToJson(this);
}
