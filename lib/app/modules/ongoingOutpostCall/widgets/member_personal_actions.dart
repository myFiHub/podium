import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/services/blocked_users_service.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/call_room_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/chat_sheet.dart';
import 'package:podium/providers/api/podium/models/outposts/liveData.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/widgets/ui/app_ui.dart';

/// Message and block, for someone else in the outpost.
class MemberPersonalActions extends StatelessWidget {
  final LiveMember member;
  const MemberPersonalActions({super.key, required this.member});

  void _message() {
    Get.closeOverlay();
    openChatSheet(privateWith: member.uuid);
  }

  Future<void> _toggleBlock() async {
    final blocks = Get.find<BlockedUsersService>();
    final name = member.name ?? 'this member';
    if (blocks.isBlocked(member.uuid)) {
      if (await blocks.unblock(member.uuid)) {
        Toast.info(title: 'Unblocked', message: '$name can message you again');
      }
      return;
    }
    if (!await confirmBlockUser(name)) return;
    final room = findCallRoom();
    final ok = room != null
        ? await room.blockUser(member.uuid)
        : await blocks.block(
            member.uuid,
            name: member.name,
            image: member.image,
          );
    if (ok) {
      Toast.info(
        title: 'Blocked',
        message: "$name can't message you, and their chat is hidden",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocks = Get.find<BlockedUsersService>();
    return Obx(() {
      final blocked = blocks.isBlocked(member.uuid);
      final canMessage = member.is_present && !blocked;
      return Row(
        children: [
          Expanded(
            child: AppSecondaryButton(
              label: 'Message',
              icon: Icons.lock_outline_rounded,
              onPressed: canMessage && findCallRoom() != null ? _message : null,
            ),
          ),
          if (blocks.available.value) ...[
            const SizedBox(width: 8),
            Expanded(
              child: AppSecondaryButton(
                label: blocked ? 'Unblock' : 'Block',
                icon: blocked ? Icons.lock_open_rounded : Icons.block_rounded,
                color: blocked ? null : AppColors.danger,
                onPressed: _toggleBlock,
              ),
            ),
          ],
        ],
      );
    });
  }
}
