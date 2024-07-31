import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'package:get/get.dart';
import 'package:podium/gen/colors.gen.dart';
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
                width: Get.width - 240,
                child: Obx(() {
                  final notifications = controller.notifications;
                  if (notifications.isEmpty) {
                    return Center(
                      child: Text('No notifications'),
                    );
                  }
                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        key: Key(notif.id),
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          key: Key(notif.id),
                          verticalOffset: 20.0,
                          child: FadeInAnimation(
                            child: GestureDetector(
                              onTap: () {
                                controller.markNotificationAsRead(
                                    notificationId: notif.id);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                    color: ColorName.cardBackground,
                                    border:
                                        Border.all(color: ColorName.cardBorder),
                                    borderRadius: const BorderRadius.all(
                                        const Radius.circular(8))),
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: Get.width - 200,
                                            child: Flexible(
                                              child: Text(
                                                notif.title,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            width: Get.width - 200,
                                            child: Flexible(
                                              child: Text(
                                                notif.body,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          if (!notif.isRead)
                                            Button(
                                              size: ButtonSize.SMALL,
                                              onPressed: () {
                                                controller
                                                    .markNotificationAsRead(
                                                        notificationId:
                                                            notif.id);
                                              },
                                              type: ButtonType.outline,
                                              text: 'Mark as read',
                                            ),
                                          space10,
                                          Button(
                                            size: ButtonSize.SMALL,
                                            onPressed: () {
                                              controller.deleteMyNotification(
                                                notif.id,
                                              );
                                            },
                                            type: ButtonType.outline,
                                            text: 'Delete',
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
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
