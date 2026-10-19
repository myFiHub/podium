import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/createOutpost/controllers/create_outpost_controller.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/popUpsAndModals/outpostImage.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/time.dart';
import 'package:podium/app/modules/global/widgets/cohosts_widget.dart';
import 'package:podium/app/modules/global/widgets/img.dart';
import 'package:podium/app/modules/global/widgets/loading_widget.dart';
import 'package:podium/app/modules/global/widgets/outpostsList.dart';
import 'package:podium/app/modules/outpostDetail/widgets/lumaDetailsDialog.dart';
import 'package:podium/app/modules/outpostDetail/widgets/usersList.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/providers/api/podium/models/outposts/liveData.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/root.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/widgets/ui/app_ui.dart';
import 'package:shimmer/shimmer.dart';

import '../controllers/outpost_detail_controller.dart';

class OutpostImage extends GetView<OutpostDetailController> {
  final double height;
  const OutpostImage({super.key, this.height = 190});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final outpost = controller.outpost.value;
      if (outpost == null) return SizedBox(height: height);

      final imageUrl =
          outpost.image.isEmpty ? Constants.logoUrl : outpost.image;

      return GestureDetector(
        onTap: () {
          openOutpostImageDialog(
            outpost: outpost,
          );
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Img(
                  src: imageUrl,
                  width: constraints.maxWidth,
                  height: height,
                  alt: outpost.name,
                  borderRadius: BorderRadius.zero,
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.45, 1],
                          colors: [
                            Colors.transparent,
                            ColorName.cardBackground.withAlpha(230),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(110),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.open_in_full_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    });
  }
}

class ShareIconButton extends StatelessWidget {
  final OutpostModel outpost;
  const ShareIconButton({super.key, required this.outpost});

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: Icons.ios_share_rounded,
      tooltip: 'Copy link',
      onTap: () {
        final url = generateOutpostShareUrl(outpostId: outpost.uuid);
        // copy to clipboard and toast
        Clipboard.setData(ClipboardData(text: url));
        Toast.info(title: 'Copied!', message: 'URL copied to clipboard');
      },
    );
  }
}

class OutpostDetailView extends GetView<OutpostDetailController> {
  const OutpostDetailView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageWrapper(
        child: Obx(() {
          final exists = Get.isRegistered<OutpostDetailController>();
          if (!exists) return const SizedBox();
          final outpost = controller.outpost.value;
          final accesses = controller.outpostAccesses.value;
          if (outpost == null || accesses == null) {
            return const Center(child: LoadingWidget());
          }
          final iAmOwner = outpost.creator_user_uuid == myId;
          final isScheduled = outpost.scheduled_for > 0;
          final showInvite = canInvite(
            outpost: outpost,
            currentUserId: myId,
          );
          return Column(
            children: [
              _TopBar(outpost: outpost),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _HeroCard(outpost: outpost, iAmOwner: iAmOwner),
                    ),
                    if (isScheduled && iAmOwner)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: ScheduledTimer(),
                        ),
                      ),
                    const SliverToBoxAdapter(
                      child: AppSectionHeader(title: 'About this outpost'),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _AccessInfo(
                          outpost: outpost,
                          iAmOwner: iAmOwner,
                        ),
                      ),
                    ),
                    if ((outpost.cohost_user_uuids?.isNotEmpty ?? false) ||
                        iAmOwner)
                      SliverToBoxAdapter(
                        child: Obx(() => CohostsWidget(
                              cohostUserUuids: outpost.cohost_user_uuids ?? [],
                              isCreator: outpost.creator_user_uuid == myId,
                              isLoading: controller.isLoadingCohosts.value,
                              onTap: () {
                                _showCohostsBottomSheet();
                              },
                            )),
                      ),
                    if (outpost.luma_event_id != null)
                      const SliverToBoxAdapter(child: _LumaIconButton()),
                    if (outpost.scheduled_for != 0)
                      const SliverToBoxAdapter(child: SetReminderButton()),
                    const MembersList(),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
              _BottomActionBar(
                outpost: outpost,
                showInvite: showInvite,
              ),
            ],
          );
        }),
      ),
    );
  }

  void _showCohostsBottomSheet() {
    final controller = Get.find<OutpostDetailController>();
    final outpost = controller.outpost.value;
    if (outpost == null) return;

    Get.bottomSheet(
      CohostsSearchBottomSheet(
        initialCohostUuids: outpost.cohost_user_uuids ?? [],
        outpostUuid: outpost.uuid,
        isCreator: outpost.creator_user_uuid == myId,
        onConfirm: (cohostUuids) {
          controller.updateCohosts(cohostUuids);
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _TopBar extends StatelessWidget {
  final OutpostModel outpost;
  const _TopBar({required this.outpost});

  @override
  Widget build(BuildContext context) {
    final canShare = canShareOutpostUrl(outpost: outpost) == true;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          AppIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back',
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const Expanded(
            child: Text(
              'OUTPOST',
              textAlign: TextAlign.center,
              style: AppText.label,
            ),
          ),
          if (canShare)
            ShareIconButton(outpost: outpost)
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final OutpostModel outpost;
  final bool iAmOwner;
  const _HeroCard({required this.outpost, required this.iAmOwner});

  @override
  Widget build(BuildContext context) {
    final isUpcoming =
        outpost.scheduled_for > DateTime.now().millisecondsSinceEpoch;
    final pills = <Widget>[
      if (outpost.creator_joined)
        const AppPill(
          label: 'Host is live',
          color: AppColors.success,
          icon: Icons.circle,
        ),
      if (isUpcoming)
        const AppPill(
          label: 'Scheduled',
          color: AppColors.accent,
          icon: Icons.event_rounded,
        ),
      if (outpost.is_recordable)
        const AppPill(
          label: 'Recordable',
          color: AppColors.danger,
          icon: Icons.fiber_manual_record_rounded,
        ),
      if (outpost.has_adult_content)
        const AppPill(
          label: '18+',
          color: AppColors.danger,
          icon: Icons.explicit_rounded,
        ),
    ];
    final creatorName = outpost.creator_user_name ?? '';
    return AppCard(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OutpostImage(),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pills.isNotEmpty) ...[
                  Wrap(spacing: 6, runSpacing: 6, children: pills),
                  const SizedBox(height: 12),
                ],
                Text(
                  outpost.name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.pageTitle.copyWith(fontSize: 24),
                ),
                if (outpost.subject.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    outpost.subject,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body.copyWith(color: ColorName.greyText),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Img(
                      src: outpost.creator_user_image,
                      size: 32,
                      alt: creatorName.isEmpty ? 'OO' : creatorName,
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Hosted by', style: AppText.caption),
                          Text(
                            iAmOwner ? 'You' : creatorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.cardTitle.copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessInfo extends StatelessWidget {
  final OutpostModel outpost;
  final bool iAmOwner;
  const _AccessInfo({required this.outpost, required this.iAmOwner});

  @override
  Widget build(BuildContext context) {
    final speakers = _InfoTile(
      icon: Icons.mic_rounded,
      color: AppColors.success,
      label: 'Speakers',
      value: parseSpeakerType(outpost.speak_type),
    );
    if (!iAmOwner) return speakers;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _InfoTile(
              icon: Icons.lock_open_rounded,
              color: AppColors.primary,
              label: 'Access',
              value: parseAccessType(outpost.enter_type),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: speakers),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _InfoTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _IconBadge(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label.toUpperCase(),
                    style: AppText.label),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.cardTitle.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _ActionRow({
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
              const Icon(
                Icons.chevron_right_rounded,
                color: ColorName.greyText,
              ),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final OutpostModel outpost;
  final bool showInvite;
  const _BottomActionBar({required this.outpost, required this.showInvite});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: ColorName.cardBackground.withAlpha(235),
        border: const Border(top: BorderSide(color: ColorName.cardBorder)),
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
                _IconBadge(
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFeatures: [FontFeature.tabularFigures()],
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
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: Colors.white,
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

class MembersList extends GetView<OutpostDetailController> {
  const MembersList({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final members = controller.membersList.value;
      final doIExistInTheList = members.any((element) => element.uuid == myId);
      if (!doIExistInTheList) {
        members.insert(
          0,
          LiveMember(
              address: myUser.address,
              can_speak: true,
              image: myUser.image!,
              name: myUser.name!,
              uuid: myUser.uuid,
              aptos_address: myUser.aptos_address!),
        );
      }
      // add my user to the top if it doesn't exist in the list

      if (members.length == 0) {
        return const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: LoadingWidget()),
          ),
        );
      }

      return SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: AppSectionHeader(
              title: 'Members',
              count: members.length,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.builder(
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                return UserListTile(
                  key: Key(member.uuid),
                  uuid: member.uuid,
                  name: member.name,
                  image: member.image,
                  followed_by_me: member.followed_by_me,
                  onRequestUpdate: () {
                    controller.updatedFollowDataForMember(member.uuid);
                  },
                );
              },
            ),
          ),
        ],
      );
    });
  }
}

class _LumaIconButton extends GetView<OutpostDetailController> {
  const _LumaIconButton();

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
      return _ActionRow(
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
      int? reminderIsSetForInMinotes = null;
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

      return _ActionRow(
        onTap: () {
          controller.setReminderForOutpost();
        },
        leading: _IconBadge(
          icon: isSet
              ? Icons.notifications_active_rounded
              : Icons.notifications_none_rounded,
          color: AppColors.accent,
        ),
        title: text,
        subtitle: isSet
            ? 'Tap to change'
            : 'Get notified before the outpost starts',
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
                Navigate.to(
                  type: NavigationTypes.toNamed,
                  route: Routes.ONGOING_OUTPOST_CALL,
                );
              } else {
                controller.startTheCall(accesses: accesses);
              }
            }
          : null;
      final background = isRegistered
          ? AppColors.success.withAlpha(36)
          : AppColors.primary;

      return FilledButton(
        onPressed: isJoining ? null : onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          backgroundColor: background,
          foregroundColor: isRegistered ? AppColors.success : Colors.white,
          disabledBackgroundColor:
              isJoining ? background.withAlpha(150) : AppColors.fill,
          disabledForegroundColor: Colors.white.withAlpha(150),
          side: isRegistered
              ? BorderSide(color: AppColors.success.withAlpha(140))
              : null,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        child: isJoining
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
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
                            baseColor: Colors.white,
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
    });
  }
}

void openInviteBottomSheet({required bool canInviteToSpeak}) {
  Get.dialog<void>(
    UserInvitationBottomSheetContent(
      canInviteToSpeak: canInviteToSpeak,
    ),
  );
}

bool canInvite({
  required OutpostModel outpost,
  required String currentUserId,
}) {
  final iAmCreator = currentUserId == outpost.creator_user_uuid;
  final isGroupPublic = outpost.enter_type == FreeOutpostAccessTypes.public;
  final amIAMember = (outpost.i_am_member);
  if (iAmCreator || isGroupPublic || amIAMember) {
    return true;
  }
  return false;
}

bool canInviteToSpeak({
  required OutpostModel outpost,
  required String currentUserId,
}) {
  final iAmCreator = currentUserId == outpost.creator_user_uuid;
  final isGroupPublic = outpost.speak_type == FreeOutpostSpeakerTypes.everyone;
  if (iAmCreator || isGroupPublic) {
    return true;
  }
  return false;
}

class UserInvitationBottomSheetContent
    extends GetView<OutpostDetailController> {
  final bool canInviteToSpeak;
  const UserInvitationBottomSheetContent({
    super.key,
    required this.canInviteToSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.65,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Invite users', style: AppText.title),
                        SizedBox(height: 2),
                        Text(
                          'Find people and invite them in',
                          style: AppText.caption,
                        ),
                      ],
                    ),
                  ),
                  AppIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Close',
                    size: 36,
                    onTap: () {
                      Get.close();
                      controller.listOfSearchedUsersToInvite.value = [];
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                autofocus: true,
                onChanged: (value) {
                  controller.searchUsers(value);
                },
                decoration: const InputDecoration(
                  hintText: 'Enter User\'s Name',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                final users = controller.listOfSearchedUsersToInvite.value;
                final loadingInviteId = controller.loadingInviteId.value;
                final liveInvitedMembers = controller.liveInvitedMembers.value;
                if (users.isEmpty) {
                  return const SingleChildScrollView(
                    child: AppEmptyState(
                      icon: Icons.person_search_rounded,
                      title: 'Search for people',
                      message: 'Type a name to find users to invite',
                      compact: true,
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final userInInvitedList = liveInvitedMembers[user.uuid];
                    final invitedToSpeak = userInInvitedList?.can_speak;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.fill,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Img(
                            src: user.image ?? '',
                            size: 36,
                            alt: user.name,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(18)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              user.name ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: invitedToSpeak == null
                                    ? Colors.white
                                    : ColorName.greyText,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (invitedToSpeak != null)
                            AppPill(
                              label:
                                  'Invited ${invitedToSpeak ? 'to speak' : 'to listen'}',
                              color: invitedToSpeak
                                  ? AppColors.success
                                  : AppColors.primary,
                              icon: Icons.check_rounded,
                            )
                          else ...[
                            if (canInviteToSpeak) ...[
                              _InviteChipButton(
                                label: 'Speak',
                                tooltip: 'Invite to speak',
                                icon: Icons.mic_rounded,
                                color: AppColors.success,
                                loading: loadingInviteId == user.uuid + 'true',
                                onPressed: () {
                                  controller.inviteUserToJoinThisOutpost(
                                    userId: user.uuid,
                                    inviteToSpeak: true,
                                  );
                                },
                              ),
                              const SizedBox(width: 6),
                            ],
                            _InviteChipButton(
                              label: 'Listen',
                              tooltip: 'Invite to listen',
                              icon: Icons.headphones_rounded,
                              color: AppColors.primary,
                              loading: loadingInviteId == user.uuid + 'false',
                              onPressed: () {
                                controller.inviteUserToJoinThisOutpost(
                                  userId: user.uuid,
                                  inviteToSpeak: false,
                                );
                              },
                            ),
                          ],
                        ],
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

class _InviteChipButton extends StatelessWidget {
  final String label;
  final String tooltip;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onPressed;
  const _InviteChipButton({
    required this.label,
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          minimumSize: const Size(0, 34),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          foregroundColor: color,
          backgroundColor: color.withAlpha(24),
          side: BorderSide(color: color.withAlpha(90)),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        child: loading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14),
                  const SizedBox(width: 4),
                  Text(label),
                ],
              ),
      ),
    );
  }
}
