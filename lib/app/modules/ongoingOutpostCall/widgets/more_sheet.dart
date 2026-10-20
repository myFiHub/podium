import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/widgets/outpost_bans_sheet.dart';
import 'package:podium/app/modules/global/widgets/outpostsList.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/call_room_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/ongoing_outpost_call_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/views/report_form.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/breakout_sheet.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/call_sheet.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/member_interactions.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/music_sheet.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/participants_sheet.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/poll_sheet.dart';
import 'package:podium/app/modules/outpostDetail/views/outpost_detail_view.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/storage.dart';
import 'package:podium/widgets/ui/app_ui.dart';

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
    HapticFeedback.selectionClick();
    Get.closeOverlay();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final callController = controller.outpostCallController;
    final room = findCallRoom();
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: CallSheet.maxHeight(context, 0.88)),
      child: Obx(() {
        final outpost = callController.outpost.value;
        return CallSheet(
          title: 'More',
          subtitle: outpost?.name,
          icon: Icons.grid_view_rounded,
          child: outpost == null
              ? const SizedBox(height: 80)
              : _body(context, room),
        );
      }),
    );
  }

  Widget _body(BuildContext context, CallRoomController? room) {
    final callController = controller.outpostCallController;
    final outpost = callController.outpost.value!;
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
    final canOfferShare =
        (room?.screenShareSupported ?? false) && callController.canTalk.value;
    final musicOn = room?.nowPlaying.value != null;

    final essentials = <_MoreTile>[
      _MoreTile(
        icon: Icons.people_alt_rounded,
        label: 'People',
        badge: '$memberCount',
        color: AppColors.primary,
        onTap: () => _runAfterClose(openParticipantsSheet),
      ),
      if (canInvite(outpost: outpost, currentUserId: myId))
        _MoreTile(
          icon: Icons.person_add_alt_1_rounded,
          label: 'Invite',
          color: AppColors.violet,
          onTap: () => _runAfterClose(
            () => openInviteBottomSheet(
              canInviteToSpeak: canInviteToSpeak(
                outpost: outpost,
                currentUserId: myId,
              ),
            ),
          ),
        ),
      if (sharing)
        _MoreTile(
          icon: Icons.stop_screen_share_rounded,
          label: 'Stop sharing',
          color: callDangerColor,
          active: true,
          onTap: () => _runAfterClose(room!.stopScreenShare),
        )
      else if (canOfferShare)
        _MoreTile(
          icon: Icons.screen_share_rounded,
          label: 'Share screen',
          color: AppColors.primary,
          onTap: () => _runAfterClose(room!.startScreenShare),
        ),
      if (canShareOutpostUrl(outpost: outpost))
        _MoreTile(
          icon: Icons.link_rounded,
          label: 'Copy link',
          color: AppColors.magenta,
          onTap: () => _runAfterClose(() {
            Clipboard.setData(
              ClipboardData(
                text: generateOutpostShareUrl(outpostId: outpost.uuid),
              ),
            );
            Toast.info(title: 'Copied!', message: 'URL copied to clipboard');
          }),
        ),
    ];

    final tools = <_MoreTile>[
      if (room != null &&
          room.breakoutSupported &&
          (canModerate || room.breakout.value.breakoutRooms.isNotEmpty))
        _MoreTile(
          icon: Icons.meeting_room_rounded,
          label: 'Rooms',
          badge: room.breakout.value.breakoutRooms.isEmpty
              ? null
              : '${room.breakout.value.breakoutRooms.length}',
          color: AppColors.violet,
          onTap: () => _runAfterClose(openBreakoutSheet),
        ),
      if (room != null && room.canControlMusic)
        _MoreTile(
          icon:
              musicOn ? Icons.graphic_eq_rounded : Icons.library_music_rounded,
          label: musicOn ? 'Playing' : 'Music',
          color: callSpeakingColor,
          active: musicOn,
          onTap: () => _runAfterClose(openMusicSheet),
        ),
      if (poll != null && poll.isOpen)
        _MoreTile(
          icon: Icons.poll_rounded,
          label: 'Live poll',
          color: callAccentColor,
          active: true,
          onTap: () => _runAfterClose(openPollSheet),
        )
      else if (canStartPoll)
        _MoreTile(
          icon: Icons.add_chart_rounded,
          label: 'Start poll',
          color: callAccentColor,
          onTap: () => _runAfterClose(openCreatePollSheet),
        ),
      if (canEndPoll)
        _MoreTile(
          icon: Icons.stop_circle_rounded,
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
    ];

    final hostControls = <_MoreTile>[
      if (amICreator && outpost.is_recordable)
        _MoreTile(
          icon: isRecording
              ? Icons.stop_circle_rounded
              : Icons.fiber_manual_record_rounded,
          label: isStartingRecord
              ? 'Starting…'
              : isRecording
                  ? 'Stop rec'
                  : 'Record',
          color: callDangerColor,
          active: isRecording,
          onTap: isStartingRecord
              ? null
              : () => _runAfterClose(
                    isRecording
                        ? controller.stopRecording
                        : controller.startRecording,
                  ),
        ),
      if (canModerate)
        _MoreTile(
          icon: Icons.volume_off_rounded,
          label: 'Mute all',
          color: ColorName.white,
          onTap: () => _runAfterClose(() {
            room!.muteEveryone();
            Toast.info(title: 'Done', message: 'Everyone was muted');
          }),
        ),
      if (canModerate && hands > 0)
        _MoreTile(
          icon: Icons.back_hand_rounded,
          label: 'Lower hands',
          badge: '$hands',
          color: callAccentColor,
          onTap: () => _runAfterClose(room!.lowerAllHands),
        ),
      if (room?.amIHost ?? false)
        _MoreTile(
          icon: Icons.block_rounded,
          label: 'Blocked',
          color: callDangerColor,
          onTap: () => _runAfterClose(
            () => openOutpostBansSheet(
              outpostId: outpost.uuid,
              creatorUuid: outpost.creator_user_uuid,
            ),
          ),
        ),
    ];

    var section = 0;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (title, tiles) in [
            (null, essentials),
            ('Room tools', tools),
            ('Host controls', hostControls),
          ])
            if (tiles.isNotEmpty)
              AppEntrance(
                index: section++,
                child: _Section(title: title, tiles: tiles),
              ),
          const SizedBox(height: 4),
          AppEntrance(
            index: section,
            child: Row(
              children: [
                Expanded(
                  child: _FooterButton(
                    icon: Icons.lightbulb_outline_rounded,
                    label: 'Tutorial',
                    onTap: () => _runAfterClose(() {
                      GetStorage().remove(IntroStorageKeys.viewedOngiongCall);
                      controller.startIntro();
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FooterButton(
                    icon: Icons.flag_outlined,
                    label: 'Report',
                    color: callDangerColor,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String? title;
  final List<_MoreTile> tiles;
  const _Section({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
        decoration: BoxDecoration(
          color: ColorName.white.withAlpha(6),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                child: Text(title!.toUpperCase(), style: AppText.label),
              ),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth / 4;
                return Wrap(
                  runSpacing: 10,
                  children: [
                    for (final tile in tiles)
                      SizedBox(width: width, child: tile),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  /// Glows to show the feature is currently on (recording, music, a poll).
  final bool active;

  /// Small count shown on the icon's corner.
  final String? badge;

  const _MoreTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    this.active = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: AppPressScale(
        enabled: enabled,
        scale: 0.92,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _iconBox(),
                    if (badge != null)
                      Positioned(
                        top: -5,
                        right: -7,
                        child: _CountBadge(text: badge!, color: color),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? color : ColorName.white.withAlpha(220),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconBox() {
    final box = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withAlpha(active ? 70 : 34),
            color.withAlpha(active ? 30 : 12),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withAlpha(active ? 160 : 46)),
        boxShadow: [
          if (active) BoxShadow(color: color.withAlpha(70), blurRadius: 14),
        ],
      ),
      child: Icon(icon, color: color, size: 24),
    );
    if (!active) return box;
    return AppBreathing(
      period: const Duration(milliseconds: 1800),
      builder: (context, v) => Transform.scale(scale: 1 + 0.03 * v, child: box),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _CountBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.surfaceRaised, width: 2),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          height: 1.2,
          fontWeight: FontWeight.w800,
          color: AppColors.onColor(color),
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _FooterButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fg = color ?? ColorName.greyText;
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: fg,
        minimumSize: const Size.fromHeight(44),
        backgroundColor: AppColors.fill,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
