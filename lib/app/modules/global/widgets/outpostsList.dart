import 'package:enhanced_paginated_view/enhanced_paginated_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/createOutpost/controllers/create_outpost_controller.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/time.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/modules/global/widgets/loading_widget.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/env.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/utils/analytics.dart';
import 'package:podium/utils/styles.dart';
import 'package:pulsator/pulsator.dart';
import 'package:rotated_corner_decoration/rotated_corner_decoration.dart';
import 'package:share_plus/share_plus.dart';
import 'package:visibility_detector/visibility_detector.dart';

enum ListPage { all, my, search }

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
      final allOutposts = controller.outposts.value;
      final myOutposts = controller.myOutposts.value;
      final lastPageReachedForAllOutposts =
          controller.lastPageReachedForAllOutposts.value;
      final lastPageReachedForMyOutposts =
          controller.lastPageReachedForMyOutposts.value;

      // Show loading placeholders if no data is available yet
      if ((listPage == ListPage.all && allOutposts.isEmpty) ||
          (listPage == ListPage.my && myOutposts.isEmpty)) {
        return ListView.builder(
          controller: scrollController,
          itemCount: 3, // Reduced from 5 to 3
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
          cacheExtent: 200,
          itemBuilder: (context, index) {
            return Container(
              height: 180,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: ColorName.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ColorName.cardBackground,
                  width: 1.0,
                ),
              ),
              child: const Center(
                child: LoadingWidget(),
              ),
            );
          },
        );
      }

      Widget listWidget;
      if (outpostsList != null) {
        List<OutpostModel> listToShow = outpostsList!;

        listWidget = ListView.builder(
          controller: scrollController,
          itemCount: listToShow.length,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
          cacheExtent: 200,
          itemBuilder: (context, index) {
            final outpost = listToShow[index];
            return _SingleOutpost(
              key: ValueKey(outpost.uuid),
              controller: controller,
              amICreator: outpost.creator_user_uuid == myId,
              outpost: outpost,
            );
          },
        );
      } else {
        List<OutpostModel> listToShow = listPage == ListPage.all
            ? allOutposts.values.toList()
            : myOutposts.values.toList();

        listWidget = EnhancedPaginatedView(
          hasReachedMax: listPage == ListPage.all
              ? lastPageReachedForAllOutposts
              : lastPageReachedForMyOutposts,
          onLoadMore: (int page) {
            listPage == ListPage.all
                ? controller.fetchAllOutpostsPage(page - 1)
                : controller.fetchMyOutpostsPage(page - 1);
          },
          onRefresh: () async {
            listPage == ListPage.all
                ? controller.fetchAllOutpostsPage(0)
                : controller.fetchMyOutpostsPage(0);
          },
          refreshBuilder: (context, onRefresh, child) {
            return RefreshIndicator(
              color: Colors.white,
              backgroundColor: ColorName.primaryBlue,
              onRefresh: onRefresh,
              child: child,
            );
          },
          itemsPerPage: numberOfOutpostsPerPage,
          delegate: EnhancedDelegate(
            listOfData: listToShow,
            status: EnhancedStatus.loaded,
          ),
          builder: (items, physics, reverse, shrinkWrap) {
            return ListView.builder(
              controller: scrollController,
              itemCount: items.length,
              physics: physics,
              reverse: reverse,
              shrinkWrap: shrinkWrap,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: false,
              cacheExtent: 200,
              itemBuilder: (context, index) {
                final outpost = items[index];
                return _SingleOutpost(
                  key: ValueKey(outpost.uuid),
                  controller: controller,
                  amICreator: outpost.creator_user_uuid == myId,
                  outpost: outpost,
                );
              },
            );
          },
        );
      }

      return RawScrollbar(
        thumbColor: ColorName.secondaryBlue.withAlpha(128),
        trackColor: ColorName.cardBackground,
        radius: const Radius.circular(4),
        thickness: 4,
        controller: scrollController,
        child: listWidget,
      );
    });
  }
}

class _SingleOutpost extends StatelessWidget {
  const _SingleOutpost({
    super.key,
    required this.controller,
    required this.amICreator,
    required this.outpost,
  });

  final OutpostsController controller;
  final bool amICreator;
  final OutpostModel outpost;

  @override
  Widget build(BuildContext context) {
    final isScheduled = outpost.scheduled_for != 0;
    return VisibilityDetector(
      key: Key('outpost_${outpost.uuid}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction == 0) {
          controller.removeOutpostFromView(outpost.uuid);
        } else {
          controller.addOutpostToView(outpost.uuid);
        }
      },
      child: Stack(
        children: [
          GestureDetector(
            key: Key(outpost.uuid + "OutpostCard"),
            onTap: () async {
              if (!wsClient.connected) {
                await HttpApis.podium.connectToWebSocket();
              }

              controller.joinOutpostAndOpenOutpostDetailPage(
                outpostId: outpost.uuid,
              );
            },
            child: _OutpostCard(
              outpost: outpost,
              amICreator: amICreator,
              controller: controller,
            ),
          ),
          if (isScheduled)
            _ScheduledBanner(
              outpost: outpost,
              key: Key(outpost.uuid + 'scheduledBanner'),
            ),
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: _OutpostActions(
                outpost: outpost,
                controller: controller,
              ),
            ),
          ),
        ],
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
    return Obx(() {
      final joiningOutpostId = controller.joiningOutpostId.value;
      return Stack(
        children: [
          Container(
            width: Get.width - 2,
            margin: const EdgeInsets.only(left: 1, bottom: 4, top: 2),
            decoration: BoxDecoration(
              color: ColorName.cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                width: 1.0,
                color: ColorName.cardBackground,
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(
                  color: ColorName.cardBackground,
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OutpostInfo(
                    outpost: outpost,
                    amICreator: amICreator,
                  ),
                  if (outpost.has_adult_content)
                    Positioned(
                      child: Assets.images.ageRestricted.image(
                        width: 24,
                        height: 24,
                      ),
                      left: 0,
                      bottom: outpost.tags.isEmpty ? 0 : 30,
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 1,
            right: 1,
            top: 2,
            bottom: 4,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: joiningOutpostId == outpost.uuid ? 1.0 : 0.0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(128),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: LoadingWidget(
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _OutpostInfo extends StatelessWidget {
  const _OutpostInfo({
    required this.outpost,
    required this.amICreator,
  });

  final OutpostModel outpost;
  final bool amICreator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OutpostName(outpost: outpost),
        _OutpostCreator(
          outpost: outpost,
          amICreator: amICreator,
        ),
        space10,
        _OutpostDetails(outpost: outpost),
        if (outpost.tags.isNotEmpty) TagsWrapper(outpost: outpost),
      ],
    );
  }
}

class _OutpostName extends StatelessWidget {
  const _OutpostName({
    required this.outpost,
  });

  final OutpostModel outpost;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('outpost_name_${outpost.uuid}'),
      constraints: BoxConstraints(
        maxWidth: Get.width - 75,
      ),
      child: Text(
        outpost.name,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          overflow: TextOverflow.ellipsis,
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
    return Container(
      key: ValueKey('outpost_creator_${outpost.uuid}'),
      constraints: BoxConstraints(
        maxWidth: Get.width - 75,
      ),
      child: Row(
        children: [
          Flexible(
              child: RichText(
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                const TextSpan(
                  text: "Created by",
                  style: TextStyle(
                    fontSize: 10,
                    color: ColorName.greyText,
                  ),
                ),
                TextSpan(
                  text: " ${amICreator ? "You" : outpost.creator_user_name}",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    overflow: TextOverflow.ellipsis,
                    color: amICreator ? Colors.green[200] : Colors.blue[200],
                  ),
                ),
              ],
            ),
          )),
          space5,
          Img(
            key: ValueKey('outpost_creator_image_${outpost.uuid}'),
            src: outpost.creator_user_image,
            alt: outpost.creator_user_name,
            size: 12,
          )
        ],
      ),
    );
  }
}

class _OutpostDetails extends StatelessWidget {
  const _OutpostDetails({
    required this.outpost,
  });

  final OutpostModel outpost;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Img(
          src: Uri.parse(outpost.image).isAbsolute ? outpost.image : '',
          alt: outpost.name,
          ifEmpty: Assets.images.logo.path,
        ),
        space10,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (outpost.is_recordable)
              const Row(
                children: [
                  Icon(
                    Icons.circle,
                    color: Colors.redAccent,
                    size: 12,
                  ),
                  space5,
                  Text(
                    "Recordable by Creator",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: ColorName.greyText,
                    ),
                  ),
                ],
              ),
            if (outpost.is_recordable) space5,
            _OutpostDetailRow(
              icon: Icons.subject,
              text: outpost.subject.isEmpty ? "No Subject" : outpost.subject,
            ),
            space5,
            _OutpostDetailRow(
              icon: Icons.lock,
              text: parseAccessType(outpost.enter_type),
            ),
            space5,
            _OutpostDetailRow(
              icon: Icons.mic,
              text: parseSpeakerType(outpost.speak_type),
            ),
            space5,
            Row(
              children: [
                _OutpostDetailRow(
                  icon: Icons.group,
                  text: "${outpost.members_count ?? 0} Members",
                ),
                _NumberOfActiveUsers(
                  outpost: outpost,
                  key: Key(outpost.uuid + 'numberOfActiveUsers'),
                ),
              ],
            ),
            if (outpost.luma_event_id != null) ...[
              space5,
              Row(
                children: [
                  Assets.images.lumaPng.image(
                    width: 14,
                    height: 14,
                  ),
                  space5,
                  const Text(
                    "Available on Luma",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: ColorName.greyText,
                    ),
                  ),
                ],
              ),
            ]
          ],
        )
      ],
    );
  }
}

class _OutpostDetailRow extends StatelessWidget {
  const _OutpostDetailRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: ColorName.greyText,
          size: 14,
        ),
        space5,
        Container(
          constraints: BoxConstraints(
            maxWidth: Get.width - 170,
          ),
          child: Text(
            " $text",
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: ColorName.greyText,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
      ],
    );
  }
}

class _OutpostActions extends StatelessWidget {
  const _OutpostActions({
    required this.outpost,
    required this.controller,
  });

  final OutpostModel outpost;
  final OutpostsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isJoining = controller.joiningOutpostId.value == outpost.uuid;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (canShareOutpostUrl(outpost: outpost))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: IconButton(
                onPressed: isJoining
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
                icon: Icon(
                  Icons.share,
                  color: isJoining
                      ? ColorName.greyText.withOpacity(0.5)
                      : ColorName.greyText,
                ),
              ),
            ),
          if (canLeaveOutpost(outpost: outpost))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: IconButton(
                onPressed: isJoining
                    ? null
                    : () {
                        controller.leaveOutpost(outpost: outpost);
                      },
                icon: Icon(
                  Icons.exit_to_app,
                  color: isJoining ? Colors.red.withOpacity(0.5) : Colors.red,
                ),
              ),
            ),
          if (canArchiveOutpost(outpost: outpost))
            IconButton(
              onPressed: isJoining
                  ? null
                  : () {
                      controller.toggleArchive(outpost: outpost);
                    },
              icon: Icon(
                outpost.is_archived ? Icons.unarchive : Icons.archive,
                color: isJoining
                    ? (outpost.is_archived
                        ? ColorName.greyText.withOpacity(0.5)
                        : Colors.red.withOpacity(0.5))
                    : (outpost.is_archived ? ColorName.greyText : Colors.red),
              ),
            )
        ],
      );
    });
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
      final numberOfActiveUsers = outpost.online_users_count ?? 0;
      final liveNumberOfActiveUsers =
          controller.mapOfOnlineUsersInOutposts.value[outpost.uuid];

      if ((liveNumberOfActiveUsers ?? 0) == 0 && numberOfActiveUsers == 0) {
        return const SizedBox();
      }

      final count = liveNumberOfActiveUsers ?? numberOfActiveUsers;
      return Container(
        width: 25,
        height: 25,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Pulsator(
              style: const PulseStyle(color: Colors.red),
              duration: const Duration(seconds: 2),
              count: 3, // Reduced from 5 to 3
              repeat: 0,
              startFromScratch: false,
              autoStart: true,
              fit: PulseFit.contain,
              child: SizedBox(
                width: 25,
                height: 25,
                child: Center(
                  child: Text(
                    "$count",
                    style: const TextStyle(
                      height: 0.8,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
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
      return const SizedBox();
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
          final size = 55;
          final numberOfDays = int.tryParse(remaining.split('d,')[0]) ?? 0;
          final remainingText = remaining.contains('d,')
              ? remaining
                  .split('d,')
                  .join('d\n')
                  .replaceAll('d', 'day${numberOfDays > 1 ? 's' : ''}')
              : remaining;
          return Positioned(
            right: 1,
            top: 2,
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topRight: const Radius.circular(8),
                ),
              ),
              child: IgnorePointer(
                child: Container(
                  foregroundDecoration: RotatedCornerDecoration.withColor(
                    color: isStarted ? Colors.green : Colors.red,
                    spanBaselineShift: remainingText.contains('days') ? 2 : 4,
                    badgeSize: Size(size.toDouble(), size.toDouble()),
                    badgeCornerRadius: const Radius.circular(0),
                    badgePosition: BadgePosition.topEnd,
                    textSpan: TextSpan(
                      text: remainingText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w400,
                        shadows: [
                          const BoxShadow(
                              color: Colors.yellowAccent, blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                  height: size.toDouble(),
                  width: size.toDouble(),
                ),
              ),
            ),
          );
        });
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
    return Container(
      margin: const EdgeInsets.only(top: 8),
      height: 24,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: Get.width - 100,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: outpost.tags
                .map((e) => SingleTag(
                      tagName: e,
                    ))
                .toList(),
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: ColorName.greyText.withAlpha(51), // 0.2 opacity * 255 = 51
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
      child: Text(
        tagName,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: ColorName.greyText,
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
    case FreeOutpostSpeakerTypes.invitees:
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
    case FreeOutpostAccessTypes.invitees:
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
