import 'package:json_annotation/json_annotation.dart';

part 'addHost.g.dart';

@JsonSerializable()
class AddHostModel {
  final String? event_api_id;
  final String email;
  final String? access_level; //'none' | 'manager' | 'check-in'
  final bool is_visible;
  String? name;

  AddHostModel({
    this.event_api_id,
    required this.email,
    this.access_level = 'manager',
    this.is_visible = true,
    this.name,
  });

  factory AddHostModel.fromJson(Map<String, dynamic> json) =>
      _$AddHostModelFromJson(json);
  Map<String, dynamic> toJson() => _$AddHostModelToJson(this);
}
