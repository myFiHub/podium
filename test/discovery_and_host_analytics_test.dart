import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:podium/app/modules/hostAnalytics/widgets/analytics_widgets.dart';
import 'package:podium/providers/api/podium/models/analytics/host_analytics.dart';
import 'package:podium/providers/api/podium/models/discovery/discovery_models.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/utils/theme.dart';

// Shapes copied from podium-server responses.
Map<String, dynamic> _discovered() => {
      'uuid': '5afc2b22-beb8-4849-b933-f65eafcaea12',
      'name': 'Ali public',
      'subject': '',
      'creator_user_uuid': '6f9c20f7-f90d-4603-b42c-fcc8e8075dfc',
      'enter_type': 'everyone',
      'speak_type': 'everyone',
      'is_recordable': false,
      'is_archived': false,
      'has_adult_content': false,
      'image': '',
      'creator_joined': false,
      'scheduled_for': 1792446541405,
      'alarm_id': 1,
      'last_active_at': 1792446541405,
      'created_at': 1792446541,
      'members_count': 1,
      'creator_user_name': 'Host Ali',
      'creator_user_image': '',
      'tags': ['music'],
      'luma_event_id': null,
      'i_am_member': true,
      'online_users_count': 2,
      'latitude': null,
      'longitude': null,
      'outpost_host_url': 'https://outposts.myfihub.com',
      'recent_listeners': 3,
      'recent_reactions': 4,
      'host_is_followed': true,
      'followed_users_in_room': [
        {'uuid': '6f9c20f7-f90d-4603-b42c-fcc8e8075dfc', 'name': 'Host Ali', 'image': null},
      ],
      'followed_users_in_room_count': 1,
    };

Map<String, dynamic> _totals() => {
      'sessions': 3,
      'hosted_minutes': 110.0,
      'unique_listeners': 4,
      'returning_listeners': 3,
      'listener_visits': 8,
      'listen_minutes': 119.0,
      'avg_listen_minutes': 14.9,
      'peak_listeners': 4,
      'avg_peak_listeners': 2.3,
      'retention_10min_rate': 0.875,
      'cheers': 2,
      'boos': 1,
      'earned': 13.3,
    };

Map<String, dynamic> _summary() => {
      'window': '30d',
      'earned_chain_id': '126',
      'outposts_count': 2,
      'totals': _totals(),
      'daily': [
        {'date': '2026-10-18', 'sessions': 1, 'listener_visits': 3, 'listen_minutes': 56.0, 'peak_listeners': 2},
        {'date': '2026-10-19', 'sessions': 2, 'listener_visits': 5, 'listen_minutes': 63.0, 'peak_listeners': 4},
        {'date': '2026-10-20', 'sessions': 0, 'listener_visits': 0, 'listen_minutes': 0.0, 'peak_listeners': 0},
      ],
      'retention_curve': [
        {'minute': 0, 'listeners': 8, 'share': 1.0},
        {'minute': 10, 'listeners': 7, 'share': 0.875},
        {'minute': 30, 'listeners': 1, 'share': 0.125},
      ],
      'earnings_by_chain': [
        {'chain_id': '126', 'cheers': 1, 'boos': 1, 'cheers_amount': 9.5, 'boos_amount': 3.8, 'total_amount': 13.3},
      ],
      'audience_source': 'followers',
      'audience_heatmap': [
        {'dow': 1, 'hour': 22, 'users': 3},
        {'dow': 0, 'hour': 1, 'users': 2},
      ],
      'best_slots': [
        {'dow': 1, 'hour': 22, 'users': 3},
      ],
      'top_outposts': [
        {
          'uuid': '5afc2b22-beb8-4849-b933-f65eafcaea12',
          'name': 'Ali public',
          'image': null,
          'is_archived': false,
          'sessions': 2,
          'unique_listeners': 3,
          'peak_listeners': 2,
          'listen_minutes': 71.0,
          'avg_listen_minutes': 17.8,
          'retention_10min_rate': 0.75,
          'earned': 13.3,
          'last_session_at': 1792360141407,
        },
      ],
    };

void main() {
  group('DiscoveredOutpost', () {
    test('parses the outpost and the discovery fields side by side', () {
      final item = DiscoveredOutpost.fromJson(_discovered());
      expect(item.outpost.name, 'Ali public');
      expect(item.outpost.online_users_count, 2);
      expect(item.outpost.i_am_member, isTrue);
      expect(item.recentListeners, 3);
      expect(item.recentReactions, 4);
      expect(item.hostIsFollowed, isTrue);
      expect(item.followedUsersInRoom.single.name, 'Host Ali');
      expect(item.followedUsersInRoomCount, 1);
    });

    test('defaults missing discovery fields', () {
      final json = _discovered()
        ..remove('recent_listeners')
        ..remove('followed_users_in_room')
        ..remove('host_is_followed');
      final item = DiscoveredOutpost.fromJson(json);
      expect(item.recentListeners, 0);
      expect(item.followedUsersInRoom, isEmpty);
      expect(item.hostIsFollowed, isFalse);
    });
  });

  test('PopularTagModel parses counts', () {
    final tag = PopularTagModel.fromJson(
      {'id': 1, 'name': 'music', 'outposts_count': 2, 'active_outposts_count': 1},
    );
    expect(tag.name, 'music');
    expect(tag.outpostsCount, 2);
    expect(tag.activeOutpostsCount, 1);
  });

  group('HostAnalyticsSummary', () {
    test('parses a full summary', () {
      final s = HostAnalyticsSummary.fromJson(_summary());
      expect(s.earnedChainId, '126');
      expect(s.outpostsCount, 2);
      expect(s.totals.peakListeners, 4);
      expect(s.totals.retention10MinRate, 0.875);
      expect(s.totals.earned, 13.3);
      expect(s.daily.length, 3);
      expect(s.daily.first.date, DateTime(2026, 10, 18));
      expect(s.retentionCurve.last.share, 0.125);
      expect(s.earningsByChain.single.totalAmount, 13.3);
      expect(s.audienceSource, AudienceSource.followers);
      expect(s.bestSlots.single.hour, 22);
      final top = s.topOutposts.single;
      expect(top.image, isNull);
      expect(top.lastSessionAt,
          DateTime.fromMillisecondsSinceEpoch(1792360141407));
    });

    test('treats an unknown audience source as none', () {
      final json = _summary()..['audience_source'] = 'something_new';
      expect(
        HostAnalyticsSummary.fromJson(json).audienceSource,
        AudienceSource.none,
      );
    });
  });

  test('HostOutpostAnalytics parses sessions', () {
    final data = HostOutpostAnalytics.fromJson({
      'window': '7d',
      'earned_chain_id': '126',
      'outpost': {
        'uuid': '5afc2b22-beb8-4849-b933-f65eafcaea12',
        'name': 'Ali public',
        'image': null,
        'is_archived': false,
      },
      'totals': _totals(),
      'daily': [],
      'retention_curve': [],
      'earnings_by_chain': [],
      'sessions': [
        {
          'uuid': '61936ccc-903b-4d26-9f47-d0bc8e0aee2b',
          'started_at': 1792360141407,
          'duration_seconds': 3600,
          'listeners': 3,
          'peak_listeners': 2,
          'avg_listen_minutes': 18.7,
          'retention_10min_rate': 0.667,
          'cheers': 2,
          'boos': 1,
          'earned': 13.3,
        },
      ],
    });
    expect(data.outpostName, 'Ali public');
    expect(data.sessions.single.peakListeners, 2);
    expect(data.sessions.single.durationSeconds, 3600);
  });

  test('formatters', () {
    expect(formatMinutes(0), '0m');
    expect(formatMinutes(0.4), '<1m');
    expect(formatMinutes(45), '45m');
    expect(formatMinutes(90), '1.5h');
    expect(formatPercent(0.875), '88%');
  });

  testWidgets('charts render with real data and with no data', (tester) async {
    AppPalette.debugSet(AppPalette.all.first);
    final s = HostAnalyticsSummary.fromJson(_summary());
    Widget wrap(Widget child) => MaterialApp(
          theme: buildThemeData(),
          home: Scaffold(body: SingleChildScrollView(child: child)),
        );

    await tester.pumpWidget(wrap(Column(children: [
      KpiGrid(totals: s.totals, earnedChainId: ''),
      DailyActivityChart(points: s.daily),
      RetentionBars(points: s.retentionCurve),
      BestTimeToGoLive(cells: s.audienceHeatmap, bestSlots: s.bestSlots),
    ])));
    expect(tester.takeException(), isNull);
    expect(find.text('Peak listeners'), findsOneWidget);
    expect(find.text('88%'), findsWidgets);

    await tester.pumpWidget(wrap(const Column(children: [
      DailyActivityChart(points: []),
      RetentionBars(points: []),
      BestTimeToGoLive(cells: [], bestSlots: []),
    ])));
    expect(tester.takeException(), isNull);
    expect(find.text('No sessions in this period'), findsOneWidget);
  });
}
