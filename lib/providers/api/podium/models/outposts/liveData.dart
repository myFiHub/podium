/*

{
    "members": [
      {
        "address": "string",
        "can_speak": true,
        "feedbacks": [
          {
            "feedback_type": "like",
            "time": "2025-03-21T13:48:58.145Z",
            "user_address": "string"
          }
        ],
        "image": "string",
        "is_present": true,
        "is_speaking": true,
        "name": "string",
        "reactions": [
          {
            "amount": 0.1,
            "reaction_type": "boo",
            "time": "2025-03-21T13:48:58.145Z",
            "user_address": "string"
          }
        ],
        "remaining_time": 9007199254740991,
        "uuid": "3fa85f64-5717-4562-b3fc-2c963f66afa6"
      }
    ]
  }


 */

import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'liveData.g.dart';

@JsonSerializable()
class OutpostLiveData {
  final List<LiveMember> members;

  OutpostLiveData({required this.members});

  factory OutpostLiveData.fromJson(Map<String, dynamic> json) =>
      _$OutpostLiveDataFromJson(json);
  Map<String, dynamic> toJson() => _$OutpostLiveDataToJson(this);
}

@JsonSerializable()
@CopyWith()
class LiveMember {
  final String address;
  final bool can_speak;
  final List<Feedback> feedbacks;
  final String image;
  final bool is_present;
  bool is_speaking;
  final String name;
  final List<UserReaction> reactions;
  int remaining_time;
  int? last_speaked_at_timestamp;
  final String aptos_address;
  final String? external_wallet_address;
  final String uuid;
  final bool? followed_by_me;

  LiveMember({
    required this.address,
    required this.can_speak,
    this.feedbacks = const [],
    required this.image,
    this.is_present = false,
    this.is_speaking = false,
    required this.name,
    this.reactions = const [],
    this.remaining_time = 0,
    required this.uuid,
    this.last_speaked_at_timestamp,
    required this.aptos_address,
    this.external_wallet_address,
    this.followed_by_me,
  });

  factory LiveMember.fromJson(Map<String, dynamic> json) =>
      _$LiveMemberFromJson(json);
  Map<String, dynamic> toJson() => _$LiveMemberToJson(this);
}

@JsonSerializable()
class Feedback {
  final String feedback_type;
  final String time;
  final String user_address;

  Feedback(
      {required this.feedback_type,
      required this.time,
      required this.user_address});

  factory Feedback.fromJson(Map<String, dynamic> json) =>
      _$FeedbackFromJson(json);
  Map<String, dynamic> toJson() => _$FeedbackToJson(this);
}

@JsonSerializable()
class UserReaction {
  final double amount;
  final String reaction_type;
  final String time;
  final String user_address;

  UserReaction(
      {required this.amount,
      required this.reaction_type,
      required this.time,
      required this.user_address});

  factory UserReaction.fromJson(Map<String, dynamic> json) =>
      _$UserReactionFromJson(json);
  Map<String, dynamic> toJson() => _$UserReactionToJson(this);
}
