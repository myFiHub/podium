import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/notification_model.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';
import '../controllers/notifications_controller.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
                      )
                    );
                  }
                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
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
                                  Container(
                                    width: Get.width - 200,
                                    child: Text(
                                      notif.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: Get.width - 200,
                                    child: Text(
                                      notif.body,
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  space10,
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (!notif.isRead)
                                        Button(
                                          size: ButtonSize.SMALL,
                                          onPressed: () {
                                            markNotificationAsRead(
                                              notificationId: notif.id,
                                            );
                                          },
                                          type: ButtonType.outline,
                                          text: 'Mark as read',
                                        ),
                                      space10,
                                      if (notif.type ==
                                          NotificationTypes.follow.toString())
                                        Button(
                                          size: ButtonSize.SMALL,
                                          onPressed: () {
                                            controller.deleteMyNotification(
                                              notif,
                                            );
                                          },
                                          type: ButtonType.outline,
                                          text: 'Delete',
                                        ),
                                      space10,
                                      if (notif.type ==
                                          NotificationTypes.inviteToJoinGroup
                                              .toString())
                                        Row(
                                          children: [
                                            Button(
                                              size: ButtonSize.SMALL,
                                              onPressed: () {
                                                controller
                                                    .rejectGroupInvitation(
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
                                                    .acceptGroupInvitation(
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
    );
  }
}
