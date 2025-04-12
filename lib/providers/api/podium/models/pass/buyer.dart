import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'buyer.g.dart';

@JsonSerializable()
@CopyWith()
class PodiumPassBuyerModel {
  final String address;
  final bool followed_by_me;
  final String image;
  final String name;
  final String uuid;

  PodiumPassBuyerModel({
    required this.address,
    required this.followed_by_me,
    required this.image,
    required this.name,
    required this.uuid,
  });

  factory PodiumPassBuyerModel.fromJson(Map<String, dynamic> json) =>
      _$PodiumPassBuyerModelFromJson(json);
  Map<String, dynamic> toJson() => _$PodiumPassBuyerModelToJson(this);
}
