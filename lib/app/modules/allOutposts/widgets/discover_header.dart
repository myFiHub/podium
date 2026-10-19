import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/allOutposts/controllers/discover_controller.dart';
import 'package:podium/app/modules/allOutposts/views/tag_outposts_view.dart';
import 'package:podium/app/modules/global/widgets/img.dart';
import 'package:podium/app/modules/global/widgets/outpostsList.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/providers/api/podium/models/discovery/discovery_models.dart';
import 'package:podium/services/server_features.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/ui/app_ui.dart';

const _railHeight = 128.0;
const _cardWidth = 248.0;
const _railPadding = EdgeInsets.symmetric(horizontal: 16);

/// Tags, live and trending rails shown above the full outposts list.
class DiscoverHeader extends GetView<DiscoverController> {
  const DiscoverHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!Get.find<ServerFeatures>().discovery.value) {
        return const SizedBox.shrink();
      }
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TagsRail(),
          _FollowingRail(),
          _LiveRail(),
          _TrendingRail(),
          AppSectionHeader(title: 'All outposts'),
        ],
      );
    });
  }
}

class _TagsRail extends GetView<DiscoverController> {
  const _TagsRail();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tags = controller.popularTags.value;
      if (tags.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: _railPadding,
            itemCount: tags.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) => _TagChip(tag: tags[index]),
          ),
        ),
      );
    });
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});

  final PopularTagModel tag;

  @override
  Widget build(BuildContext context) {
    final active = tag.activeOutpostsCount;
    return Material(
      color: AppColors.fill,
      shape: StadiumBorder(side: BorderSide(color: AppColors.border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openTagOutposts(id: tag.id, name: tag.name),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '#',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              Text(
                tag.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ColorName.white,
                ),
              ),
              if (active > 0) ...[
                const SizedBox(width: 6),
                Text('$active', style: AppText.caption),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FollowingRail extends GetView<DiscoverController> {
  const _FollowingRail();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.liveFromFollowings.value;
      if (items.isEmpty) return const SizedBox.shrink();
      return _Rail(
        title: 'Live from people you follow',
        items: items,
        signal: _Signal.following,
      );
    });
  }
}

class _LiveRail extends GetView<DiscoverController> {
  const _LiveRail();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.liveNow.value;
      if (items.isEmpty) {
        return controller.isFirstLoad.value
            ? const _RailSkeleton(title: 'Live now')
            : const SizedBox.shrink();
      }
      return _Rail(title: 'Live now', items: items, signal: _Signal.live);
    });
  }
}

class _TrendingRail extends GetView<DiscoverController> {
  const _TrendingRail();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.trending.value;
      final loading = controller.isLoadingTrending.value;
      final toggle = _WindowToggle(
        selected: controller.trendingWindow.value,
        onSelect: controller.selectTrendingWindow,
      );
      if (items.isEmpty) {
        if (loading) return _RailSkeleton(title: 'Trending', trailing: toggle);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionHeader(title: 'Trending', trailing: toggle),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text(
                'Nothing trending yet. Rooms rise here as people listen and react.',
                style: AppText.caption,
              ),
            ),
          ],
        );
      }
      return _Rail(
        title: 'Trending',
        items: items,
        signal: _Signal.trending,
        trailing: toggle,
      );
    });
  }
}

class _WindowToggle extends StatelessWidget {
  const _WindowToggle({required this.selected, required this.onSelect});

  final TrendingWindow selected;
  final ValueChanged<TrendingWindow> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final window in TrendingWindow.values)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: GestureDetector(
                onTap: () => onSelect(window),
                child: AppPill(
                  label: window.label,
                  color: window == selected ? AppColors.primary : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _Signal { following, live, trending }

class _Rail extends StatelessWidget {
  const _Rail({
    required this.title,
    required this.items,
    required this.signal,
    this.trailing,
  });

  final String title;
  final List<DiscoveredOutpost> items;
  final _Signal signal;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(title: title, count: items.length, trailing: trailing),
        SizedBox(
          height: _railHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: _railPadding,
            itemCount: items.length,
            itemExtent: _cardWidth + 10,
            addAutomaticKeepAlives: false,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _RailCard(item: items[index], signal: signal),
            ),
          ),
        ),
      ],
    );
  }
}

class _RailCard extends StatelessWidget {
  const _RailCard({required this.item, required this.signal});

  final DiscoveredOutpost item;
  final _Signal signal;

  @override
  Widget build(BuildContext context) {
    final outpost = item.outpost;
    final online = outpost.online_users_count ?? 0;
    final tone = online > 0 ? AppColors.live : AppColors.primary;
    return AppCard(
      padding: const EdgeInsets.all(12),
      borderColor: tone.withAlpha(70),
      onTap: () => openOutpost(outpost),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Img(
                src: Uri.parse(outpost.image).isAbsolute ? outpost.image : '',
                alt: outpost.name,
                ifEmpty: Assets.images.logo.path,
                size: 44,
                borderRadius:
                    const BorderRadius.all(Radius.circular(AppRadius.sm)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      outpost.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.cardTitle.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'by ${outpost.creator_user_name ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              if (online > 0) ...[
                _LiveCount(count: online),
                const SizedBox(width: 8),
              ],
              Expanded(child: _signalLine()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _signalLine() {
    switch (signal) {
      case _Signal.following:
        if (item.followedUsersInRoomCount > 0) {
          return _FollowedPresence(item: item);
        }
        return const _SignalText(
          icon: Icons.person_rounded,
          text: 'Host you follow',
        );
      case _Signal.live:
        return _SignalText(
          icon: Icons.people_alt_rounded,
          text: '${item.outpost.members_count ?? 0} members',
        );
      case _Signal.trending:
        return _SignalText(
          icon: Icons.local_fire_department_rounded,
          text: _trendingText(item),
        );
    }
  }
}

String _trendingText(DiscoveredOutpost item) {
  final listeners = item.recentListeners;
  final reactions = item.recentReactions;
  final parts = [
    if (listeners > 0) '$listeners ${listeners == 1 ? 'listener' : 'listeners'}',
    if (reactions > 0) '$reactions ${reactions == 1 ? 'reaction' : 'reactions'}',
  ];
  return parts.isEmpty ? 'Picking up' : parts.join(' · ');
}

class _LiveCount extends StatelessWidget {
  const _LiveCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.live;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 6, color: color),
          const SizedBox(width: 4),
          Text(
            '$count',
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

class _SignalText extends StatelessWidget {
  const _SignalText({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textFaint),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _FollowedPresence extends StatelessWidget {
  const _FollowedPresence({required this.item});

  final DiscoveredOutpost item;

  @override
  Widget build(BuildContext context) {
    final users = item.followedUsersInRoom;
    final count = item.followedUsersInRoomCount;
    final first = users.isNotEmpty ? (users.first.name ?? 'Someone') : '';
    final others = count - 1;
    final label = users.isEmpty
        ? '$count you follow'
        : others > 0
            ? '$first +$others'
            : first;
    const avatar = 18.0;
    const overlap = 12.0;
    return Row(
      children: [
        SizedBox(
          width: avatar + overlap * (users.length - 1).clamp(0, 2),
          height: avatar,
          child: Stack(
            children: [
              for (var i = 0; i < users.length && i < 3; i++)
                Positioned(
                  left: overlap * i,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 1.5),
                    ),
                    child: Img(
                      src: users[i].image ?? '',
                      alt: users[i].name,
                      size: avatar - 3,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(avatar / 2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: ColorName.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _RailSkeleton extends StatelessWidget {
  const _RailSkeleton({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(title: title, trailing: trailing),
        SizedBox(
          height: _railHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: _railPadding,
            itemCount: 2,
            itemExtent: _cardWidth + 10,
            itemBuilder: (context, index) => const Padding(
              padding: EdgeInsets.only(right: 10),
              child: AppCard(
                padding: EdgeInsets.zero,
                child: SizedBox.expand(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
