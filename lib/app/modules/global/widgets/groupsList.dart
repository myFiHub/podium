import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/createGroup/controllers/create_group_controller.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/time.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/env.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/utils/analytics.dart';
import 'package:podium/utils/constants.dart';
import 'package:rotated_corner_decoration/rotated_corner_decoration.dart';
import 'package:share_plus/share_plus.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/utils/styles.dart';

class GroupList extends StatelessWidget {
  final List<FirebaseGroup> groupsList;
  const GroupList({super.key, required this.groupsList});
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GroupsController>();
    return Scrollbar(
      child: ListView.builder(
        itemCount: groupsList.length,
        itemBuilder: (context, index) {
          final group = groupsList[index];
          final name = group.name;
          final amICreator = group.creator.id == myId;
          String creatorAvatar = group.creator.avatar;

          if (creatorAvatar == defaultAvatar) {
            creatorAvatar = avatarPlaceHolder(group.creator.fullName);
          }
          return _SingleGroup(
            key: Key(group.id),
            controller: controller,
            amICreator: amICreator,
            name: name,
            creatorAvatar: creatorAvatar,
            group: group,
          );
        },
      ),
    );
  }
}

class _SingleGroup extends StatelessWidget {
  const _SingleGroup({
    super.key,
    required this.controller,
    required this.amICreator,
    required this.name,
    required this.creatorAvatar,
    required this.group,
  });

  final GroupsController controller;
  final bool amICreator;
  final String name;
  final String creatorAvatar;
  final FirebaseGroup group;

  @override
  Widget build(BuildContext context) {
    final isScheduled = group.scheduledFor != 0;

    return GestureDetector(
      onTap: () {
        controller.joinGroupAndOpenGroupDetailPage(
          groupId: group.id,
        );
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
                color: ColorName.cardBackground,
                border: Border.all(color: ColorName.cardBorder),
                borderRadius: const BorderRadius.all(const Radius.circular(8))),
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            padding: const EdgeInsets.all(8),
            // key: Key(group.id),
            child: Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: Get.width - 75,
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        space10,
                        Row(
                          children: [
                            Img(
                              src: Uri.parse(group.imageUrl ?? "").isAbsolute
                                  ? group.imageUrl!
                                  : Constants.logoUrl,
                              alt: group.name,
                            ),
                            space10,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: Get.width - 170,
                                  child: RichText(
                                      overflow: TextOverflow.ellipsis,
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: "Created by:",
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: ColorName.greyText,
                                            ),
                                          ),
                                          TextSpan(
                                            text:
                                                "  ${amICreator ? "You" : group.creator.fullName}",
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: amICreator
                                                  ? Colors.green[200]
                                                  : Colors.blue[200],
                                            ),
                                          ),
                                        ],
                                      )),
                                ),
                                space5,
                                Row(
                                  children: [
                                    Icon(
                                      Icons.subject,
                                      color: ColorName.greyText,
                                      size: 14,
                                    ),
                                    Container(
                                      width: Get.width - 170,
                                      child: Text(
                                        " ${group.subject == null ? "No Subject" : group.subject!.isEmpty ? "No Subject" : group.subject}",
                                        style: TextStyle(
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
                                    Icon(
                                      Icons.lock,
                                      color: ColorName.greyText,
                                      size: 14,
                                    ),
                                    space5,
                                    Text(
                                      parseAccessType(group.accessType),
                                      style: TextStyle(
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
                                    Icon(
                                      Icons.mic,
                                      color: ColorName.greyText,
                                      size: 14,
                                    ),
                                    space5,
                                    Text(
                                      parseSpeakerType(group.speakerType),
                                      style: TextStyle(
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
                                    Icon(
                                      Icons.group,
                                      color: ColorName.greyText,
                                      size: 14,
                                    ),
                                    space5,
                                    Text(
                                      "${group.members.length} Members",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w400,
                                        color: ColorName.greyText,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          ],
                        ),
                        if (group.tags.isNotEmpty) TagsWrapper(group: group),
                      ],
                    ),
                    Column(
                      children: [
                        if (canShareGroupUrl(group: group))
                          IconButton(
                            onPressed: () {
                              analytics.logEvent(
                                name: "share_group",
                                parameters: {
                                  "group_id": group.id,
                                  "group_name": group.name,
                                },
                              );
                              Share.share(
                                  generateGroupShareUrl(groupId: group.id));
                            },
                            icon: Icon(
                              Icons.share,
                              color: ColorName.greyText,
                            ),
                          ),
                        if (canArchiveGroup(group: group))
                          IconButton(
                            onPressed: () {
                              controller.toggleArchive(group: group);
                            },
                            icon: Icon(
                              group.archived ? Icons.unarchive : Icons.archive,
                              color: group.archived
                                  ? ColorName.greyText
                                  : Colors.red,
                            ),
                          )
                      ],
                    )
                  ],
                ),
                JoiningIndicator(
                  groupId: group.id,
                ),
                if (group.hasAdultContent)
                  Positioned(
                    child: Assets.images.ageRestricted.image(
                      width: 30,
                      height: 30,
                    ),
                    left: 0,
                    bottom: 0,
                  ),
              ],
            ),
          ),
          if (isScheduled)
            _ScheduledBanner(
              group: group,
              key: Key(group.id + 'scheduledBanner'),
            ),
          _NumberOfActiveUsers(
            groupId: group.id,
            key: Key(group.id + 'numberOfActiveUsers'),
          ),
        ],
      ),
    );
  }
}

class _NumberOfActiveUsers extends GetView<GroupsController> {
  final String groupId;
  const _NumberOfActiveUsers({
    super.key,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final allActiveUsers = controller.presentUsersInGroupsMap.value;
      final activeUsers = allActiveUsers[groupId] ?? [];
      final numberOfActiveUsers = activeUsers.length;
      return numberOfActiveUsers == 0
          ? SizedBox()
          : Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ColorName.secondaryBlue.withOpacity(1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "${numberOfActiveUsers} Active",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            );
    });
  }
}

generateGroupShareUrl({required String groupId}) {
  return "${Env.baseDeepLinkUrl}/?link=${Env.baseDeepLinkUrl}${Routes.GROUP_DETAIL}?id=${groupId}&apn=com.web3podium";
}

class _ScheduledBanner extends StatelessWidget {
  final FirebaseGroup group;
  const _ScheduledBanner({
    super.key,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    final passedAtLeast2h =
        group.scheduledFor < DateTime.now().millisecondsSinceEpoch - 7200000;
    if (passedAtLeast2h) {
      return const SizedBox();
    }
    return GetBuilder<GlobalController>(
        id: GlobalUpdateIds.ticker,
        builder: (globalController) {
          final remaining = remainintTimeUntilMilSecondsFormated(
            time: group.scheduledFor,
            textIfAlreadyPassed: "Started",
          );
          final isStarted =
              group.scheduledFor < DateTime.now().millisecondsSinceEpoch;
          final size = 60;
          final remainingText = remaining.contains('d,')
              ? remaining.split('d,').join('d\n').replaceAll('d', 'days')
              : remaining;
          return Positioned(
            right: 5,
            top: 8,
            child: IgnorePointer(
              child: Container(
                foregroundDecoration: RotatedCornerDecoration.withColor(
                  color: isStarted ? Colors.green : Colors.red,
                  spanBaselineShift: remainingText.contains('days') ? 2 : 4,
                  badgeSize: Size(size.toDouble(), size.toDouble()),
                  badgeCornerRadius: Radius.circular(4),
                  badgePosition: BadgePosition.topEnd,
                  textSpan: TextSpan(
                    text: remainingText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      letterSpacing: 1,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        BoxShadow(color: Colors.yellowAccent, blurRadius: 8),
                      ],
                    ),
                  ),
                ),
                height: size.toDouble(),
                width: size.toDouble(),
              ),
            ),
          );
        });
  }
}

class TagsWrapper extends StatelessWidget {
  const TagsWrapper({
    super.key,
    required this.group,
  });

  final FirebaseGroup group;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 8),
      width: Get.width - 74,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: group.tags
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
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      margin: EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: ColorName.greyText.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tagName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: ColorName.greyText,
        ),
      ),
    );
  }
}

class JoiningIndicator extends GetView<GroupsController> {
  final groupId;
  const JoiningIndicator({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final joiningGroupId = controller.joiningGroupId.value;
      if (joiningGroupId != groupId) {
        return const SizedBox();
      }
      return Positioned(
        right: Get.width / 2 - 20,
        bottom: 40,
        child: CircularProgressIndicator(),
      );
    });
  }
}

String parseSpeakerType(String? speakerType) {
  switch (speakerType) {
    case null:
      return "Everyone";
    case FreeRoomSpeakerTypes.everyone:
      return "Everyone";
    case FreeRoomSpeakerTypes.invitees:
      return "Only Invited Users";
    case BuyableTicketTypes.onlyArenaTicketHolders:
      return "Only Arena Ticket Holders";
    case BuyableTicketTypes.onlyFriendTechTicketHolders:
      return "Only Friendtech Ticket Holders";
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
    case FreeRoomAccessTypes.public:
      return "Public";
    case FreeRoomAccessTypes.onlyLink:
      return "Only By Link";
    case FreeRoomAccessTypes.invitees:
      return "Only Invited Users";
    case BuyableTicketTypes.onlyArenaTicketHolders:
      return "Only Arena Ticket Holders";
    case BuyableTicketTypes.onlyFriendTechTicketHolders:
      return "Only Friendtech Ticket Holders";
    case BuyableTicketTypes.onlyPodiumPassHolders:
      return "Only Podium Pass Holders";
    default:
      return "Public";
  }
}

canShareGroupUrl({required FirebaseGroup group}) {
  final GlobalController globalController = Get.find();
  if (globalController.currentUserInfo.value == null) {
    return false;
  }
  final iAmCreator = group.creator.id == myId;
  if (iAmCreator) {
    return true;
  }
  if (group.accessType == FreeRoomAccessTypes.public) {
    return true;
  }
  if (group.accessType == FreeRoomAccessTypes.onlyLink) {
    if (group.members.contains(myId)) {
      return true;
    }
  }
  return false;
}

canArchiveGroup({required FirebaseGroup group}) {
  final GlobalController globalController = Get.find();
  if (globalController.currentUserInfo.value == null) {
    return false;
  }
  final iAmCreator = group.creator.id == myId;
  return iAmCreator;
}
