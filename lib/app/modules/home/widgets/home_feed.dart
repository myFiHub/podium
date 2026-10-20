import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/widgets/opening_overlay.dart';
import 'package:podium/app/modules/global/widgets/img.dart';
import 'package:podium/app/modules/global/widgets/outpostsList.dart';
import 'package:podium/app/modules/home/controllers/home_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/providers/api/podium/models/discovery/discovery_models.dart';
import 'package:podium/providers/api/podium/models/home/home_feed.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/services/server_features.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/ui/app_ui.dart';

const _railPadding = EdgeInsets.symmetric(horizontal: 16);
const _railGap = 10.0;

/// Everything on Home above the viewer's own outposts.
class HomeFeedSections extends StatelessWidget {
  const HomeFeedSections({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _QuickActions(),
        _HappeningNow(),
        _ActivityCard(),
        _UpNext(),
        _JumpBackIn(),
        _PeopleToFollow(),
      ],
    );
  }
}

// Quick actions

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasDashboard = Get.find<ServerFeatures>().discovery.value;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.add_rounded,
                label: 'Start',
                color: AppColors.primary,
                onTap: () => _open(Routes.CREATE_OUTPOST),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickAction(
                icon: Icons.explore_rounded,
                label: 'Explore',
                color: AppColors.violet,
                onTap: openExplore,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickAction(
                icon: Icons.replay_rounded,
                label: 'Replays',
                color: AppColors.magenta,
                onTap: () => _open(Routes.RECORDS),
              ),
            ),
            if (hasDashboard) ...[
              const SizedBox(width: 8),
              Expanded(
                child: _QuickAction(
                  icon: Icons.insights_rounded,
                  label: 'Insights',
                  color: AppColors.success,
                  onTap: () => _open(Routes.HOST_DASHBOARD),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  static void _open(String route) =>
      Navigate.to(type: NavigationTypes.toNamed, route: route);
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 12),
      radius: AppRadius.md,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconTile(icon: icon, color: color, size: 34),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: ColorName.white,
            ),
          ),
        ],
      ),
    );
  }
}

// Happening now

class _LiveItem {
  const _LiveItem({
    required this.outpost,
    required this.online,
    required this.line,
    this.people = const [],
  });

  final OutpostModel outpost;
  final int online;
  final String line;
  final List<LiveUserPreview> people;
}

class _HappeningNow extends GetView<HomeController> {
  const _HappeningNow();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final outposts = Get.find<OutpostsController>();
      final online = outposts.mapOfOnlineUsersInOutposts.value;
      final me = Get.find<GlobalController>().myUserInfo.value?.uuid;
      final items = <_LiveItem>[];
      final seen = <String>{};
      for (final outpost in outposts.myOutposts.value.values) {
        final count = online[outpost.uuid] ?? outpost.online_users_count ?? 0;
        if (count <= 0 || outpost.is_archived) continue;
        seen.add(outpost.uuid);
        items.add(_LiveItem(
          outpost: outpost,
          online: count,
          line: outpost.creator_user_uuid == me
              ? 'Your room is live'
              : 'One of your outposts',
        ));
      }
      for (final item in controller.liveFromFollowings.value) {
        if (!seen.add(item.outpost.uuid)) continue;
        items.add(_LiveItem(
          outpost: item.outpost,
          online:
              online[item.outpost.uuid] ?? item.outpost.online_users_count ?? 0,
          line: _presenceLine(item),
          people: item.followedUsersInRoom,
        ));
      }
      if (items.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: 'Happening now',
            count: items.length,
            trailing: const Padding(
              padding: EdgeInsets.only(right: 12),
              child: _LiveDot(),
            ),
          ),
          SizedBox(
            height: 124,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: _railPadding,
              itemCount: items.length,
              itemExtent: 260 + _railGap,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(right: _railGap),
                child: _LiveCard(item: items[i]),
              ),
            ),
          ),
        ],
      );
    });
  }

  static String _presenceLine(DiscoveredOutpost item) {
    final count = item.followedUsersInRoomCount;
    final first = item.followedUsersInRoom.firstOrNull?.name;
    if (count > 0 && first != null && first.isNotEmpty) {
      return count == 1 ? '$first is inside' : '$first +${count - 1} inside';
    }
    if (count > 0) return '$count you follow inside';
    return 'Host you follow';
  }
}

class _LiveCard extends StatelessWidget {
  const _LiveCard({required this.item});

  final _LiveItem item;

  @override
  Widget build(BuildContext context) {
    final outpost = item.outpost;
    final live = AppColors.live;
    return OpeningOutpostOverlay(
      outpostId: outpost.uuid,
      child: AppCard(
        padding: const EdgeInsets.all(12),
        borderGradient: LinearGradient(
          colors: [live.withAlpha(140), AppColors.magenta.withAlpha(60)],
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [live.withAlpha(26), AppColors.surfaceGlass],
        ),
        onTap: () => openOutpost(outpost),
        child: Row(
          children: [
            _OutpostImage(outpost: outpost, size: 64),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    outpost.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.cardTitle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (item.people.isNotEmpty) ...[
                        _AvatarStack(
                          images: [for (final p in item.people) p.image ?? ''],
                          names: [for (final p in item.people) p.name ?? ''],
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          item.line,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.caption,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _CountPill(
                    icon: Icons.headphones_rounded,
                    label: '${item.online} listening',
                    color: live,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Activity

class _ActivityCard extends GetView<HomeController> {
  const _ActivityCard();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.feedSupported.value) return const SizedBox.shrink();
      final feed = controller.feed.value;
      if (feed == null) {
        return controller.isLoadingFeed.value
            ? const _ActivitySkeleton()
            : const SizedBox.shrink();
      }
      final activity = feed.activity;
      final now = activity.current;
      final before = activity.previous;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSectionHeader(title: 'Your week'),
          AppCard(
            margin: _railPadding,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            borderGradient: LinearGradient(
              colors: [
                AppColors.primary.withAlpha(90),
                AppColors.violet.withAlpha(60),
                AppColors.magenta.withAlpha(40),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StreakRow(activity: activity),
                const SizedBox(height: 14),
                if (now.isEmpty && before.isEmpty)
                  Text(
                    'Join an outpost to start filling this in. Time listening, '
                    'time on the mic and new followers show up here.',
                    style: AppText.muted.copyWith(height: 1.4),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          label: 'Listened',
                          value: compactMinutes(now.listenMinutes),
                          delta: _minutesDelta(
                              now.listenMinutes, before.listenMinutes),
                        ),
                      ),
                      Expanded(
                        child: _Stat(
                          label: 'On the mic',
                          value: compactMinutes(now.speakMinutes),
                          delta: _minutesDelta(
                              now.speakMinutes, before.speakMinutes),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          label: 'Outposts',
                          value: '${now.outpostsJoined}',
                          delta: _countDelta(
                              now.outpostsJoined, before.outpostsJoined),
                        ),
                      ),
                      Expanded(
                        child: _Stat(
                          label: 'New followers',
                          value: '${now.newFollowers}',
                          delta: _countDelta(
                              now.newFollowers, before.newFollowers),
                        ),
                      ),
                    ],
                  ),
                  if (now.cheersReceived > 0) ...[
                    const SizedBox(height: 12),
                    AppCallout(
                      icon: Icons.celebration_rounded,
                      color: AppColors.accent,
                      text: now.cheersReceived == 1
                          ? 'Someone cheered for you this week'
                          : '${now.cheersReceived} cheers for you this week',
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _StreakRow extends StatelessWidget {
  const _StreakRow({required this.activity});

  final HomeActivity activity;

  @override
  Widget build(BuildContext context) {
    final streak = activity.streakDays;
    final flame = streak > 0 ? AppColors.accent : AppColors.textFaint;
    final title = switch (streak) {
      0 => 'No streak yet',
      1 => '1 day streak',
      _ => '$streak day streak',
    };
    final subtitle = streak == 0
        ? 'Join an outpost today to start one'
        : activity.activeToday
            ? 'You showed up today'
            : 'Join an outpost today to keep it going';
    final today = DateUtils.dateOnly(DateTime.now());
    final days = activity.last7Days;
    return Row(
      children: [
        AppIconTile(
          icon: Icons.local_fire_department_rounded,
          color: flame,
          size: 40,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.cardTitle),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        for (var i = 0; i < days.length; i++)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: _DayDot(
              letter: DateFormat.E()
                  .format(today.subtract(Duration(days: days.length - 1 - i)))
                  .substring(0, 1),
              active: days[i],
              isToday: i == days.length - 1,
            ),
          ),
      ],
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.letter,
    required this.active,
    required this.isToday,
  });

  final String letter;
  final bool active;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.accent;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? color : AppColors.fill,
            border: Border.all(
              color: isToday
                  ? AppColors.primary
                  : active
                      ? color
                      : AppColors.border,
              width: isToday ? 1.5 : 1,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          letter,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: isToday ? AppColors.primary : AppColors.textFaint,
          ),
        ),
      ],
    );
  }
}

class _Delta {
  const _Delta(this.label, this.up);

  final String label;
  final bool up;
}

_Delta? _minutesDelta(double now, double before) {
  final diff = now.round() - before.round();
  if (diff == 0) return null;
  if (before.round() == 0) return const _Delta('new', true);
  return _Delta(compactMinutes(diff.abs().toDouble()), diff > 0);
}

_Delta? _countDelta(int now, int before) {
  final diff = now - before;
  if (diff == 0) return null;
  if (before == 0) return const _Delta('new', true);
  return _Delta('${diff.abs()}', diff > 0);
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.delta});

  final String label;
  final String value;
  final _Delta? delta;

  @override
  Widget build(BuildContext context) {
    final delta = this.delta;
    final deltaColor =
        delta == null || delta.up ? AppColors.success : AppColors.textFaint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.caption),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              flex: 3,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: AppText.title.copyWith(
                    fontSize: 20,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            if (delta != null) ...[
              const SizedBox(width: 6),
              Flexible(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    delta.label == 'new'
                        ? 'new'
                        : '${delta.up ? '↑' : '↓'} ${delta.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: deltaColor,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ActivitySkeleton extends StatelessWidget {
  const _ActivitySkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(title: 'Your week'),
        AppCard(
          margin: _railPadding,
          padding: EdgeInsets.zero,
          child: SizedBox(height: 150),
        ),
      ],
    );
  }
}

// Up next

class _UpNext extends GetView<HomeController> {
  const _UpNext();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.feed.value?.upNext ?? const [];
      if (items.isEmpty) return const SizedBox.shrink();
      return _Rail(
        title: 'Up next',
        count: items.length,
        height: 132,
        itemWidth: 236,
        itemCount: items.length,
        itemBuilder: (i) => _UpNextCard(item: items[i]),
      );
    });
  }
}

class _UpNextCard extends StatelessWidget {
  const _UpNextCard({required this.item});

  final UpNextOutpost item;

  @override
  Widget build(BuildContext context) {
    final outpost = item.outpost;
    final at = DateTime.fromMillisecondsSinceEpoch(outpost.scheduled_for);
    final (reasonLabel, reasonColor) = _reasonStyle(item);
    return OpeningOutpostOverlay(
      outpostId: outpost.uuid,
      child: AppCard(
        padding: const EdgeInsets.all(12),
        onTap: () => openOutpost(outpost),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _DateBadge(at: at),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Ticking(
                        builder: () => Text(
                          whenLabel(at),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        outpost.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.cardTitle.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                if (item.reminderSet)
                  Icon(
                    Icons.notifications_active_rounded,
                    size: 16,
                    color: AppColors.accent,
                  ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Flexible(
                  child: AppPill(label: reasonLabel, color: reasonColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'by ${outpost.creator_user_name ?? 'someone'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: AppText.caption,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static (String, Color) _reasonStyle(UpNextOutpost item) =>
      switch (item.reason) {
        UpNextReason.hosting => ('Hosting', AppColors.primary),
        UpNextReason.cohosting => ('Cohosting', AppColors.primary),
        UpNextReason.member => ('Joined', AppColors.violet),
        UpNextReason.invited => ('Invited', AppColors.accent),
        UpNextReason.followedHost => ('You follow', AppColors.magenta),
      };
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.at});

  final DateTime at;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withAlpha(40),
            AppColors.violet.withAlpha(30),
          ],
        ),
        border: Border.all(color: AppColors.primary.withAlpha(70)),
      ),
      child: Column(
        children: [
          Text(
            DateFormat.MMM().format(at).toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          Text(
            '${at.day}',
            style: AppText.title.copyWith(fontSize: 18, height: 1.1),
          ),
        ],
      ),
    );
  }
}

// Jump back in

class _JumpBackIn extends GetView<HomeController> {
  const _JumpBackIn();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.feed.value?.jumpBackIn ?? const [];
      if (items.isEmpty) return const SizedBox.shrink();
      final online =
          Get.find<OutpostsController>().mapOfOnlineUsersInOutposts.value;
      return _Rail(
        title: 'Jump back in',
        height: 76,
        itemWidth: 248,
        itemCount: items.length,
        itemBuilder: (i) {
          final item = items[i];
          final count =
              online[item.outpost.uuid] ?? item.outpost.online_users_count ?? 0;
          return _RecentCard(item: item, online: count);
        },
      );
    });
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.item, required this.online});

  final RecentOutpost item;
  final int online;

  @override
  Widget build(BuildContext context) {
    final outpost = item.outpost;
    final listened = compactMinutes(item.listenedMinutes);
    final ago = agoLabel(
      DateTime.fromMillisecondsSinceEpoch(item.lastListenedAt),
    );
    return OpeningOutpostOverlay(
      outpostId: outpost.uuid,
      child: AppCard(
        padding: const EdgeInsets.all(10),
        borderColor: online > 0 ? AppColors.live.withAlpha(90) : null,
        onTap: () => openOutpost(outpost),
        child: Row(
          children: [
            _OutpostImage(outpost: outpost, size: 54),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    outpost.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.cardTitle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    online > 0
                        ? 'Live now · $online listening'
                        : 'Listened $listened · $ago',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(
                      color: online > 0 ? AppColors.live : null,
                      fontWeight: online > 0 ? FontWeight.w700 : null,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.play_circle_fill_rounded,
              size: 26,
              color: online > 0 ? AppColors.live : AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

// People to follow

class _PeopleToFollow extends GetView<HomeController> {
  const _PeopleToFollow();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final people = controller.feed.value?.suggestedPeople ?? const [];
      if (people.isEmpty) return const SizedBox.shrink();
      return _Rail(
        title: 'People to follow',
        height: 196,
        itemWidth: 148,
        itemCount: people.length,
        itemBuilder: (i) => _PersonCard(user: people[i]),
      );
    });
  }
}

class _PersonCard extends GetView<HomeController> {
  const _PersonCard({required this.user});

  final SuggestedUser user;

  @override
  Widget build(BuildContext context) {
    return OpeningProfileOverlay(
      userId: user.uuid,
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
        onTap: () => controller.openProfile(user.uuid),
        child: Column(
          children: [
            _Avatar(user: user),
            const SizedBox(height: 8),
            Text(
              user.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.cardTitle.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              _reasonLine(user),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption.copyWith(fontSize: 11, height: 1.3),
            ),
            const Spacer(),
            Obx(() {
              final following = controller.followed.contains(user.uuid);
              final busy = controller.followInProgress.contains(user.uuid);
              return SizedBox(
                width: double.infinity,
                height: 32,
                child: following
                    ? OutlinedButton(
                        onPressed:
                            busy ? null : () => controller.toggleFollow(user),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: ColorName.white,
                          side: BorderSide(color: AppColors.border),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('Following'),
                      )
                    : FilledButton(
                        onPressed:
                            busy ? null : () => controller.toggleFollow(user),
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Text(
                          user.reason == SuggestionReason.followsYou
                              ? 'Follow back'
                              : 'Follow',
                        ),
                      ),
              );
            }),
          ],
        ),
      ),
    );
  }

  static String _reasonLine(SuggestedUser user) {
    switch (user.reason) {
      case SuggestionReason.youListened:
        return 'You listened to their outposts';
      case SuggestionReason.followsYou:
        return 'Follows you';
      case SuggestionReason.followedByFollowings:
        final names = user.mutualNames;
        final others = user.mutualCount - names.length;
        if (names.isEmpty) {
          return 'Followed by ${user.mutualCount} you follow';
        }
        final who =
            names.join(names.length == 2 && others <= 0 ? ' and ' : ', ');
        return others > 0
            ? 'Followed by $who and $others more'
            : 'Followed by $who';
      case SuggestionReason.popularHost:
        final count = user.outpostsCount;
        return count > 0
            ? 'Popular host · $count ${count == 1 ? 'outpost' : 'outposts'}'
            : 'Popular host';
    }
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});

  final SuggestedUser user;

  @override
  Widget build(BuildContext context) {
    const size = 60.0;
    final ring = user.isLive ? AppColors.live : AppColors.violet.withAlpha(90);
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ring, width: 2),
          ),
          child: Img(
            src: user.image ?? '',
            alt: user.name,
            size: size,
            borderRadius: const BorderRadius.all(Radius.circular(size / 2)),
          ),
        ),
        if (user.isLive)
          Positioned(
            bottom: -6,
            child: AppPill(label: 'LIVE', color: AppColors.live, filled: true),
          ),
      ],
    );
  }
}

// Shared pieces

class _Rail extends StatelessWidget {
  const _Rail({
    required this.title,
    required this.height,
    required this.itemWidth,
    required this.itemCount,
    required this.itemBuilder,
    this.count,
  });

  final String title;
  final int? count;
  final double height;
  final double itemWidth;
  final int itemCount;
  final Widget Function(int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(title: title, count: count),
        SizedBox(
          height: height,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: _railPadding,
            itemCount: itemCount,
            itemExtent: itemWidth + _railGap,
            addAutomaticKeepAlives: false,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(right: _railGap),
              child: itemBuilder(i),
            ),
          ),
        ),
      ],
    );
  }
}

class _OutpostImage extends StatelessWidget {
  const _OutpostImage({required this.outpost, required this.size});

  final OutpostModel outpost;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Img(
      src: Uri.parse(outpost.image).isAbsolute ? outpost.image : '',
      alt: outpost.name,
      ifEmpty: Assets.images.logo.path,
      size: size,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.sm)),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.images, required this.names});

  final List<String> images;
  final List<String> names;

  @override
  Widget build(BuildContext context) {
    const avatar = 18.0;
    const overlap = 12.0;
    final count = images.length.clamp(0, 3);
    return SizedBox(
      width: avatar + overlap * (count - 1),
      height: avatar,
      child: Stack(
        children: [
          for (var i = 0; i < count; i++)
            Positioned(
              left: overlap * i,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
                child: Img(
                  src: images[i],
                  alt: names[i],
                  size: avatar - 3,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(avatar / 2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    return AppBreathing(
      period: const Duration(milliseconds: 1400),
      active: !reduceMotion(context),
      builder: (context, v) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.live,
          boxShadow: [
            BoxShadow(
              color: AppColors.live.withAlpha((80 + 120 * v).round()),
              blurRadius: 4 + 6 * v,
            ),
          ],
        ),
      ),
    );
  }
}

/// Rebuilds every 30 seconds so relative times stay current.
class _Ticking extends StatefulWidget {
  const _Ticking({required this.builder});

  final Widget Function() builder;

  @override
  State<_Ticking> createState() => _TickingState();
}

class _TickingState extends State<_Ticking> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer =
        Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder();
}

void openExplore() {
  Navigate.to(
    type: NavigationTypes.offAllNamed,
    route: Routes.ALL_OUTPOSTS,
  );
}

/// `42m`, `1h 5m`, `12h`.
String compactMinutes(double minutes) {
  final total = minutes.round();
  if (total < 60) return '${total}m';
  final hours = total ~/ 60;
  final rest = total % 60;
  if (hours >= 10 || rest == 0) return '${hours}h';
  return '${hours}h ${rest}m';
}

/// When a scheduled outpost starts, relative to now.
String whenLabel(DateTime at, {DateTime? now}) {
  now ??= DateTime.now();
  final diff = at.difference(now);
  if (diff.inMinutes < 1) return 'Starting now';
  if (diff.inMinutes < 60) return 'In ${diff.inMinutes} min';
  final time = DateFormat.jm().format(at);
  final days =
      DateUtils.dateOnly(at).difference(DateUtils.dateOnly(now)).inDays;
  if (days == 0) {
    return diff.inHours < 6 ? 'In ${diff.inHours}h' : 'Today · $time';
  }
  if (days == 1) return 'Tomorrow · $time';
  if (days < 7) return '${DateFormat.E().format(at)} · $time';
  return '${DateFormat.MMMd().format(at)} · $time';
}

/// `just now`, `5m ago`, `3h ago`, `2d ago`.
String agoLabel(DateTime at, {DateTime? now}) {
  now ??= DateTime.now();
  final diff = now.difference(at);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat.MMMd().format(at);
}
