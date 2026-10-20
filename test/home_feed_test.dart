import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/home/controllers/home_controller.dart';
import 'package:podium/app/modules/home/widgets/home_feed.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/data/repositories/repositories.dart';
import 'package:podium/providers/api/podium/models/discovery/discovery_models.dart';
import 'package:podium/providers/api/podium/models/home/home_feed.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/providers/api/podium/podium.dart';
import 'package:podium/services/server_features.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/utils/theme.dart';

// Shape copied from a podium-server /home response; names changed.
const _feedJson = '''
{
  "activity": {
    "active_today": true,
    "current": {"cheers_received": 3, "listen_minutes": 95.0, "new_followers": 4, "outposts_joined": 5, "speak_minutes": 12.0},
    "last_7_days": [false, true, false, false, true, true, true],
    "previous": {"cheers_received": 0, "listen_minutes": 40.0, "new_followers": 0, "outposts_joined": 6, "speak_minutes": 12.0},
    "streak_days": 3
  },
  "jump_back_in": [
    {
      "alarm_id": 7, "created_at": 1792491971, "creator_joined": false, "creator_user_image": null,
      "creator_user_name": "Sara", "creator_user_uuid": "01a158d8-e2cc-7151-bcb8-aca025b6eebc",
      "enter_type": "everyone", "has_adult_content": false, "i_am_member": false, "image": null,
      "is_archived": false, "is_recordable": false, "last_active_at": 1792491971285,
      "last_listened_at": 1792406771279, "latitude": null, "listened_minutes": 30.0, "longitude": null,
      "luma_event_id": null, "members_count": 1, "name": "Late night DeFi talk", "online_users_count": 0,
      "outpost_host_url": "https://outposts.myfihub.com", "scheduled_for": 1792232771279,
      "speak_type": "everyone", "subject": null, "tags": [], "uuid": "01a158d8-e2d5-7653-84b3-5e8295926f74"
    }
  ],
  "suggested_people": [
    {"followers_count": 120, "image": null, "is_live": true, "mutual_count": 0, "mutual_names": [],
     "name": "Sara", "outposts_count": 2, "reason": "you_listened", "uuid": "01a158d8-e2cc-7151-bcb8-aca025b6eebc"},
    {"followers_count": 3, "image": null, "is_live": false, "mutual_count": 0, "mutual_names": [],
     "name": "Reza", "outposts_count": 0, "reason": "follows_you", "uuid": "01a158d8-e2ce-7a90-890b-8c9c87ee855c"},
    {"followers_count": 48, "image": null, "is_live": false, "mutual_count": 4, "mutual_names": ["Ali", "Mina"],
     "name": "Neda", "outposts_count": 9, "reason": "followed_by_followings", "uuid": "01a158d8-e2ce-7a90-890b-8c9c87ee8551"},
    {"followers_count": 900, "image": null, "is_live": false, "mutual_count": 0, "mutual_names": [],
     "name": "Kian", "outposts_count": 31, "reason": "popular_host", "uuid": "01a158d8-e2ce-7a90-890b-8c9c87ee8552"},
    {"broken": true}
  ],
  "up_next": [
    {
      "alarm_id": 1, "created_at": 1792491971, "creator_joined": false, "creator_user_image": null,
      "creator_user_name": "Mohsen", "creator_user_uuid": "01a158d8-e2c0-76f2-91cc-793fdccf2080",
      "enter_type": "everyone", "has_adult_content": false, "i_am_member": true, "image": null,
      "is_archived": false, "is_recordable": false, "last_active_at": 1792491971281, "latitude": null,
      "longitude": null, "luma_event_id": null, "members_count": 1, "name": "Weekly builders sync",
      "online_users_count": 0, "outpost_host_url": "https://outposts.myfihub.com", "reason": "hosting",
      "reminder_set": false, "scheduled_for": 1792578371279, "speak_type": "everyone", "subject": null,
      "tags": [], "uuid": "01a158d8-e2cf-77d2-b875-a52a8f3996fe"
    },
    {
      "alarm_id": 2, "created_at": 1792491971, "creator_joined": false, "creator_user_image": null,
      "creator_user_name": "Ali", "creator_user_uuid": "01a158d8-e2c0-76f2-91cc-793fdccf2081",
      "enter_type": "everyone", "has_adult_content": false, "i_am_member": false, "image": null,
      "is_archived": false, "is_recordable": false, "last_active_at": 1792491971281, "latitude": null,
      "longitude": null, "luma_event_id": null, "members_count": 14, "name": "Avalanche AMA",
      "online_users_count": 0, "outpost_host_url": "https://outposts.myfihub.com", "reason": "followed_host",
      "reminder_set": true, "scheduled_for": 1792664771279, "speak_type": "everyone", "subject": null,
      "tags": [], "uuid": "01a158d8-e2cf-77d2-b875-a52a8f3996f1"
    }
  ]
}
''';

HomeFeed _feed() =>
    HomeFeed.fromJson(Map<String, dynamic>.from(jsonDecode(_feedJson)));

class _FakeRepo extends OutpostRepository {
  _FakeRepo(this.feed) : super(PodiumApi(Dio()));

  final HomeFeed feed;
  final live = <DiscoveredOutpost>[];

  @override
  Future<HomeFeed> getHomeFeed({required int utcOffsetMinutes}) async => feed;

  @override
  Future<List<DiscoveredOutpost>> getLiveFromFollowings({int? limit}) async =>
      live;
}

mixin _Lifecycle {
  bool get initialized => true;
  bool get isClosed => false;
  void onStart() {}
  void onDelete() {}
  void onInit() {}
  void onReady() {}
  void onClose() {}
}

var _users = 0;

/// A new user per test, so the home cache from an earlier test is dropped.
class _FakeGlobal with _Lifecycle implements GlobalController {
  @override
  final myUserInfo = Rxn<UserModel>(UserModel.fromJson(
    {'uuid': 'user-${_users++}', 'name': 'Mohsen', 'address': '0x0'},
  ));
  @override
  final activeRoute = Routes.MY_PROFILE.obs;
  @override
  final appLifecycleState = Rx(AppLifecycleState.resumed);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOutposts with _Lifecycle implements OutpostsController {
  @override
  final myOutposts = Rx<Map<String, OutpostModel>>({});
  @override
  final mapOfOnlineUsersInOutposts = Rx<Map<String, int>>({});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFeatures with _Lifecycle implements ServerFeatures {
  @override
  final discovery = true.obs;

  @override
  Future<void> probe() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('HomeFeed parses a server response and skips broken items', () {
    final feed = _feed();
    expect(feed.upNext.map((e) => e.outpost.name),
        ['Weekly builders sync', 'Avalanche AMA']);
    expect(feed.upNext.first.reason, UpNextReason.hosting);
    expect(feed.upNext.first.outpost.image, '');
    expect(feed.upNext.last.reason, UpNextReason.followedHost);
    expect(feed.upNext.last.reminderSet, isTrue);

    final recent = feed.jumpBackIn.single;
    expect(recent.listenedMinutes, 30);
    expect(recent.outpost.subject, '');

    expect(feed.suggestedPeople, hasLength(4));
    expect(feed.suggestedPeople.first.isLive, isTrue);
    expect(feed.suggestedPeople[2].mutualNames, ['Ali', 'Mina']);
    expect(feed.suggestedPeople.last.reason, SuggestionReason.popularHost);

    final activity = feed.activity;
    expect(activity.streakDays, 3);
    expect(activity.last7Days, hasLength(7));
    expect(activity.current.cheersReceived, 3);
    expect(activity.previous.outpostsJoined, 6);
  });

  test('unknown reasons fall back instead of failing', () {
    expect(UpNextReason.parse('something_new'), UpNextReason.followedHost);
    expect(SuggestionReason.parse(null), SuggestionReason.popularHost);
  });

  test('an empty response gives an empty feed', () {
    final feed = HomeFeed.fromJson(const {});
    expect(feed.upNext, isEmpty);
    expect(feed.activity.streakDays, 0);
    expect(feed.activity.current.isEmpty, isTrue);
  });

  test('labels', () {
    expect(compactMinutes(0), '0m');
    expect(compactMinutes(42.4), '42m');
    expect(compactMinutes(65), '1h 5m');
    expect(compactMinutes(120), '2h');
    expect(compactMinutes(725), '12h');

    final now = DateTime(2026, 10, 20, 10);
    expect(whenLabel(now.subtract(const Duration(minutes: 3)), now: now),
        'Starting now');
    expect(
        whenLabel(now.add(const Duration(minutes: 25)), now: now), 'In 25 min');
    expect(whenLabel(now.add(const Duration(hours: 3)), now: now), 'In 3h');
    expect(whenLabel(DateTime(2026, 10, 20, 20), now: now),
        startsWith('Today · '));
    expect(whenLabel(DateTime(2026, 10, 21, 18, 30), now: now),
        startsWith('Tomorrow · '));
    expect(
        whenLabel(DateTime(2026, 10, 23, 9), now: now), startsWith('Fri · '));
    expect(
        whenLabel(DateTime(2026, 11, 2, 9), now: now), startsWith('Nov 2 · '));

    expect(agoLabel(now, now: now), 'just now');
    expect(
        agoLabel(now.subtract(const Duration(minutes: 5)), now: now), '5m ago');
    expect(
        agoLabel(now.subtract(const Duration(hours: 3)), now: now), '3h ago');
    expect(agoLabel(now.subtract(const Duration(days: 2)), now: now), '2d ago');
  });

  group('HomeFeedSections', () {
    late _FakeRepo repo;

    setUp(() {
      Get.testMode = true;
      AppPalette.debugSet(AppPalette.all.first);
      repo = _FakeRepo(_feed());
      Get.put<GlobalController>(_FakeGlobal());
      Get.put<OutpostsController>(_FakeOutposts());
      Get.put<ServerFeatures>(_FakeFeatures());
      Get.put<OutpostRepository>(repo);
    });

    tearDown(Get.reset);

    Future<void> pump(WidgetTester tester, {bool onHome = false}) async {
      if (onHome) Get.find<GlobalController>().activeRoute.value = Routes.HOME;
      Get.put(HomeController());
      await tester.binding.setSurfaceSize(const Size(400, 1400));
      await tester.pumpWidget(MaterialApp(
        theme: buildThemeData(),
        home: const Scaffold(
          body: SingleChildScrollView(child: HomeFeedSections()),
        ),
      ));
      await tester.pump();
    }

    testWidgets('renders every section without overflowing', (tester) async {
      repo.live.add(DiscoveredOutpost.fromJson({
        ...Map<String, dynamic>.from(
            (jsonDecode(_feedJson)['up_next'] as List).last),
        'name': 'Builders hangout',
        'image': '',
        'subject': '',
        'creator_user_image': '',
        'online_users_count': 9,
        'followed_users_in_room': [
          {'uuid': 'a', 'name': 'Ali', 'image': null},
          {'uuid': 'b', 'name': 'Mina', 'image': null},
        ],
        'followed_users_in_room_count': 2,
      }));
      await pump(tester, onHome: true);

      expect(tester.takeException(), isNull);
      expect(find.text('HAPPENING NOW'), findsOneWidget);
      expect(find.text('Ali +1 inside'), findsOneWidget);
      expect(find.text('YOUR WEEK'), findsOneWidget);
      expect(find.text('3 day streak'), findsOneWidget);
      expect(find.text('1h 35m'), findsOneWidget);
      expect(find.text('3 cheers for you this week'), findsOneWidget);
      expect(find.text('UP NEXT'), findsOneWidget);
      expect(find.text('Hosting'), findsOneWidget);
      expect(find.text('JUMP BACK IN'), findsOneWidget);
      expect(find.text('PEOPLE TO FOLLOW'), findsOneWidget);
      expect(find.text('Follow back'), findsOneWidget);
      expect(find.text('Followed by Ali, Mina and 2 more'), findsOneWidget);

      // Stops the live poll timer started while Home is on screen.
      Get.delete<HomeController>();
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('a new account only gets quick actions and a nudge',
        (tester) async {
      repo = _FakeRepo(const HomeFeed());
      Get.replace<OutpostRepository>(repo);
      await pump(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('No streak yet'), findsOneWidget);
      expect(find.text('UP NEXT'), findsNothing);
      expect(find.text('PEOPLE TO FOLLOW'), findsNothing);
      expect(find.text('HAPPENING NOW'), findsNothing);

      await tester.binding.setSurfaceSize(null);
    });
  });
}
