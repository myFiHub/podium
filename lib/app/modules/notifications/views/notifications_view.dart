import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/modules/global/widgets/loading_widget.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/providers/api/podium/models/notifications/notificationModel.dart';
import 'package:podium/root.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/utils/truncate.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:shimmer/shimmer.dart';

import '../controllers/notifications_controller.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageWrapper(
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  child: Obx(() {
                    final notifications = controller.notifications;
                    if (notifications.isEmpty) {
                      return const EmptyNotificationsWidget();
                    }
                    return ListView.builder(
                      key: const PageStorageKey('notifications_list'),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notif = notifications[index];
                        return NotificationCard(
                          key: ValueKey(notif.uuid),
                          notification: notif,
                          controller: controller,
                        );
                      },
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyNotificationsWidget extends StatelessWidget {
  const EmptyNotificationsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Assets.images.bell.image(
            width: 64,
            height: 64,
          ),
          const SizedBox(height: 10),
          const Text('No notifications'),
        ],
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final NotificationsController controller;

  const NotificationCard({
    Key? key,
    required this.notification,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isInvite = notification.notification_type == NotificationTypes.invite;
    final imageSrc = isInvite
        ? notification.invite_metadata?.inviter_image ?? ''
        : notification.follow_metadata?.follower_image ?? '';
    final alt = isInvite
        ? notification.invite_metadata?.inviter_name ?? ''
        : notification.follow_metadata?.follower_name ?? '';
    final idPrefix = isInvite ? 'Inviter ID: ' : 'Follower ID: ';
    final notifierId = isInvite
        ? notification.invite_metadata?.inviter_uuid ?? ''
        : notification.follow_metadata?.follower_uuid ?? '';
    final title =
        notification.notification_type.name == NotificationTypes.invite.name
            ? 'Outpost Invitation'
            : 'New Follower';

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: ColorName.cardBackground,
            border: Border.all(
              color: ColorName.cardBorder,
            ),
            borderRadius: const BorderRadius.all(
              Radius.circular(8),
            ),
          ),
          margin: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NotificationHeader(
                  key: ValueKey('${imageSrc}_${alt}'),
                  imageSrc: imageSrc,
                  alt: alt,
                  title: title,
                  isInvite: isInvite,
                  isRead: notification.is_read,
                ),
                space5,
                NotificationMessage(
                  key: ValueKey('message_${notification.uuid}'),
                  message: notification.message,
                ),
                space5,
                NotificationIdSection(
                  key: ValueKey('${notifierId}_${notification.uuid}'),
                  idPrefix: idPrefix,
                  notifierId: notifierId,
                  isInvite: isInvite,
                  notificationId: notification.uuid,
                  controller: controller,
                ),
                space5,
                NotificationActions(
                  key: ValueKey('actions_${notification.uuid}'),
                  notification: notification,
                  controller: controller,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class NotificationHeader extends StatelessWidget {
  final String imageSrc;
  final String alt;
  final String title;
  final bool isInvite;
  final bool isRead;

  const NotificationHeader({
    Key? key,
    required this.imageSrc,
    required this.alt,
    required this.title,
    required this.isInvite,
    required this.isRead,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Img(
          key: ValueKey('img_${imageSrc}'),
          src: imageSrc,
          alt: alt,
          width: 24,
          height: 24,
        ),
        space10,
        if (isInvite && !isRead)
          Shimmer.fromColors(
            key: ValueKey('shimmer_${title}'),
            loop: 5,
            baseColor: Colors.white,
            highlightColor: Colors.blueAccent,
            child: NotifTitleWidget(
              key: ValueKey('title_${title}'),
              title: title,
            ),
          )
        else
          NotifTitleWidget(
            key: ValueKey('title_${title}'),
            title: title,
          ),
      ],
    );
  }
}

class NotificationMessage extends StatelessWidget {
  final String message;

  const NotificationMessage({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Get.width - 60,
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 14,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class NotificationIdSection extends StatelessWidget {
  final String idPrefix;
  final String notifierId;
  final bool isInvite;
  final String notificationId;
  final NotificationsController controller;

  const NotificationIdSection({
    Key? key,
    required this.idPrefix,
    required this.notifierId,
    required this.isInvite,
    required this.notificationId,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        controller.openUserProfile(
          id: notifierId,
          notifId: notificationId,
        );
      },
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(
            vertical: 6,
            horizontal: 10,
          ),
          decoration: BoxDecoration(
            color: ColorName.primaryBlue.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: ColorName.primaryBlue.withAlpha(77),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                key: ValueKey('richText_${notifierId}'),
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                  children: [
                    TextSpan(
                      text: '$idPrefix ',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isInvite
                            ? ColorName.primaryBlue
                            : ColorName.primaryBlue,
                      ),
                    ),
                    TextSpan(
                      text: truncate(
                        notifierId,
                        length: 15,
                      ),
                      style: TextStyle(
                        color: isInvite
                            ? ColorName.primaryBlue
                            : ColorName.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              space5,
              const Icon(
                Icons.arrow_forward_ios,
                size: 10,
                color: ColorName.primaryBlue,
              ),
            ],
          ),
        ),
        Obx(() {
          final loadingUserId = controller.loadingUserId.value;
          return loadingUserId == notifierId + notificationId
              ? const Padding(
                  padding: EdgeInsets.only(
                    left: 6,
                  ),
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: LoadingWidget(
                      color: Colors.blue,
                    ),
                  ))
              : emptySpace;
        })
      ]),
    );
  }
}

class NotificationActions extends StatelessWidget {
  final NotificationModel notification;
  final NotificationsController controller;

  const NotificationActions({
    Key? key,
    required this.notification,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (!notification.is_read)
          Obx(
            () {
              final loadingInviteId = controller.loadingInviteId.value;
              return Button(
                key: ValueKey('read_${notification.uuid}'),
                loading: loadingInviteId == notification.uuid + 'read',
                size: ButtonSize.SMALL,
                onPressed: () {
                  controller.markNotificationAsRead(id: notification.uuid);
                },
                type: ButtonType.outline,
                text: 'Mark as read',
              );
            },
          ),
        space10,
        if (notification.notification_type == NotificationTypes.invite)
          Row(
            children: [
              Obx(
                () {
                  final loadingInviteId = controller.loadingInviteId.value;
                  return Button(
                    key: ValueKey('reject_${notification.uuid}'),
                    loading: loadingInviteId == notification.uuid + 'reject',
                    size: ButtonSize.SMALL,
                    onPressed: () {
                      controller.rejectOutpostInvitation(
                        notif: notification,
                      );
                    },
                    color: Colors.red[200]!,
                    textColor: Colors.red[200]!,
                    type: ButtonType.outline,
                    text: 'Reject',
                  );
                },
              ),
              space10,
              Obx(
                () {
                  final loadingInviteId = controller.loadingInviteId.value;
                  return Button(
                    key: ValueKey('accept_${notification.uuid}'),
                    loading: loadingInviteId == notification.uuid + 'accept',
                    size: ButtonSize.SMALL,
                    onPressed: () {
                      controller.acceptOutpostInvitation(
                        notif: notification,
                      );
                    },
                    color: Colors.green[200]!,
                    textColor: Colors.green[200]!,
                    type: ButtonType.outline,
                    text: 'Accept',
                  );
                },
              ),
            ],
          )
      ],
    );
  }
}

class NotifTitleWidget extends StatelessWidget {
  final String title;

  const NotifTitleWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}
