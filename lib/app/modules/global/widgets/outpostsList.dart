import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/createOutpost/controllers/create_outpost_controller.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/popUpsAndModals/outpostImage.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/time.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/env.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/utils/analytics.dart';
import 'package:podium/widgets/ui/app_ui.dart';
import 'package:pulsator/pulsator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:visibility_detector/visibility_detector.dart';

enum ListPage { all, my, search }

const _listPadding = EdgeInsets.only(top: 4, bottom: 96);

class OutpostsList extends GetView<OutpostsController> {
  final List<OutpostModel>? outpostsList;
  final ScrollController? scrollController;
  final ListPage listPage;
  const OutpostsList({
    super.key,
    this.outpostsList,
    this.scrollController,
    required this.listPage,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Only subscribe to this tab's data so the other tab's updates don't
      // rebuild this list.
      final isMyPage = listPage == ListPage.my;
      final pageOutposts =
          isMyPage ? controller.myOutposts.value : controller.outposts.value;
      final lastPageReached = isMyPage
          ? controller.lastPageReachedForMyOutposts.value
          : controller.lastPageReachedForAllOutposts.value;

      if (listPage != ListPage.search && pageOutposts.isEmpty) {
        return ListView.builder(
          cacheExtent: 200,
          controller: scrollController,
          padding: _listPadding,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          addAutomaticKeepAlives: false,
          itemBuilder: (context, index) => const OutpostCardSkeleton(),
        );
      }

      Widget listWidget;
      if (outpostsList != null) {
        List<OutpostModel> listToShow = outpostsList!;

        listWidget = ListView.builder(
          cacheExtent: 200,
          controller: scrollController,
          padding: _listPadding,
          itemCount: listToShow.length,
          addAutomaticKeepAlives: false,
          itemBuilder: (context, index) {
            final outpost = listToShow[index];
            return AppEntrance(
              key: ValueKey(outpost.uuid),
              id: outpost.uuid,
              index: index,
              child: _SingleOutpost(
                controller: controller,
                amICreator: outpost.creator_user_uuid == myId,
                outpost: outpost,
              ),
            );
          },
        );
      } else {
        listWidget = _PaginatedOutposts(
          items: pageOutposts.values.toList(),
          hasReachedMax: lastPageReached,
          scrollController: scrollController,
          controller: controller,
          fetchPage: listPage == ListPage.all
              ? controller.fetchAllOutpostsPage
              : controller.fetchMyOutpostsPage,
        );
      }

      return RawScrollbar(
        thumbColor: ColorName.white.withAlpha(40),
        radius: const Radius.circular(4),
        thickness: 3,
        controller: scrollController,
        child: listWidget,
      );
    });
  }
}

/// Lazily built list that asks for the next page when the user nears the end.
class _PaginatedOutposts extends StatefulWidget {
  const _PaginatedOutposts({
    required this.items,
    required this.hasReachedMax,
    required this.scrollController,
    required this.controller,
    required this.fetchPage,
  });

  final List<OutpostModel> items;
  final bool hasReachedMax;
  final ScrollController? scrollController;
  final OutpostsController controller;
  final Future<void> Function(int page) fetchPage;

  @override
  State<_PaginatedOutposts> createState() => _PaginatedOutpostsState();
}

class _PaginatedOutpostsState extends State<_PaginatedOutposts> {
  static const _loadMoreThreshold = 400.0;
  bool _loadingMore = false;

  Future<void> _loadMore() async {
    if (_loadingMore || widget.hasReachedMax || widget.items.isEmpty) return;
    _loadingMore = true;
    try {
      await widget.fetchPage(widget.items.length ~/ numberOfOutpostsPerPage);
    } finally {
      _loadingMore = false;
    }
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification &&
        notification.metrics.axis == Axis.vertical &&
        notification.metrics.extentAfter <= _loadMoreThreshold) {
      _loadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    return RefreshIndicator(
      color: AppColors.onPrimary,
      backgroundColor: ColorName.primaryBlue,
      onRefresh: () async => await widget.fetchPage(0),
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: ListView.builder(
          controller: widget.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: _listPadding,
          itemCount: items.length,
          addAutomaticKeepAlives: false,
          itemBuilder: (context, index) {
            final outpost = items[index];
            return AppEntrance(
              key: ValueKey(outpost.uuid),
              id: outpost.uuid,
              index: index,
              child: _SingleOutpost(
                controller: widget.controller,
                amICreator: outpost.creator_user_uuid == myId,
                outpost: outpost,
              ),
            );
          },
        ),
      ),
    );
  }
}

Future<void> _openOutpost(
  OutpostsController controller,
  OutpostModel outpost,
) async {
  if (!wsClient.connected) {
    await HttpApis.podium.connectToWebSocket();
  }
  controller.joinOutpostAndOpenOutpostDetailPage(
    outpostId: outpost.uuid,
  );
}

class _SingleOutpost extends StatelessWidget {
  const _SingleOutpost({
    required this.controller,
    required this.amICreator,
    required this.outpost,
  });

  final OutpostsController controller;
  final bool amICreator;
  final OutpostModel outpost;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('outpost_${outpost.uuid}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction == 0) {
          controller.removeOutpostFromView(outpost.uuid);
        } else {
          controller.addOutpostToView(outpost.uuid);
        }
      },
      child: _OutpostCard(
        outpost: outpost,
        amICreator: amICreator,
        controller: controller,
      ),
    );
  }
}

class _OutpostCard extends StatelessWidget {
  const _OutpostCard({
    required this.outpost,
    required this.amICreator,
    required this.controller,
  });

  final OutpostModel outpost;
  final bool amICreator;
  final OutpostsController controller;

  @override
  Widget build(BuildContext context) {
    // Built outside the Obx so a join state change only rebuilds the frame
    // and the actions row.
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OutpostHeader(outpost: outpost, amICreator: amICreator),
        if (outpost.subject.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            outpost.subject,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.muted.copyWith(height: 1.35),
          ),
        ],
        const SizedBox(height: 12),
        _OutpostMeta(outpost: outpost),
        if (outpost.tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          TagsWrapper(outpost: outpost),
        ],
        const SizedBox(height: 12),
        Divider(height: 1, thickness: 1, color: AppColors.border),
        const SizedBox(height: 10),
      ],
    );
    return Obx(() {
      final isJoining = controller.joiningOutpostId.value == outpost.uuid;
      return AppCard(
        key: Key(outpost.uuid + "OutpostCard"),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        borderColor: isJoining ? AppColors.primary.withAlpha(140) : null,
        onTap: isJoining ? null : () => _openOutpost(controller, outpost),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            body,
            _OutpostActions(
              outpost: outpost,
              controller: controller,
              amICreator: amICreator,
              isJoining: isJoining,
            ),
          ],
        ),
      );
    });
  }
}

class _OutpostHeader extends StatelessWidget {
  const _OutpostHeader({
    required this.outpost,
    required this.amICreator,
  });

  final OutpostModel outpost;
  final bool amICreator;

  @override
  Widget build(BuildContext context) {
    final isScheduled = outpost.scheduled_for != 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OutpostThumb(outpost: outpost),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                outpost.name,
                key: ValueKey('outpost_name_${outpost.uuid}'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.cardTitle.copyWith(fontSize: 16, height: 1.25),
              ),
              const SizedBox(height: 6),
              _OutpostCreator(outpost: outpost, amICreator: amICreator),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isScheduled)
              _ScheduledBanner(
                outpost: outpost,
                key: Key(outpost.uuid + 'scheduledBanner'),
              ),
            _NumberOfActiveUsers(
              outpost: outpost,
              topGap: isScheduled ? 6 : 0,
              key: Key(outpost.uuid + 'numberOfActiveUsers'),
            ),
          ],
        ),
      ],
    );
  }
}

class _OutpostThumb extends StatelessWidget {
  const _OutpostThumb({required this.outpost});

  final OutpostModel outpost;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        openOutpostImageDialog(
          outpost: outpost,
        );
      },
      child: Container(
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: ColorName.white.withAlpha(20)),
        ),
        child: Img(
          src: Uri.parse(outpost.image).isAbsolute ? outpost.image : '',
          alt: outpost.name,
          ifEmpty: Assets.images.logo.path,
          size: 56,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
        ),
      ),
    );
  }
}

class _OutpostCreator extends StatelessWidget {
  const _OutpostCreator({
    required this.outpost,
    required this.amICreator,
  });

  final OutpostModel outpost;
  final bool amICreator;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: ValueKey('outpost_creator_${outpost.uuid}'),
      children: [
        Img(
          key: ValueKey('outpost_creator_image_${outpost.uuid}'),
          src: outpost.creator_user_image,
          alt: outpost.creator_user_name,
          size: 18,
          borderRadius: const BorderRadius.all(Radius.circular(9)),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'by '),
                TextSpan(
                  text: amICreator ? 'You' : outpost.creator_user_name ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: amICreator ? AppColors.success : ColorName.greyText,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption,
          ),
        ),
      ],
    );
  }
}

class _OutpostMeta extends StatelessWidget {
  const _OutpostMeta({required this.outpost});

  final OutpostModel outpost;

  @override
  Widget build(BuildContext context) {
    final members = outpost.members_count ?? 0;
    final isPublic = outpost.enter_type == FreeOutpostAccessTypes.public;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _MetaChip(
          leading: const Icon(Icons.people_alt_rounded),
          text: '$members ${members == 1 ? 'Member' : 'Members'}',
        ),
        _MetaChip(
          leading: Icon(isPublic ? Icons.public_rounded : Icons.lock_rounded),
          text: parseAccessType(outpost.enter_type),
        ),
        _MetaChip(
          leading: const Icon(Icons.mic_rounded),
          text: parseSpeakerType(outpost.speak_type),
        ),
        if (outpost.is_recordable)
          _MetaChip(
            leading: const Icon(Icons.fiber_manual_record_rounded),
            text: 'Recordable by creator',
            color: AppColors.danger,
          ),
        if (outpost.luma_event_id != null)
          _MetaChip(
            leading: Assets.images.lumaPng.image(width: 13, height: 13),
            text: 'Available on Luma',
          ),
        if (outpost.has_adult_content)
          _MetaChip(
            leading: Assets.images.ageRestricted.image(width: 14, height: 14),
            text: 'Adult content',
            color: AppColors.accent,
          ),
        if (outpost.is_archived)
          const _MetaChip(
            leading: Icon(Icons.inventory_2_outlined),
            text: 'Archived',
          ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.leading,
    required this.text,
    this.color,
  });

  final Widget leading;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color == null ? ColorName.white.withAlpha(10) : fg.withAlpha(22),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTheme.merge(
            data: IconThemeData(size: 13, color: fg),
            child: leading,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutpostActions extends StatelessWidget {
  const _OutpostActions({
    required this.outpost,
    required this.controller,
    required this.amICreator,
    required this.isJoining,
  });

  final OutpostModel outpost;
  final OutpostsController controller;
  final bool amICreator;
  final bool isJoining;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (canShareOutpostUrl(outpost: outpost))
          _CardIconAction(
            icon: Icons.ios_share_rounded,
            tooltip: 'Share',
            onTap: isJoining
                ? null
                : () {
                    analytics.logEvent(
                      name: "share_group",
                      parameters: {
                        "outpost_id": outpost.uuid,
                        "outpost_name": outpost.name,
                      },
                    );
                    Share.share(
                        generateOutpostShareUrl(outpostId: outpost.uuid));
                  },
          ),
        if (canLeaveOutpost(outpost: outpost))
          _CardIconAction(
            icon: Icons.logout_rounded,
            tooltip: 'Leave outpost',
            color: AppColors.danger,
            onTap: isJoining
                ? null
                : () {
                    controller.leaveOutpost(outpost: outpost);
                  },
          ),
        if (canArchiveOutpost(outpost: outpost))
          _CardIconAction(
            icon: outpost.is_archived
                ? Icons.unarchive_outlined
                : Icons.archive_outlined,
            tooltip: outpost.is_archived ? 'Unarchive' : 'Archive',
            color: outpost.is_archived ? null : AppColors.danger,
            onTap: isJoining
                ? null
                : () {
                    controller.toggleArchive(outpost: outpost);
                  },
          ),
        const Spacer(),
        _EnterButton(
          label: amICreator || outpost.i_am_member ? 'Enter' : 'Join',
          loading: isJoining,
          onPressed: () => _openOutpost(controller, outpost),
        ),
      ],
    );
  }
}

class _CardIconAction extends StatelessWidget {
  const _CardIconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? ColorName.white;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        icon: Icon(icon, size: 18),
        style: IconButton.styleFrom(
          fixedSize: const Size.square(38),
          minimumSize: const Size.square(38),
          backgroundColor: color == null ? AppColors.fill : fg.withAlpha(20),
          disabledBackgroundColor: AppColors.fill,
          foregroundColor: fg,
          disabledForegroundColor: fg.withAlpha(90),
          side: BorderSide(
            color: color == null ? AppColors.border : fg.withAlpha(60),
          ),
        ),
      ),
    );
  }
}

class _EnterButton extends StatelessWidget {
  const _EnterButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppGradientShell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: _button(),
    );
  }

  Widget _button() {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(96, 38),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        visualDensity: VisualDensity.compact,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.onPrimary,
        disabledBackgroundColor: Colors.transparent,
        disabledForegroundColor: AppColors.onPrimary,
        shadowColor: Colors.transparent,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      child: loading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.onPrimary,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded, size: 16),
              ],
            ),
    );
  }
}

class _NumberOfActiveUsers extends GetView<OutpostsController> {
  final OutpostModel outpost;
  final double topGap;
  const _NumberOfActiveUsers({
    super.key,
    required this.outpost,
    this.topGap = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final numberOfActiveUsers = outpost.online_users_count ?? 0;
      final liveNumberOfActiveUsers =
          controller.mapOfOnlineUsersInOutposts.value[outpost.uuid];

      final isLive =
          (liveNumberOfActiveUsers ?? 0) != 0 || numberOfActiveUsers != 0;
      final count = liveNumberOfActiveUsers ?? numberOfActiveUsers;
      return AnimatedSwitcher(
        duration: reduceMotion(context)
            ? Duration.zero
            : const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation,
            alignment: Alignment.centerRight,
            child: child,
          ),
        ),
        child: isLive
            ? _liveBadge(count)
            : const SizedBox.shrink(key: ValueKey('offline')),
      );
    });
  }

  Widget _liveBadge(int count) {
    return Padding(
      key: const ValueKey('live'),
      padding: EdgeInsets.only(top: topGap),
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 3, 10, 3),
        decoration: BoxDecoration(
          color: AppColors.live.withAlpha(26),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.live.withAlpha(70)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: RepaintBoundary(
                child: Pulsator(
                  style: PulseStyle(color: AppColors.live),
                  duration: const Duration(seconds: 2),
                  count: 2,
                  repeat: 0,
                  startFromScratch: false,
                  autoStart: true,
                  fit: PulseFit.contain,
                  child: Icon(
                    Icons.circle,
                    size: 6,
                    color: AppColors.live,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 3),
            Text(
              'LIVE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: AppColors.live,
              ),
            ),
            const SizedBox(width: 6),
            AppRollingText(
              '$count',
              alignment: Alignment.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: ColorName.white,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String generateOutpostShareUrl({required String outpostId}) {
  return "${Env.baseDeepLinkUrl}/?link=${Env.baseDeepLinkUrl}${Routes.OUTPOST_DETAIL}?id=${outpostId}&apn=com.web3podium&ibi=com.web3podium";
}

class _ScheduledBanner extends StatelessWidget {
  final OutpostModel outpost;
  const _ScheduledBanner({
    super.key,
    required this.outpost,
  });

  @override
  Widget build(BuildContext context) {
    final passedAtLeast2h =
        outpost.scheduled_for < DateTime.now().millisecondsSinceEpoch - 7200000;
    if (passedAtLeast2h) {
      return const SizedBox.shrink();
    }
    return GetBuilder<GlobalController>(
        id: GlobalUpdateIds.ticker,
        builder: (globalController) {
          final remaining = remainintTimeUntilMilSecondsFormated(
            time: outpost.scheduled_for,
            textIfAlreadyPassed: "Started",
          );
          final isStarted =
              outpost.scheduled_for < DateTime.now().millisecondsSinceEpoch;
          final color = isStarted ? AppColors.success : AppColors.accent;
          final text =
              isStarted ? remaining : 'In ${remaining.replaceAll(' d,', 'd ')}';
          // Ticks every second; keep its repaints off the card.
          return RepaintBoundary(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: color.withAlpha(70)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isStarted
                        ? Icons.play_circle_outline_rounded
                        : Icons.schedule_rounded,
                    size: 13,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}

/// Placeholder card shown while outposts are loading.
class OutpostCardSkeleton extends StatelessWidget {
  const OutpostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      child: Shimmer.fromColors(
        baseColor: ColorName.white.withAlpha(16),
        highlightColor: ColorName.white.withAlpha(40),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SkeletonBox(width: 56, height: 56, radius: AppRadius.md),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBox(width: 180, height: 14),
                      SizedBox(height: 10),
                      _SkeletonBox(width: 110, height: 10),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                _SkeletonBox(width: 80, height: 22, radius: 999),
                SizedBox(width: 6),
                _SkeletonBox(width: 64, height: 22, radius: 999),
                SizedBox(width: 6),
                _SkeletonBox(width: 72, height: 22, radius: 999),
              ],
            ),
            SizedBox(height: 18),
            Row(
              children: [
                _SkeletonBox(width: 38, height: 38, radius: 19),
                Spacer(),
                _SkeletonBox(width: 96, height: 38, radius: AppRadius.sm),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 6,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ColorName.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class TagsWrapper extends StatelessWidget {
  const TagsWrapper({
    super.key,
    required this.outpost,
  });

  final OutpostModel outpost;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) {},
      onHorizontalDragUpdate: (_) {},
      onHorizontalDragEnd: (_) {},
      child: SizedBox(
        height: 26,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final tag in outpost.tags) SingleTag(tagName: tag),
            ],
          ),
        ),
      ),
    );
  }
}

class SingleTag extends StatelessWidget {
  final String tagName;
  const SingleTag({
    required this.tagName,
    super.key,
  });

  static List<Color> get _palette => [
        AppColors.primary,
        _soften(AppColors.violet),
        _soften(AppColors.magenta),
      ];

  static Color _soften(Color color) => AppPalette.current.isLight
      ? color
      : Color.lerp(color, Colors.white, 0.35)!;

  Color get _color {
    final sum = tagName.codeUnits.fold<int>(0, (a, b) => a + b);
    return _palette[sum % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(55)),
      ),
      child: Text(
        tagName,
        maxLines: 1,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

String parseSpeakerType(String? speakerType) {
  switch (speakerType) {
    case null:
      return "Everyone";
    case FreeOutpostSpeakerTypes.everyone:
      return "Everyone";
    case FreeOutpostSpeakerTypes.invited_users:
      return "Only Invited Users";
    case BuyableTicketTypes.onlyArenaTicketHolders:
      return "Only Arena Ticket Holders";
    case BuyableTicketTypes.onlyFriendTechTicketHolders:
      return "Only Friendtech Key Holders";
    case BuyableTicketTypes.onlyPodiumPassHolders:
      return "Only Podium Pass Holders";

    default:
      return "Unknown";
  }
}

String parseAccessType(String? accessType) {
  switch (accessType) {
    case null:
      return "Public";
    case FreeOutpostAccessTypes.public:
      return "Public";
    case FreeOutpostAccessTypes.onlyLink:
      return "Only By Link";
    case FreeOutpostAccessTypes.invited_users:
      return "Only Invited Users";
    case BuyableTicketTypes.onlyArenaTicketHolders:
      return "Only Arena Ticket Holders";
    case BuyableTicketTypes.onlyFriendTechTicketHolders:
      return "Only Friendtech Key Holders";
    case BuyableTicketTypes.onlyPodiumPassHolders:
      return "Only Podium Pass Holders";
    default:
      return "Public";
  }
}

canShareOutpostUrl({required OutpostModel outpost}) {
  final GlobalController globalController = Get.find();
  if (globalController.myUserInfo.value == null) {
    return false;
  }
  final iAmCreator = outpost.creator_user_uuid == myId;
  if (iAmCreator) {
    return true;
  }
  if (outpost.enter_type == FreeOutpostAccessTypes.public) {
    return true;
  }
  if (outpost.enter_type == FreeOutpostAccessTypes.onlyLink) {
    if (outpost.i_am_member) {
      return true;
    }
  }
  return false;
}

canLeaveOutpost({required OutpostModel outpost}) {
  final GlobalController globalController = Get.find();
  if (globalController.myUserInfo.value == null) {
    return false;
  }
  final iAmCreator = outpost.creator_user_uuid == myId;
  final amIMember = outpost.i_am_member;
  if (iAmCreator) {
    return false;
  }
  return amIMember;
}

canArchiveOutpost({required OutpostModel outpost}) {
  final GlobalController globalController = Get.find();
  if (globalController.myUserInfo.value == null) {
    return false;
  }
  final iAmCreator = outpost.creator_user_uuid == myId;
  return iAmCreator;
}
