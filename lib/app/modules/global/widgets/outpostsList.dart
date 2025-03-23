import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
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

class OutpostsList extends StatelessWidget {
  final List<OutpostModel> outpostsList;
  final ScrollController? scrollController;
  final PagingController<int, OutpostModel>? pagingController;
  const OutpostsList({
    super.key,
    required this.outpostsList,
    this.scrollController,
    this.pagingController,
  });
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OutpostsController>();
    return Scrollbar(
        controller: scrollController,
        child: pagingController == null
            ? ListView.builder(
                controller: scrollController,
                itemCount: outpostsList.length,
                itemBuilder: (context, index) {
                  final outpost = outpostsList[index];
                  final amICreator = outpost.creator_user_uuid == myId;
                  return _SingleOutpost(
                    key: Key(outpost.uuid),
                    controller: controller,
                    amICreator: amICreator,
                    outpost: outpost,
                  );
                },
              )
            : PagedListView<int, OutpostModel>(
                pagingController: pagingController!,
                scrollController: scrollController,
                builderDelegate: PagedChildBuilderDelegate<OutpostModel>(
                    itemBuilder: (context, outpost, index) {
                  final amICreator = outpost.creator_user_uuid == myId;
                  return _SingleOutpost(
                    key: Key(outpost.uuid),
                    controller: controller,
                    amICreator: amICreator,
                    outpost: outpost,
                  );
                }),
              ));
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
    return GestureDetector(
      onTap: () async {
        controller.joinOutpostAndOpenOutpostDetailPage(
          outpostId: outpost.uuid,
        );
      },
      child: Stack(
        children: [
          space16,
          Container(
            decoration: const BoxDecoration(
                color: ColorName.cardBackground,
                borderRadius: BorderRadius.all(Radius.circular(8))),
            margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
            padding: const EdgeInsets.all(10),
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
                                          overflow: TextOverflow.ellipsis,
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
                                      parseAccessType(outpost.enter_type),
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
                                      parseSpeakerType(outpost.speak_type),
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
                              controller.toggleArchive(outpost: outpost);
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
                _JoiningIndicator(
                  outpostId: outpost.uuid,
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
          if (isScheduled)
            _ScheduledBanner(
              outpost: outpost,
              key: Key(outpost.uuid + 'scheduledBanner'),
            ),
          _NumberOfActiveUsers(
            outpost: outpost,
            key: Key(outpost.uuid + 'numberOfActiveUsers'),
          ),
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
                  child: Text(
                    "${numberOfActiveUsers}",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
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
          final remainingText = remaining.contains('d,')
              ? remaining.split('d,').join('d\n').replaceAll('d', 'days')
              : remaining;
          return Positioned(
            right: 10,
            top: 0,
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
        color: ColorName.greyText.withAlpha(51),
        borderRadius: BorderRadius.circular(4),
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

class _JoiningIndicator extends GetView<OutpostsController> {
  final String outpostId;
  const _JoiningIndicator({super.key, required this.outpostId});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final joiningGroupId = controller.joiningGroupId.value;
      if (joiningGroupId != outpostId) {
        return const SizedBox();
      }
      return Positioned(
        right: Get.width / 2 - 20,
        bottom: 40,
        child: const CircularProgressIndicator(),
      );
    });
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
