import 'package:enhanced_paginated_view/enhanced_paginated_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:glow_container/glow_container.dart';
import 'package:podium/app/modules/createOutpost/controllers/create_outpost_controller.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/time.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/env.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/gen/colors.gen.dart';
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

      Widget listWidget;
      if (outpostsList != null) {
        List<OutpostModel> listToShow = outpostsList!;

        listWidget = ListView.builder(
          controller: scrollController,
          itemCount: listToShow.length,
          itemBuilder: (context, index) {
            final outpost = listToShow[index];
            return _SingleOutpost(
              key: Key(outpost.uuid),
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
              itemBuilder: (context, index) {
                final outpost = items[index];
                return _SingleOutpost(
                  key: Key(outpost.uuid),
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
          // When the outpost is not visible, remove it from view
          controller.removeOutpostFromView(outpost.uuid);
        } else {
          // When the outpost becomes visible, add it to view
          controller.addOutpostToView(outpost.uuid);
        }
      },
      child: GestureDetector(
        key: Key(outpost.uuid + "OutpostCard"),
        onTap: () async {
          controller.joinOutpostAndOpenOutpostDetailPage(
            outpostId: outpost.uuid,
          );
        },
        child: Stack(
          children: [
            space16,
            Obx(
              () {
                final joiningOutpostId = controller.joiningOutpostId.value;
                return GlowContainer(
                  glowRadius: 4,
                  gradientColors: const [
                    ColorName.primaryBlue,
                    ColorName.secondaryBlue
                  ],
                  rotationDuration: const Duration(seconds: 1),
                  glowLocation: GlowLocation.outerOnly,
                  containerOptions: ContainerOptions(
                    width: Get.width - 2,
                    borderRadius: 8,
                    margin: const EdgeInsets.only(left: 1, bottom: 8, top: 2),
                    backgroundColor: ColorName.cardBackground,
                    borderSide: const BorderSide(
                      width: 1.0,
                      color: ColorName.cardBackground,
                    ),
                  ),
                  transitionDuration: const Duration(milliseconds: 200),
                  showAnimatedBorder: joiningOutpostId == outpost.uuid,
                  child: Container(
                    decoration: const BoxDecoration(
                        color: ColorName.cardBackground,
                        borderRadius: BorderRadius.all(Radius.circular(8))),
                    margin: const EdgeInsets.only(left: 0, right: 0, bottom: 0),
                    padding: const EdgeInsets.all(8),
                    child: Stack(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 270,
                                  ),
                                  //width: Get.width - 200,
                                  child: Text(
                                    outpost.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                Container(
                                    constraints: const BoxConstraints(
                                      maxWidth: 270,
                                    ),
                                    //width: Get.width - 300,
                                    child: Row(
                                      children: [
                                        RichText(
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
                                                text:
                                                    " ${amICreator ? "You" : outpost.creator_user_name}",
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                  color: amICreator
                                                      ? Colors.green[200]
                                                      : Colors.blue[200],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        space5,
                                        Img(
                                          src: outpost.creator_user_image,
                                          size: 12,
                                        )
                                      ],
                                    )),
                                space10,
                                Row(
                                  children: [
                                    Img(
                                      src: Uri.parse(outpost.image).isAbsolute
                                          ? outpost.image
                                          : '',
                                      alt: outpost.name,
                                      ifEmpty: Assets.images.logo.path,
                                    ),
                                    space10,
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.subject,
                                              color: ColorName.greyText,
                                              size: 14,
                                            ),
                                            Container(
                                              constraints: const BoxConstraints(
                                                maxWidth: 180,
                                              ),
                                              // width: Get.width - 200,
                                              child: Text(
                                                " ${outpost.subject.isEmpty ? "No Subject" : outpost.subject}",
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w400,
                                                  color: ColorName.greyText,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                        space5,
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.lock,
                                              color: ColorName.greyText,
                                              size: 14,
                                            ),
                                            space5,
                                            Text(
                                              parseAccessType(
                                                  outpost.enter_type),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w400,
                                                color: ColorName.greyText,
                                              ),
                                            ),
                                          ],
                                        ),
                                        space5,
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.mic,
                                              color: ColorName.greyText,
                                              size: 14,
                                            ),
                                            space5,
                                            Text(
                                              parseSpeakerType(
                                                  outpost.speak_type),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w400,
                                                color: ColorName.greyText,
                                              ),
                                            ),
                                          ],
                                        ),
                                        space5,
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.group,
                                              color: ColorName.greyText,
                                              size: 14,
                                            ),
                                            space5,
                                            Text(
                                              "${outpost.members_count ?? 0} Members",
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w400,
                                                color: ColorName.greyText,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (outpost.luma_event_id != null) ...[
                                          space5,
                                          Row(
                                            children: [
                                              //  local image
                                              Assets.images.lumaPng.image(
                                                width: 14,
                                                height: 14,
                                              ),
                                              space5,
                                              const Text(
                                                "Available on Luma",
                                                style: const TextStyle(
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
                                ),
                                if (outpost.tags.isNotEmpty)
                                  TagsWrapper(outpost: outpost),
                              ],
                            ),
                            Column(
                              children: [
                                if (canShareOutpostUrl(outpost: outpost))
                                  IconButton(
                                    onPressed: () {
                                      analytics.logEvent(
                                        name: "share_group",
                                        parameters: {
                                          "outpost_id": outpost.uuid,
                                          "outpost_name": outpost.name,
                                        },
                                      );
                                      Share.share(generateOutpostShareUrl(
                                          outpostId: outpost.uuid));
                                    },
                                    icon: const Icon(
                                      Icons.share,
                                      color: ColorName.greyText,
                                    ),
                                  ),
                                if (canLeaveOutpost(outpost: outpost))
                                  IconButton(
                                    onPressed: () {
                                      controller.leaveOutpost(outpost: outpost);
                                    },
                                    icon: const Icon(
                                      Icons.exit_to_app,
                                      color: Colors.red,
                                    ),
                                  ),
                                if (canArchiveOutpost(outpost: outpost))
                                  IconButton(
                                    onPressed: () {
                                      controller.toggleArchive(
                                          outpost: outpost);
                                    },
                                    icon: Icon(
                                      outpost.is_archived
                                          ? Icons.unarchive
                                          : Icons.archive,
                                      color: outpost.is_archived
                                          ? ColorName.greyText
                                          : Colors.red,
                                    ),
                                  )
                              ],
                            )
                          ],
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
                );
              },
            ),
            if (isScheduled)
              _ScheduledBanner(
                outpost: outpost,
                key: Key(outpost.uuid + 'scheduledBanner'),
              ),
            Positioned(
              child: _NumberOfActiveUsers(
                outpost: outpost,
                key: Key(outpost.uuid + 'numberOfActiveUsers'),
              ),
              left: -8,
              top: -6,
            )
          ],
        ),
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
    final numberOfActiveUsers = outpost.online_users_count ?? 0;

    return numberOfActiveUsers == 0
        ? const SizedBox()
        : Container(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Pulsator(
                  style: const PulseStyle(color: Colors.red),
                  duration: const Duration(seconds: 2),
                  count: 5,
                  repeat: 0,
                  startFromScratch: false,
                  autoStart: true,
                  fit: PulseFit.contain,
                  child: Obx(() {
                    final numberOfActiveUsers = controller
                        .mapOfOnlineUsersInOutposts.value[outpost.uuid];
                    return Text(
                      "${numberOfActiveUsers ?? 0}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
              ],
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
          final numberOfDays = remaining.split('d,').length;

          final remainingText = remaining.contains('d,')
              ? remaining
                  .split('d,')
                  .join('d\n')
                  .replaceAll('d', 'day${(numberOfDays - 1) > 1 ? 's' : ''}')
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
      width: Get.width - 100,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: outpost.tags
              .map((e) => SingleTag(
                    tagName: e,
                  ))
              .toList(),
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
