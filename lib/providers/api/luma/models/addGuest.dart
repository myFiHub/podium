import 'package:json_annotation/json_annotation.dart';

part 'addGuest.g.dart';

@JsonSerializable()
class AddGuestModel {
  final String email;
    String? name;
  AddGuestModel({
    required this.email,
    this.name,
  });

  factory AddGuestModel.fromJson(Map<String, dynamic> json) =>
      _$AddGuestModelFromJson(json);
  Map<String, dynamic> toJson() => _$AddGuestModelToJson(this);
}
