import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/providers/api/podium/models/notifications/notificationModel.dart';
import 'package:podium/root.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';

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
                      ));
                    }
                    return ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notif = notifications[index];
                        final imageSrc =
                            notif.follow_metadata?.follower_image ??
                                notif.invite_metadata?.inviter_image ??
                                '';
                        final alt = notif.follow_metadata?.follower_name ??
                            notif.invite_metadata?.inviter_name ??
                            '';
                        return Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: ColorName.cardBackground,
                                border: Border.all(
                                  color: ColorName.cardBorder,
                                ),
                                borderRadius: const BorderRadius.all(
                                  const Radius.circular(8),
                                ),
                              ),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Img(
                                          src: imageSrc,
                                          alt: alt,
                                          width: 24,
                                          height: 24,
                                        ),
                                        space10,
                                        Text(
                                          notif.notification_type.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      width: Get.width - 60,
                                      child: Text(
                                        notif.message,
                                        style: const TextStyle(
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    space10,
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (!notif.is_read)
                                          Button(
                                            size: ButtonSize.SMALL,
                                            onPressed: () {
                                              controller.markNotificationAsRead(
                                                  id: notif.uuid);
                                            },
                                            type: ButtonType.outline,
                                            text: 'Mark as read',
                                          ),
                                        // space10,
                                        // if (notif.notification_type ==
                                        //     NotificationTypes.follow)
                                        //   Button(
                                        //     size: ButtonSize.SMALL,
                                        //     onPressed: () {
                                        //       controller.deleteMyNotification(
                                        //         notif,
                                        //       );
                                        //     },
                                        //     type: ButtonType.outline,
                                        //     text: 'Delete',
                                        //   ),
                                        space10,
                                        if (notif.notification_type ==
                                            NotificationTypes.invite)
                                          Row(
                                            children: [
                                              Button(
                                                size: ButtonSize.SMALL,
                                                onPressed: () {
                                                  controller
                                                      .rejectOutpostInvitation(
                                                    notif: notif,
                                                  );
                                                },
                                                color: Colors.red[200]!,
                                                textColor: Colors.red[200]!,
                                                type: ButtonType.outline,
                                                text: 'Reject',
                                              ),
                                              space10,
                                              Button(
                                                size: ButtonSize.SMALL,
                                                onPressed: () {
                                                  controller
                                                      .acceptOutpostInvitation(
                                                    notif: notif,
                                                  );
                                                },
                                                color: Colors.green[200]!,
                                                textColor: Colors.green[200]!,
                                                type: ButtonType.outline,
                                                text: 'Accept',
                                              ),
                                            ],
                                          )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }),
                ),
              ),
              // Button(
              //   onPressed: () {
              //     controller.sendTestNotif();
              //   },
              //   text: 'add notification',
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
