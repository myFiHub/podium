import 'package:json_annotation/json_annotation.dart';

part 'tag.g.dart';

@JsonSerializable()
class TagModel {
  final String uuid;
  final String name;
  final List<String> outpostIds;
  TagModel({
    required this.uuid,
    required this.name,
    required this.outpostIds,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) =>
      _$TagModelFromJson(json);
  Map<String, dynamic> toJson() => _$TagModelToJson(this);
}
