import 'package:podium/providers/api/podium/models/outposts/outpost.dart';

/// Someone the viewer follows who is in a live outpost right now.
class LiveUserPreview {
  final String uuid;
  final String? name;
  final String? image;

  const LiveUserPreview({required this.uuid, this.name, this.image});

  factory LiveUserPreview.fromJson(Map<String, dynamic> json) =>
      LiveUserPreview(
        uuid: json['uuid'] as String,
        name: json['name'] as String?,
        image: json['image'] as String?,
      );
}

/// An outpost from the discovery endpoints, with the signals that ranked it.
class DiscoveredOutpost {
  final OutpostModel outpost;

  /// Distinct listeners in the trending window; 0 outside trending.
  final int recentListeners;

  /// Cheers and boos in the trending window; 0 outside trending.
  final int recentReactions;
  final bool hostIsFollowed;

  /// Up to three of them; [followedUsersInRoomCount] has the full count.
  final List<LiveUserPreview> followedUsersInRoom;
  final int followedUsersInRoomCount;

  const DiscoveredOutpost({
    required this.outpost,
    this.recentListeners = 0,
    this.recentReactions = 0,
    this.hostIsFollowed = false,
    this.followedUsersInRoom = const [],
    this.followedUsersInRoomCount = 0,
  });

  /// The outpost fields sit at the top level next to the discovery fields.
  factory DiscoveredOutpost.fromJson(Map<String, dynamic> json) =>
      DiscoveredOutpost(
        outpost: OutpostModel.fromJson(json),
        recentListeners: (json['recent_listeners'] as num?)?.toInt() ?? 0,
        recentReactions: (json['recent_reactions'] as num?)?.toInt() ?? 0,
        hostIsFollowed: json['host_is_followed'] as bool? ?? false,
        followedUsersInRoom: (json['followed_users_in_room'] as List? ?? [])
            .map((e) => LiveUserPreview.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        followedUsersInRoomCount:
            (json['followed_users_in_room_count'] as num?)?.toInt() ?? 0,
      );
}

class PopularTagModel {
  final int id;
  final String name;
  final int outpostsCount;
  final int activeOutpostsCount;

  const PopularTagModel({
    required this.id,
    required this.name,
    required this.outpostsCount,
    required this.activeOutpostsCount,
  });

  factory PopularTagModel.fromJson(Map<String, dynamic> json) =>
      PopularTagModel(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        outpostsCount: (json['outposts_count'] as num?)?.toInt() ?? 0,
        activeOutpostsCount:
            (json['active_outposts_count'] as num?)?.toInt() ?? 0,
      );
}

enum TrendingWindow {
  day('24h', 'Today'),
  week('7d', 'This week');

  const TrendingWindow(this.value, this.label);

  final String value;
  final String label;
}
