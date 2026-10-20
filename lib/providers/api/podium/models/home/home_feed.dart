import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/utils/logger.dart';

int _int(Object? v) => (v as num?)?.toInt() ?? 0;
double _double(Object? v) => (v as num?)?.toDouble() ?? 0;

/// Skips items that fail to parse, so one bad row can't empty a section.
List<T> _list<T>(Object? v, T Function(Map<String, dynamic>) fromJson) {
  final items = <T>[];
  for (final e in v as List? ?? const []) {
    try {
      items.add(fromJson(Map<String, dynamic>.from(e)));
    } catch (err) {
      l.e(err);
    }
  }
  return items;
}

/// The server sends `null` for an empty image or subject, which
/// [OutpostModel.fromJson] can't read.
OutpostModel _outpost(Map<String, dynamic> json) => OutpostModel.fromJson({
      ...json,
      for (final key in const ['image', 'subject', 'creator_user_image'])
        key: json[key] ?? '',
    });

enum UpNextReason {
  hosting,
  cohosting,
  member,
  invited,
  followedHost;

  static UpNextReason parse(Object? value) => switch (value) {
        'hosting' => hosting,
        'cohosting' => cohosting,
        'member' => member,
        'invited' => invited,
        _ => followedHost,
      };
}

/// A scheduled outpost the viewer is involved in or may care about.
class UpNextOutpost {
  final OutpostModel outpost;
  final UpNextReason reason;
  final bool reminderSet;

  const UpNextOutpost({
    required this.outpost,
    required this.reason,
    required this.reminderSet,
  });

  /// The outpost fields sit at the top level next to the home fields.
  factory UpNextOutpost.fromJson(Map<String, dynamic> json) => UpNextOutpost(
        outpost: _outpost(json),
        reason: UpNextReason.parse(json['reason']),
        reminderSet: json['reminder_set'] as bool? ?? false,
      );
}

/// An outpost the viewer listened to recently.
class RecentOutpost {
  final OutpostModel outpost;

  /// Milliseconds since the epoch.
  final int lastListenedAt;
  final double listenedMinutes;

  const RecentOutpost({
    required this.outpost,
    required this.lastListenedAt,
    required this.listenedMinutes,
  });

  factory RecentOutpost.fromJson(Map<String, dynamic> json) => RecentOutpost(
        outpost: _outpost(json),
        lastListenedAt: _int(json['last_listened_at']),
        listenedMinutes: _double(json['listened_minutes']),
      );
}

enum SuggestionReason {
  youListened,
  followsYou,
  followedByFollowings,
  popularHost;

  static SuggestionReason parse(Object? value) => switch (value) {
        'you_listened' => youListened,
        'follows_you' => followsYou,
        'followed_by_followings' => followedByFollowings,
        _ => popularHost,
      };
}

class SuggestedUser {
  final String uuid;
  final String name;
  final String? image;
  final int followersCount;
  final int outpostsCount;
  final SuggestionReason reason;

  /// How many people the viewer follows also follow this person.
  final int mutualCount;

  /// Up to two of them.
  final List<String> mutualNames;

  /// Hosting a live outpost right now.
  final bool isLive;

  const SuggestedUser({
    required this.uuid,
    required this.name,
    this.image,
    this.followersCount = 0,
    this.outpostsCount = 0,
    required this.reason,
    this.mutualCount = 0,
    this.mutualNames = const [],
    this.isLive = false,
  });

  factory SuggestedUser.fromJson(Map<String, dynamic> json) => SuggestedUser(
        uuid: json['uuid'] as String,
        name: json['name'] as String,
        image: json['image'] as String?,
        followersCount: _int(json['followers_count']),
        outpostsCount: _int(json['outposts_count']),
        reason: SuggestionReason.parse(json['reason']),
        mutualCount: _int(json['mutual_count']),
        mutualNames: (json['mutual_names'] as List? ?? const [])
            .whereType<String>()
            .toList(),
        isLive: json['is_live'] as bool? ?? false,
      );
}

class ActivityTotals {
  final double listenMinutes;
  final double speakMinutes;
  final int outpostsJoined;
  final int newFollowers;
  final int cheersReceived;

  const ActivityTotals({
    this.listenMinutes = 0,
    this.speakMinutes = 0,
    this.outpostsJoined = 0,
    this.newFollowers = 0,
    this.cheersReceived = 0,
  });

  bool get isEmpty =>
      listenMinutes < 1 &&
      speakMinutes < 1 &&
      outpostsJoined == 0 &&
      newFollowers == 0 &&
      cheersReceived == 0;

  factory ActivityTotals.fromJson(Map<String, dynamic> json) => ActivityTotals(
        listenMinutes: _double(json['listen_minutes']),
        speakMinutes: _double(json['speak_minutes']),
        outpostsJoined: _int(json['outposts_joined']),
        newFollowers: _int(json['new_followers']),
        cheersReceived: _int(json['cheers_received']),
      );
}

class HomeActivity {
  /// The last seven days.
  final ActivityTotals current;

  /// The seven days before those.
  final ActivityTotals previous;

  /// Consecutive local days with an outpost joined, ending today or
  /// yesterday.
  final int streakDays;
  final bool activeToday;

  /// One per local day, oldest first, ending today.
  final List<bool> last7Days;

  const HomeActivity({
    this.current = const ActivityTotals(),
    this.previous = const ActivityTotals(),
    this.streakDays = 0,
    this.activeToday = false,
    this.last7Days = const [],
  });

  factory HomeActivity.fromJson(Map<String, dynamic> json) => HomeActivity(
        current: ActivityTotals.fromJson(
            Map<String, dynamic>.from(json['current'] as Map? ?? const {})),
        previous: ActivityTotals.fromJson(
            Map<String, dynamic>.from(json['previous'] as Map? ?? const {})),
        streakDays: _int(json['streak_days']),
        activeToday: json['active_today'] as bool? ?? false,
        last7Days: (json['last_7_days'] as List? ?? const [])
            .map((e) => e == true)
            .toList(),
      );
}

/// Everything the home page shows besides the viewer's own outposts.
class HomeFeed {
  final List<UpNextOutpost> upNext;
  final List<RecentOutpost> jumpBackIn;
  final List<SuggestedUser> suggestedPeople;
  final HomeActivity activity;

  const HomeFeed({
    this.upNext = const [],
    this.jumpBackIn = const [],
    this.suggestedPeople = const [],
    this.activity = const HomeActivity(),
  });

  factory HomeFeed.fromJson(Map<String, dynamic> json) => HomeFeed(
        upNext: _list(json['up_next'], UpNextOutpost.fromJson),
        jumpBackIn: _list(json['jump_back_in'], RecentOutpost.fromJson),
        suggestedPeople:
            _list(json['suggested_people'], SuggestedUser.fromJson),
        activity: HomeActivity.fromJson(
            Map<String, dynamic>.from(json['activity'] as Map? ?? const {})),
      );
}
