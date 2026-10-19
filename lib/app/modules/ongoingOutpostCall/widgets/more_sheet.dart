import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/widgets/outpostsList.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/call_room_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/ongoing_outpost_call_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/views/report_form.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/call_sheet.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/member_interactions.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/participants_sheet.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/poll_sheet.dart';
import 'package:podium/app/modules/outpostDetail/views/outpost_detail_view.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/storage.dart';
import 'package:podium/widgets/ui/aurora.dart';

void openMoreSheet() {
  Get.bottomSheet(
    const MoreSheet(),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class MoreSheet extends GetView<OngoingOutpostCallController> {
  const MoreSheet({super.key});

  void _runAfterClose(VoidCallback action) {
    Get.closeOverlay();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final callController = controller.outpostCallController;
    final room = findCallRoom();
    return CallSheet(
      child: Obx(() {
        final outpost = callController.outpost.value;
        if (outpost == null) return const SizedBox(height: 80);
        final amICreator = outpost.creator_user_uuid == myId;
        final memberCount = callController.members.value.length;
        final isRecording = controller.isRecording.value;
        final isStartingRecord = controller.isStartingToRecord.value;
        final canModerate = room?.canModerate ?? false;
        final hands = room?.raisedHandUuids.length ?? 0;
        final poll = room?.activePoll.value;
        final canStartPoll = room?.canStartPoll ?? false;
        final canEndPoll = room?.canEndPoll ?? false;
        final sharing = room?.localSharing.value ?? false;
        final canOfferShare = (room?.screenShareSupported ?? false) &&
            callController.canTalk.value;

        final tiles = <_MoreTile>[
          if (sharing)
            _MoreTile(
              icon: Icons.stop_screen_share_outlined,
              label: 'Stop sharing',
              color: callDangerColor,
              onTap: () => _runAfterClose(room!.stopScreenShare),
            )
          else if (canOfferShare)
            _MoreTile(
              icon: Icons.screen_share_outlined,
              label: 'Share screen',
              onTap: () => _runAfterClose(room!.startScreenShare),
            ),
          _MoreTile(
            icon: Icons.people_alt_outlined,
            label: 'People ($memberCount)',
            onTap: () => _runAfterClose(openParticipantsSheet),
          ),
          if (canInvite(outpost: outpost, currentUserId: myId))
            _MoreTile(
              icon: Icons.person_add_alt_1_outlined,
              label: 'Invite',
              onTap: () => _runAfterClose(
                () => openInviteBottomSheet(
                  canInviteToSpeak: canInviteToSpeak(
                    outpost: outpost,
                    currentUserId: myId,
                  ),
                ),
              ),
            ),
          if (amICreator && outpost.is_recordable)
            _MoreTile(
              icon: isRecording
                  ? Icons.stop_circle_outlined
                  : Icons.fiber_manual_record,
              label: isStartingRecord
                  ? 'Starting…'
                  : isRecording
                      ? 'Stop recording'
                      : 'Record',
              color: callDangerColor,
              onTap: isStartingRecord
                  ? null
                  : () => _runAfterClose(
                        isRecording
                            ? controller.stopRecording
                            : controller.startRecording,
                      ),
            ),
          if (canStartPoll)
            _MoreTile(
              icon: Icons.poll_outlined,
              label: 'Start poll',
              onTap: () => _runAfterClose(openCreatePollSheet),
            ),
          if (poll != null && poll.isOpen)
            _MoreTile(
              icon: Icons.poll_rounded,
              label: 'Active poll',
              color: ColorName.primaryBlue,
              onTap: () => _runAfterClose(openPollSheet),
            ),
          if (canEndPoll)
            _MoreTile(
              icon: Icons.stop_circle_outlined,
              label: 'End poll',
              color: callDangerColor,
              onTap: () => _runAfterClose(() {
                room!.endPoll();
                Toast.info(
                  title: 'Poll ended',
                  message: 'Final results are visible to everyone',
                );
              }),
            ),
          if (canModerate)
            _MoreTile(
              icon: Icons.volume_off_outlined,
              label: 'Mute everyone',
              onTap: () => _runAfterClose(() {
                room!.muteEveryone();
                Toast.info(title: 'Done', message: 'Everyone was muted');
              }),
            ),
          if (canModerate && hands > 0)
            _MoreTile(
              icon: Icons.back_hand_outlined,
              label: 'Lower all hands',
              onTap: () => _runAfterClose(room!.lowerAllHands),
            ),
          if (canShareOutpostUrl(outpost: outpost))
            _MoreTile(
              icon: Icons.link_rounded,
              label: 'Copy link',
              onTap: () => _runAfterClose(() {
                Clipboard.setData(
                  ClipboardData(
                    text: generateOutpostShareUrl(outpostId: outpost.uuid),
                  ),
                );
                Toast.info(
                    title: 'Copied!', message: 'URL copied to clipboard');
              }),
            ),
          _MoreTile(
            icon: Icons.lightbulb_outline,
            label: 'Tutorial',
            onTap: () => _runAfterClose(() {
              GetStorage().remove(IntroStorageKeys.viewedOngiongCall);
              controller.startIntro();
            }),
          ),
          _MoreTile(
            icon: Icons.flag_outlined,
            label: 'Report',
            onTap: () => _runAfterClose(() {
              Get.dialog(
                AppDialogMotion(
                  child: Dialog(
                    backgroundColor: ColorName.cardBackground,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ReportForm(),
                    ),
                  ),
                ),
              );
            }),
          ),
        ];

        return GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 8,
          childAspectRatio: 0.85,
          children: tiles,
        );
      }),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  Color get _color => color ?? ColorName.white;

  const _MoreTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: ColorName.white.withAlpha(12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: _color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: ColorName.greyText),
          ),
        ],
      ),
    );
  }
}
