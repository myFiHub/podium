import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:podium/app/modules/createOutpost/controllers/create_outpost_controller.dart';
import 'package:podium/app/modules/createOutpost/outpost_types.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/popUpsAndModals/outpostImage.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/data/repositories/repositories.dart';
import 'package:podium/env.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/utils/analytics.dart';
import 'package:podium/utils/palette.dart';
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
  final EdgeInsets padding;

  /// Scrolls with the list, above the first outpost.
  final Widget? header;

  /// Runs alongside the first-page reload on pull-to-refresh.
  final Future<void> Function()? onRefresh;

  /// Called as an [outpostsList] scrolls near its end, to load more.
  final VoidCallback? onNearEnd;
  const OutpostsList({
    super.key,
    this.outpostsList,
    this.scrollController,
    required this.listPage,
    this.padding = _listPadding,
    this.header,
    this.onRefresh,
    this.onNearEnd,
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
        final header = this.header;
        if (header != null) {
          return ListView(
            controller: scrollController,
            padding: padding,
            children: [
              header,
              for (var i = 0; i < 3; i++) const OutpostCardSkeleton(),
            ],
          );
        }
        return ListView.builder(
          controller: scrollController,
          padding: padding,
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
          controller: scrollController,
          padding: padding,
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
        final onNearEnd = this.onNearEnd;
        if (onNearEnd != null) {
          listWidget = NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification &&
                  notification.metrics.axis == Axis.vertical &&
                  notification.metrics.extentAfter <=
                      _PaginatedOutpostsState._loadMoreThreshold) {
                onNearEnd();
              }
              return false;
            },
            child: listWidget,
          );
        }
      } else {
        listWidget = _PaginatedOutposts(
          items: pageOutposts.values.toList(),
          hasReachedMax: lastPageReached,
          scrollController: scrollController,
          controller: controller,
          padding: padding,
          header: header,
          onRefresh: onRefresh,
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
    required this.padding,
    this.header,
    this.onRefresh,
  });

  final List<OutpostModel> items;
  final bool hasReachedMax;
  final ScrollController? scrollController;
  final OutpostsController controller;
  final Future<void> Function(int page) fetchPage;
  final EdgeInsets padding;
  final Widget? header;
  final Future<void> Function()? onRefresh;

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
    final header = widget.header;
    final offset = header == null ? 0 : 1;
    return RefreshIndicator(
      color: AppColors.onPrimary,
      backgroundColor: ColorName.primaryBlue,
      onRefresh: () async {
        final extra = widget.onRefresh;
        await Future.wait([widget.fetchPage(0), if (extra != null) extra()]);
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: ListView.builder(
          controller: widget.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: widget.padding,
          itemCount: items.length + offset,
          addAutomaticKeepAlives: false,
          itemBuilder: (context, i) {
            if (header != null && i == 0) return header;
            final index = i - offset;
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
    await Get.find<AuthRepository>().reconnectSocket();
  }
  controller.joinOutpostAndOpenOutpostDetailPage(
    outpostId: outpost.uuid,
  );
}

/// Joins [outpost] and opens its page, the same way tapping a list card does.
Future<void> openOutpost(OutpostModel outpost) =>
    _openOutpost(Get.find<OutpostsController>(), outpost);

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
    final access = _AccessStyle.of(outpost.enter_type);
    // Built outside the Obx so a join or live state change only rebuilds the
    // frame and the actions row.
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OutpostHeader(
            outpost: outpost, amICreator: amICreator, access: access),
        if (outpost.subject.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            outpost.subject,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.muted.copyWith(height: 1.4),
          ),
        ],
        if (outpost.scheduled_for != 0)
          _ScheduleStrip(
            outpost: outpost,
            key: Key('${outpost.uuid}scheduledBanner'),
          ),
        const SizedBox(height: 12),
        _OutpostMeta(outpost: outpost, access: access),
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
      final isLive = _onlineCount(controller, outpost) > 0;
      final tone = outpost.is_archived
          ? AppColors.textFaint
          : isLive
              ? AppColors.live
              : access.color;
      return AppCard(
        key: Key("${outpost.uuid}OutpostCard"),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        gradient: _cardWash(tone),
        borderGradient: _cardBorder(tone),
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
              isLive: isLive,
            ),
          ],
        ),
      );
    });
  }
}

int _onlineCount(OutpostsController controller, OutpostModel outpost) =>
    controller.mapOfOnlineUsersInOutposts.value[outpost.uuid] ??
    outpost.online_users_count ??
    0;

/// Glass fill with a soft glow of [tone] from the top-left corner.
LinearGradient _cardWash(Color tone) {
  final base = AppColors.surfaceGlass;
  final glow = AppPalette.current.isLight ? 18 : 30;
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.alphaBlend(tone.withAlpha(glow), base), base],
    stops: const [0, 0.6],
  );
}

LinearGradient _cardBorder(Color tone) => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        tone.withAlpha(160),
        tone.withAlpha(40),
        ColorName.white.withAlpha(14),
        tone.withAlpha(70),
      ],
      stops: const [0, 0.35, 0.7, 1],
    );

Color _softenOnDark(Color color) =>
    AppPalette.current.isLight ? color : Color.lerp(color, Colors.white, 0.35)!;

/// Icon, label and tint that identify how an outpost is entered.
class _AccessStyle {
  const _AccessStyle(this.icon, this.label, this.color);

  final IconData icon;
  final String label;
  final Color color;

  static _AccessStyle of(String? enterType) => switch (enterType) {
        FreeOutpostAccessTypes.onlyLink => _AccessStyle(
            Icons.link_rounded,
            'Link only',
            _softenOnDark(AppColors.violet),
          ),
        FreeOutpostAccessTypes.invited_users => _AccessStyle(
            Icons.lock_person_rounded,
            'Invite only',
            _softenOnDark(AppColors.magenta),
          ),
        BuyableTicketTypes.onlyArenaTicketHolders => _AccessStyle(
            Icons.confirmation_number_rounded,
            'Arena ticket',
            AppColors.accent,
          ),
        BuyableTicketTypes.onlyFriendTechTicketHolders => _AccessStyle(
            Icons.key_rounded,
            'Friendtech key',
            AppColors.accent,
          ),
        BuyableTicketTypes.onlyPodiumPassHolders => _AccessStyle(
            Icons.workspace_premium_rounded,
            'Podium Pass',
            AppColors.accent,
          ),
        _ => _AccessStyle(Icons.public_rounded, 'Public', AppColors.primary),
      };
}

String _speakLabel(String? speakType) => switch (speakType) {
      FreeOutpostSpeakerTypes.invited_users => 'Invited speakers',
      BuyableTicketTypes.onlyArenaTicketHolders ||
      BuyableTicketTypes.onlyFriendTechTicketHolders ||
      BuyableTicketTypes.onlyPodiumPassHolders =>
        'Holders speak',
      _ => 'Open mic',
    };

class _OutpostHeader extends StatelessWidget {
  const _OutpostHeader({
    required this.outpost,
    required this.amICreator,
    required this.access,
  });

  final OutpostModel outpost;
  final bool amICreator;
  final _AccessStyle access;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OutpostThumb(outpost: outpost, access: access),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      outpost.name,
                      key: ValueKey('outpost_name_${outpost.uuid}'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.cardTitle
                          .copyWith(fontSize: 16, height: 1.25),
                    ),
                  ),
                  if (outpost.is_archived)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: _ArchivedPill(),
                    )
                  else
                    _NumberOfActiveUsers(
                      outpost: outpost,
                      key: Key('${outpost.uuid}numberOfActiveUsers'),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              _OutpostCreator(outpost: outpost, amICreator: amICreator),
            ],
          ),
        ),
      ],
    );
  }
}

const _greyscale = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0,
]);

class _OutpostThumb extends StatelessWidget {
  const _OutpostThumb({required this.outpost, required this.access});

  final OutpostModel outpost;
  final _AccessStyle access;

  @override
  Widget build(BuildContext context) {
    final color = outpost.is_archived ? AppColors.textFaint : access.color;
    Widget image = Img(
      src: Uri.parse(outpost.image).isAbsolute ? outpost.image : '',
      alt: outpost.name,
      ifEmpty: Assets.images.logo.path,
      size: 56,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
    );
    if (outpost.is_archived) {
      image = ColorFiltered(colorFilter: _greyscale, child: image);
    }
    return GestureDetector(
      onTap: () {
        openOutpostImageDialog(
          outpost: outpost,
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: color.withAlpha(70)),
            ),
            child: image,
          ),
          Positioned(
            right: -6,
            bottom: -6,
            child: Tooltip(
              message: access.label,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    color.withAlpha(56),
                    AppColors.surface,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
                child: Icon(access.icon, size: 12, color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchivedPill extends StatelessWidget {
  const _ArchivedPill();

  @override
  Widget build(BuildContext context) {
    final color = AppColors.textFaint;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            'Archived',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
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
              children: amICreator
                  ? [
                      TextSpan(
                        text: 'Hosted by you',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ]
                  : [
                      const TextSpan(text: 'by '),
                      TextSpan(
                        text: outpost.creator_user_name ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption,
          ),
        ),
        if (!amICreator && outpost.i_am_member) ...[
          const SizedBox(width: 6),
          const _JoinedBadge(),
        ],
      ],
    );
  }
}

class _JoinedBadge extends StatelessWidget {
  const _JoinedBadge();

  @override
  Widget build(BuildContext context) {
    final color = AppColors.primary;
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            'JOINED',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutpostMeta extends StatelessWidget {
  const _OutpostMeta({required this.outpost, required this.access});

  final OutpostModel outpost;
  final _AccessStyle access;

  @override
  Widget build(BuildContext context) {
    final members = outpost.members_count ?? 0;
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _AccessPill(
          access: access,
          muted: outpost.is_archived,
        ),
        _MetaItem(
          icon: Icons.people_alt_rounded,
          text: '$members ${members == 1 ? 'member' : 'members'}',
        ),
        _MetaItem(
          icon: Icons.mic_rounded,
          text: _speakLabel(outpost.speak_type),
        ),
        if (outpost.is_recordable ||
            outpost.luma_event_id != null ||
            outpost.has_adult_content)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (outpost.is_recordable)
                _FlagIcon(
                  tooltip: 'Recordable by creator',
                  color: AppColors.danger,
                  child: Icon(
                    Icons.radio_button_checked_rounded,
                    size: 13,
                    color: AppColors.danger,
                  ),
                ),
              if (outpost.luma_event_id != null)
                _FlagIcon(
                  tooltip: 'Available on Luma',
                  child: Assets.images.lumaPng.image(width: 13, height: 13),
                ),
              if (outpost.has_adult_content)
                _FlagIcon(
                  tooltip: 'Adult content',
                  color: AppColors.accent,
                  child:
                      Assets.images.ageRestricted.image(width: 14, height: 14),
                ),
            ],
          ),
      ],
    );
  }
}

class _AccessPill extends StatelessWidget {
  const _AccessPill({required this.access, required this.muted});

  final _AccessStyle access;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final color = muted ? AppColors.textFaint : access.color;
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 4, 9, 4),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(64)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(access.icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            access.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textFaint),
        const SizedBox(width: 5),
        Text(
          text,
          maxLines: 1,
          style: AppText.caption.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _FlagIcon extends StatelessWidget {
  const _FlagIcon({
    required this.tooltip,
    required this.child,
    this.color,
  });

  final String tooltip;
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color?.withAlpha(24) ?? AppColors.fill,
            shape: BoxShape.circle,
          ),
          child: child,
        ),
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
    required this.isLive,
  });

  final OutpostModel outpost;
  final OutpostsController controller;
  final bool amICreator;
  final bool isJoining;
  final bool isLive;

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
                    SharePlus.instance.share(
                      ShareParams(
                        text: generateOutpostShareUrl(outpostId: outpost.uuid),
                      ),
                    );
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
          icon: isLive ? Icons.graphic_eq_rounded : Icons.arrow_forward_rounded,
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
    required this.icon,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
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
                Icon(icon, size: 16),
              ],
            ),
    );
  }
}

class _NumberOfActiveUsers extends GetView<OutpostsController> {
  final OutpostModel outpost;
  const _NumberOfActiveUsers({
    super.key,
    required this.outpost,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final count = _onlineCount(controller, outpost);
      final isLive = count > 0;
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
    return KeyedSubtree(
      key: const ValueKey('live'),
      child: Container(
        margin: const EdgeInsets.only(left: 8),
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
  return "${Env.baseDeepLinkUrl}/?link=${Env.baseDeepLinkUrl}${Routes.OUTPOST_DETAIL}?id=$outpostId&apn=com.web3podium&ibi=com.web3podium";
}

/// Calendar strip for scheduled outposts: the date, a friendly day/time and a
/// live countdown. Hidden two hours after the start time.
class _ScheduleStrip extends StatelessWidget {
  final OutpostModel outpost;
  const _ScheduleStrip({
    super.key,
    required this.outpost,
  });

  static const _hideAfter = Duration(hours: 2);

  @override
  Widget build(BuildContext context) {
    final at = DateTime.fromMillisecondsSinceEpoch(outpost.scheduled_for);
    if (DateTime.now().difference(at) > _hideAfter) {
      return const SizedBox.shrink();
    }
    return GetBuilder<GlobalController>(
        id: GlobalUpdateIds.ticker,
        builder: (globalController) {
          final now = DateTime.now();
          if (now.difference(at) > _hideAfter) {
            return const SizedBox.shrink();
          }
          final isStarted = !at.isAfter(now);
          final color = isStarted ? AppColors.success : AppColors.accent;
          // Ticks every second; keep its repaints off the card.
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: RepaintBoundary(
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
                decoration: BoxDecoration(
                  color: color.withAlpha(18),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: color.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    _DateTile(at: at, color: color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isStarted ? 'STARTED' : 'SCHEDULED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _whenLabel(at, now),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: ColorName.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isStarted
                              ? Icons.play_circle_outline_rounded
                              : Icons.hourglass_bottom_rounded,
                          size: 14,
                          color: color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isStarted
                              ? _agoLabel(now.difference(at))
                              : 'in ${_countdownLabel(at.difference(now))}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.at, required this.color});

  final DateTime at;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat.MMM().format(at).toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: color,
            ),
          ),
          Text(
            '${at.day}',
            style: TextStyle(
              fontSize: 15,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: ColorName.white,
            ),
          ),
        ],
      ),
    );
  }
}

String _whenLabel(DateTime at, DateTime now) {
  final time = DateFormat.jm().format(at);
  // Rounded so a DST shift between the two dates can't skew the day count.
  final days =
      (DateUtils.dateOnly(at).difference(DateUtils.dateOnly(now)).inHours / 24)
          .round();
  final day = switch (days) {
    0 => 'Today',
    1 => 'Tomorrow',
    -1 => 'Yesterday',
    > 1 && < 7 => DateFormat.EEEE().format(at),
    _ when at.year == now.year => DateFormat.MMMd().format(at),
    _ => DateFormat.yMMMd().format(at),
  };
  return '$day · $time';
}

String _countdownLabel(Duration d) {
  if (d.inDays > 0) return '${d.inDays}d ${d.inHours.remainder(24)}h';
  if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  final seconds = d.inSeconds.remainder(60);
  if (d.inMinutes > 0) return '${d.inMinutes}m ${seconds}s';
  return '${seconds}s';
}

String _agoLabel(Duration d) {
  if (d.inMinutes < 1) return 'just now';
  if (d.inHours < 1) return '${d.inMinutes}m ago';
  return '${d.inHours}h ${d.inMinutes.remainder(60)}m ago';
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

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '#',
              style: TextStyle(color: AppColors.textFaint),
            ),
            TextSpan(text: tagName),
          ],
        ),
        maxLines: 1,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
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

bool canShareOutpostUrl({required OutpostModel outpost}) {
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

bool canLeaveOutpost({required OutpostModel outpost}) {
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

bool canArchiveOutpost({required OutpostModel outpost}) {
  final GlobalController globalController = Get.find();
  if (globalController.myUserInfo.value == null) {
    return false;
  }
  final iAmCreator = outpost.creator_user_uuid == myId;
  return iAmCreator;
}
