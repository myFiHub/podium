import 'package:flutter/material.dart';
import 'package:podium/utils/palette.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/providers/api/podium/models/notifications/notificationModel.dart';
import 'package:podium/root.dart';
import 'package:podium/utils/truncate.dart';
import 'package:podium/widgets/ui/app_ui.dart';

import '../controllers/notifications_controller.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageWrapper(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(() {
              final unread = controller.numberOfUnreadNotifications.value;
              return AppPageHeader(
                title: 'Alerts',
                subtitle:
                    unread == 0 ? "You're all caught up" : '$unread unread',
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              );
            }),
            Expanded(
              child: Obx(() {
                final notifications = controller.notifications;
                if (notifications.isEmpty) {
                  return const EmptyNotificationsWidget();
                }
                return ListView.builder(
                  key: const PageStorageKey('notifications_list'),
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    return AppEntrance(
                      key: ValueKey(notif.uuid),
                      id: 'notification_${notif.uuid}',
                      index: index,
                      child: NotificationCard(
                        notification: notif,
                        controller: controller,
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyNotificationsWidget extends StatelessWidget {
  const EmptyNotificationsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SingleChildScrollView(
        child: AppEmptyState(
          icon: Icons.notifications_none_rounded,
          title: 'No notifications',
          message: 'Invitations and new followers will show up here.',
        ),
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
    final isRead = notification.is_read;

    return AppCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      borderColor: isRead ? null : AppColors.primary.withAlpha(90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotificationAvatar(
                key: ValueKey('img_${imageSrc}'),
                imageSrc: imageSrc,
                alt: alt,
                isInvite: isInvite,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NotificationHeader(
                      key: ValueKey('${imageSrc}_${alt}'),
                      imageSrc: imageSrc,
                      alt: alt,
                      title: title,
                      isInvite: isInvite,
                      isRead: isRead,
                    ),
                    const SizedBox(height: 4),
                    NotificationMessage(
                      key: ValueKey('message_${notification.uuid}'),
                      message: notification.message,
                    ),
                    const SizedBox(height: 10),
                    NotificationIdSection(
                      key: ValueKey('${notifierId}_${notification.uuid}'),
                      idPrefix: idPrefix,
                      notifierId: notifierId,
                      isInvite: isInvite,
                      notificationId: notification.uuid,
                      controller: controller,
                    ),
                  ],
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !isRead || isInvite
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: NotificationActions(
                      key: ValueKey('actions_${notification.uuid}'),
                      notification: notification,
                      controller: controller,
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _NotificationAvatar extends StatelessWidget {
  final String imageSrc;
  final String alt;
  final bool isInvite;

  const _NotificationAvatar({
    super.key,
    required this.imageSrc,
    required this.alt,
    required this.isInvite,
  });

  @override
  Widget build(BuildContext context) {
    final color = isInvite ? AppColors.accent : AppColors.success;
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Img(
            src: imageSrc,
            alt: alt,
            size: 44,
            borderRadius: const BorderRadius.all(Radius.circular(22)),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              child: Icon(
                isInvite ? Icons.mail_rounded : Icons.person_add_alt_1_rounded,
                size: 10,
                color: AppColors.onColor(color),
              ),
            ),
          ),
        ],
      ),
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
        Flexible(
          child: NotifTitleWidget(
            key: ValueKey('title_${title}'),
            title: title,
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutBack,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: isRead
              ? const SizedBox.shrink(key: ValueKey('read'))
              : Padding(
                  key: const ValueKey('new'),
                  padding: const EdgeInsets.only(left: 8),
                  child: AppPill(label: 'NEW', color: AppColors.primary),
                ),
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
    return Text(
      message,
      style: AppText.muted.copyWith(height: 1.35),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
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
    return Material(
      color: AppColors.primary.withAlpha(22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: AppColors.primary.withAlpha(60)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          controller.openUserProfile(
            id: notifierId,
            notifId: notificationId,
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 5, 8, 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text.rich(
                  key: ValueKey('richText_${notifierId}'),
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$idPrefix ',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: truncate(
                          notifierId,
                          length: 15,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Obx(() {
                final loadingUserId = controller.loadingUserId.value;
                return loadingUserId == notifierId + notificationId
                    ? SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.6,
                          color: AppColors.primary,
                        ),
                      )
                    : Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: AppColors.primary,
                      );
              }),
            ],
          ),
        ),
      ),
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
    final isInvite = notification.notification_type == NotificationTypes.invite;
    return Obx(() {
      final loadingInviteId = controller.loadingInviteId.value;
      return Row(
        children: [
          if (!notification.is_read)
            _NotifActionButton(
              key: ValueKey('read_${notification.uuid}'),
              label: 'Mark as read',
              loading: loadingInviteId == notification.uuid + 'read',
              style: _NotifActionStyle.text,
              onPressed: () {
                controller.markNotificationAsRead(id: notification.uuid);
              },
            ),
          const Spacer(),
          if (isInvite) ...[
            _NotifActionButton(
              key: ValueKey('reject_${notification.uuid}'),
              label: 'Reject',
              loading: loadingInviteId == notification.uuid + 'reject',
              style: _NotifActionStyle.danger,
              onPressed: () {
                controller.rejectOutpostInvitation(
                  notif: notification,
                );
              },
            ),
            const SizedBox(width: 8),
            _NotifActionButton(
              key: ValueKey('accept_${notification.uuid}'),
              label: 'Accept',
              loading: loadingInviteId == notification.uuid + 'accept',
              style: _NotifActionStyle.primary,
              onPressed: () {
                controller.acceptOutpostInvitation(
                  notif: notification,
                );
              },
            ),
          ],
        ],
      );
    });
  }
}

enum _NotifActionStyle { text, danger, primary }

class _NotifActionButton extends StatelessWidget {
  final String label;
  final bool loading;
  final _NotifActionStyle style;
  final VoidCallback onPressed;

  const _NotifActionButton({
    super.key,
    required this.label,
    required this.loading,
    required this.style,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
    );
    const padding = EdgeInsets.symmetric(horizontal: 16);
    const minimumSize = Size(0, 36);
    const textStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w700);
    final fg = switch (style) {
      _NotifActionStyle.text => AppColors.textMuted,
      _NotifActionStyle.danger => AppColors.danger,
      _NotifActionStyle.primary => ColorName.white,
    };
    final child = loading
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : Text(label);
    final onTap = loading ? null : onPressed;

    switch (style) {
      case _NotifActionStyle.text:
        return TextButton.icon(
          onPressed: onTap,
          icon: loading ? child : const Icon(Icons.done_all_rounded, size: 16),
          label: Text(label),
          style: TextButton.styleFrom(
            foregroundColor: fg,
            disabledForegroundColor: fg,
            minimumSize: minimumSize,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            textStyle: textStyle,
            shape: shape,
          ),
        );
      case _NotifActionStyle.danger:
        return OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: fg,
            disabledForegroundColor: fg,
            backgroundColor: fg.withAlpha(18),
            side: BorderSide(color: fg.withAlpha(90)),
            minimumSize: minimumSize,
            padding: padding,
            textStyle: textStyle,
            shape: shape,
          ),
          child: child,
        );
      case _NotifActionStyle.primary:
        return FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: AppColors.onColor(AppColors.success),
            disabledBackgroundColor: AppColors.success.withAlpha(150),
            disabledForegroundColor: AppColors.onColor(AppColors.success),
            minimumSize: minimumSize,
            padding: padding,
            textStyle: textStyle,
            shape: shape,
          ),
          child: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : Text(label),
        );
    }
  }
}

class NotifTitleWidget extends StatelessWidget {
  final String title;

  const NotifTitleWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppText.cardTitle,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}
