import '../controllers/outpost_detail_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/lib/jitsiMeet.dart';
import 'package:podium/app/modules/global/popUpsAndModals/outpostBanNotice.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/time.dart';
import 'package:podium/app/modules/global/widgets/img.dart';
import 'package:podium/app/modules/global/widgets/loading_widget.dart';
import 'package:podium/app/modules/global/widgets/outpost_bans_sheet.dart';
import 'package:podium/app/modules/hostAnalytics/views/host_outpost_analytics_view.dart';
import 'package:podium/app/modules/outpostDetail/views/outpost_detail_view.dart';
import 'package:podium/app/modules/outpostDetail/widgets/lumaDetailsDialog.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost_ban.dart';
import 'package:podium/services/server_features.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/ui/app_ui.dart';
import 'package:shimmer/shimmer.dart';

class _OutpostActionRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _OutpostActionRow({
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.cardTitle.copyWith(fontSize: 14),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption,
                  ),
                ],
              ],
            ),
          ),
          trailing ??
              Icon(
                Icons.chevron_right_rounded,
                color: ColorName.greyText,
              ),
        ],
      ),
    );
  }
}

class OutpostBottomActionBar extends StatelessWidget {
  final OutpostModel outpost;
  final bool showInvite;
  const OutpostBottomActionBar(
      {super.key, required this.outpost, required this.showInvite});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: ColorName.cardBackground.withAlpha(235),
        border: Border(top: BorderSide(color: ColorName.cardBorder)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          if (showInvite) ...[
            Expanded(
              flex: 2,
              child: AppSecondaryButton(
                label: 'Invite',
                icon: Icons.person_add_alt_1_rounded,
                onPressed: () {
                  openInviteBottomSheet(
                      canInviteToSpeak: canInviteToSpeak(
                    outpost: outpost,
                    currentUserId: myId,
                  ));
                },
              ),
            ),
            const SizedBox(width: 12),
          ],
          const Expanded(
            flex: 3,
            child: JoinTheOutpostButton(),
          ),
        ],
      ),
    );
  }
}

class ScheduledTimer extends GetView<OutpostDetailController> {
  const ScheduledTimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final scheduledTime = controller.outpost.value?.scheduled_for;
      final openRescheduleOutpostDialog =
          controller.openRescheduleOutpostDialog;
      final _ = controller.outpost.value?.creator_joined ?? false;
      if (scheduledTime == null) {
        return const SizedBox();
      }
      return GetBuilder<GlobalController>(
        id: GlobalUpdateIds.ticker,
        builder: (controller) {
          final hasTimePassed =
              scheduledTime < DateTime.now().millisecondsSinceEpoch;
          final time = remainintTimeUntilMilSecondsFormated(
            time: scheduledTime,
          ).replaceAll('d,', 'day, ');
          final color = hasTimePassed ? AppColors.accent : AppColors.primary;
          return AppCard(
            onTap: openRescheduleOutpostDialog,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            borderColor: color.withAlpha(80),
            child: Row(
              children: [
                AppIconTile(
                  size: 36,
                  circle: true,
                  icon: hasTimePassed
                      ? Icons.update_rounded
                      : Icons.schedule_rounded,
                  color: color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasTimePassed ? 'START TIME PASSED' : 'STARTS IN',
                        style: AppText.label,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hasTimePassed ? 'Reschedule?' : time,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ColorName.white,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.fill,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: ColorName.white,
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}

class LumaIconButton extends GetView<OutpostDetailController> {
  const LumaIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isGettingLumaEventDetails =
          controller.isGettingLumaEventDetails.value;
      final isGettingLumaEventGuests =
          controller.isGettingLumaEventGuests.value;
      final lumaEventDetails = controller.lumaEventDetails.value;
      final image = lumaEventDetails?.event.cover_url;
      final isLoading = isGettingLumaEventDetails || isGettingLumaEventGuests;
      return _OutpostActionRow(
        onTap: () {
          if (isLoading) return;
          openLumaDetailsDialog();
        },
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: image != null
              ? Img(
                  src: image,
                  size: 40,
                  alt: 'luma event',
                  borderRadius: BorderRadius.zero,
                )
              : Assets.images.lumaPng.image(
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
        ),
        title: 'Luma event',
        subtitle: isLoading
            ? 'Loading event details…'
            : 'Hosts, guests and event details',
        trailing: isLoading ? const LoadingWidget(size: 14) : null,
      );
    });
  }
}

class OutpostAnalyticsButton extends StatelessWidget {
  const OutpostAnalyticsButton({super.key, required this.outpost});

  final OutpostModel outpost;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!Get.find<ServerFeatures>().discovery.value) {
        return const SizedBox.shrink();
      }
      return _OutpostActionRow(
        onTap: () => openHostOutpostAnalytics(
          uuid: outpost.uuid,
          name: outpost.name,
        ),
        leading: AppIconTile(
          size: 36,
          circle: true,
          icon: Icons.insights_rounded,
          color: AppColors.violet,
        ),
        title: 'Outpost analytics',
        subtitle: 'Listeners, retention and earnings per session',
      );
    });
  }
}

class OutpostBansButton extends StatelessWidget {
  const OutpostBansButton({super.key, required this.outpost});

  final OutpostModel outpost;

  @override
  Widget build(BuildContext context) {
    return _OutpostActionRow(
      onTap: () => openOutpostBansSheet(
        outpostId: outpost.uuid,
        creatorUuid: outpost.creator_user_uuid,
      ),
      leading: AppIconTile(
        size: 36,
        circle: true,
        icon: Icons.block_rounded,
        color: AppColors.danger,
      ),
      title: 'Removed & blocked',
      subtitle: 'See who is kept out and let them back in',
    );
  }
}

/// Tells a visitor a host removed or blocked them from this outpost.
class MyOutpostBanBanner extends StatelessWidget {
  const MyOutpostBanBanner({super.key, required this.ban});

  final OutpostBanInfo ban;

  @override
  Widget build(BuildContext context) {
    final until = ban.expiresAt;
    final isKick = ban.banKind == OutpostBanKind.kick && until != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: AppCallout(
        icon: isKick ? Icons.logout_rounded : Icons.block_rounded,
        color: AppColors.danger,
        text: isKick
            ? 'A host removed you from this outpost. You can join again in '
                '${formatTimeUntil(until)}.'
            : "A host blocked you from this outpost. You can't join it "
                'unless a host lets you back in.',
      ),
    );
  }
}

class ChangeScheduleButton extends GetView<OutpostDetailController> {
  const ChangeScheduleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSecondaryButton(
      label: 'Change Schedule',
      icon: Icons.edit_calendar_rounded,
      color: ColorName.primaryBlue,
      onPressed: () async {
        controller.reselectScheduleTime();
      },
    );
  }
}

class SetReminderButton extends GetView<OutpostDetailController> {
  const SetReminderButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final outpost = controller.outpost.value;
      final remindMeBefore = outpost?.reminder_offset_minutes;
      final isSettingReminder = controller.isSettingReminder.value;
      if (outpost == null) {
        return const SizedBox();
      }
      int? reminderIsSetForInMinotes;
      if (remindMeBefore != null) {
        reminderIsSetForInMinotes = remindMeBefore;
      }

      String text = reminderIsSetForInMinotes != null
          ? "Reminder is set for ${reminderIsSetForInMinotes.abs()} min before event"
          : 'Set a reminder';
      if (reminderIsSetForInMinotes == 0) {
        text = 'Reminder is set for when event starts';
      }
      final isPassed =
          outpost.scheduled_for < DateTime.now().millisecondsSinceEpoch;
      if (isPassed) {
        return const SizedBox();
      }
      final isSet = reminderIsSetForInMinotes != null;

      return _OutpostActionRow(
        onTap: () {
          controller.setReminderForOutpost();
        },
        leading: AppIconTile(
          size: 36,
          circle: true,
          icon: isSet
              ? Icons.notifications_active_rounded
              : Icons.notifications_none_rounded,
          color: AppColors.accent,
        ),
        title: text,
        subtitle:
            isSet ? 'Tap to change' : 'Get notified before the outpost starts',
        trailing: isSettingReminder ? const LoadingWidget(size: 14) : null,
      );
    });
  }
}

class JoinTheOutpostButton extends GetView<OutpostDetailController> {
  const JoinTheOutpostButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final accesses = controller.outpostAccesses.value;
      final outpost = controller.outpost.value;
      final joinButtonContent = controller.jointButtonContentProps.value;
      final isJoining = controller.isJoining.value;
      final callController = Get.find<OutpostCallController>();
      final callOutpostId = callController.outpost.value?.uuid;
      final isRegistered = callController.isInCall.value &&
          outpost != null &&
          callOutpostId == outpost.uuid;
      final enabled = isRegistered || joinButtonContent.enabled;
      final text = isRegistered ? 'Return to Outpost' : joinButtonContent.text;
      if (accesses == null || outpost == null) {
        return const SizedBox();
      }

      final onPressed = enabled
          ? () {
              if (isRegistered && Get.isRegistered<OutpostDetailController>()) {
                openCallPage();
              } else {
                controller.startTheCall(accesses: accesses);
              }
            }
          : null;
      final useGradient = !isRegistered && (enabled || isJoining);
      final background = isRegistered
          ? AppColors.success.withAlpha(36)
          : useGradient
              ? Colors.transparent
              : AppColors.primary;
      final radius = BorderRadius.circular(AppRadius.lg);

      final button = FilledButton(
        onPressed: isJoining ? null : onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          backgroundColor: background,
          foregroundColor: isRegistered
              ? AppColors.success
              : useGradient
                  ? AppColors.onPrimary
                  : ColorName.white,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: isJoining
              ? (useGradient ? Colors.transparent : background.withAlpha(150))
              : AppColors.fill,
          disabledForegroundColor: ColorName.white.withAlpha(150),
          side: isRegistered
              ? BorderSide(color: AppColors.success.withAlpha(140))
              : null,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        child: isJoining
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: useGradient ? AppColors.onPrimary : ColorName.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isRegistered) ...[
                    Icon(
                      enabled
                          ? Icons.podcasts_rounded
                          : Icons.hourglass_top_rounded,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: isRegistered
                        ? Shimmer.fromColors(
                            baseColor: ColorName.white,
                            highlightColor: AppColors.success,
                            child: Text(
                              text,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        : Text(
                            text,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: text.contains('\n') ? 12 : 15,
                              height: 1.25,
                            ),
                          ),
                  ),
                  if (isRegistered) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ],
              ),
      );
      if (!useGradient) return button;
      return AppGradientShell(
        borderRadius: radius,
        child: AppSheen(borderRadius: radius, child: button),
      );
    });
  }
}
