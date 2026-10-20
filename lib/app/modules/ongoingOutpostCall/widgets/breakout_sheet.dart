import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/call_room_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/call_sheet.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/member_interactions.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/ui/aurora.dart';

void openBreakoutSheet() {
  if (findCallRoom() == null) return;
  Get.bottomSheet(
    const BreakoutSheet(),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

void openCreateBreakoutRoomDialog() {
  final room = findCallRoom();
  if (room == null || !room.canModerate) return;
  Get.dialog(const AppDialogMotion(child: _CreateRoomDialog()));
}

/// Main room and breakout rooms. Everyone can move between rooms; hosts
/// with Jitsi moderation can also create, fill and close them.
class BreakoutSheet extends GetView<CallRoomController> {
  const BreakoutSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: CallSheet.maxHeight(context, 0.85)),
      child: CallSheet(
        title: 'Rooms',
        trailing: Obx(() {
          if (!controller.canModerate) return const SizedBox.shrink();
          return IconButton(
            tooltip: 'New room',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.add_rounded, color: ColorName.primaryBlue),
            onPressed: openCreateBreakoutRoomDialog,
          );
        }),
        child: Obx(() {
          final state = controller.breakout.value;
          final canModerate = controller.canModerate;
          final breakoutRooms = state.breakoutRooms;
          if (breakoutRooms.isEmpty) {
            return _NoRooms(canModerate: canModerate);
          }
          final current = state.currentRoom;
          final anyoneOut = breakoutRooms.any((r) => r.participants.isNotEmpty);
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (canModerate) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: controller.autoAssignBreakoutRooms,
                          icon: const Icon(Icons.shuffle_rounded, size: 18),
                          label: const Text('Auto-assign'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: anyoneOut
                              ? controller.closeAllBreakoutRooms
                              : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: callDangerColor,
                          ),
                          icon: const Icon(Icons.call_merge_rounded, size: 18),
                          label: const Text('Close all'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                for (final room in state.rooms)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RoomCard(
                      room: room,
                      isCurrent: current?.id == room.id,
                      rooms: state.rooms,
                      canModerate: canModerate,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _NoRooms extends StatelessWidget {
  final bool canModerate;
  const _NoRooms({required this.canModerate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.meeting_room_outlined,
              size: 36, color: ColorName.greyText),
          const SizedBox(height: 10),
          Text(
            canModerate
                ? 'Split the room into smaller groups'
                : 'No breakout rooms yet',
            textAlign: TextAlign.center,
            style: TextStyle(color: ColorName.greyText),
          ),
          if (canModerate) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: openCreateBreakoutRoomDialog,
              style: FilledButton.styleFrom(
                backgroundColor: ColorName.primaryBlue,
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Create room'),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoomCard extends GetView<CallRoomController> {
  final BreakoutRoom room;
  final bool isCurrent;
  final List<BreakoutRoom> rooms;
  final bool canModerate;
  const _RoomCard({
    required this.room,
    required this.isCurrent,
    required this.rooms,
    required this.canModerate,
  });

  @override
  Widget build(BuildContext context) {
    final count = room.participants.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: isCurrent
            ? ColorName.primaryBlue.withAlpha(20)
            : ColorName.white.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? ColorName.primaryBlue.withAlpha(110)
              : ColorName.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                room.isMainRoom
                    ? Icons.home_rounded
                    : Icons.meeting_room_rounded,
                size: 18,
                color: isCurrent ? ColorName.primaryBlue : ColorName.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  room.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                '$count',
                style: TextStyle(fontSize: 12, color: ColorName.greyText),
              ),
              const SizedBox(width: 4),
              Icon(Icons.person_outline_rounded,
                  size: 14, color: ColorName.greyText),
              const SizedBox(width: 4),
              if (isCurrent)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'You',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ColorName.primaryBlue,
                    ),
                  ),
                )
              else
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    controller.moveToRoom(room.isMainRoom ? null : room);
                    Get.closeOverlay();
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: ColorName.primaryBlue,
                  ),
                  child: const Text('Join'),
                ),
              if (canModerate && !room.isMainRoom)
                PopupMenuButton<String>(
                  tooltip: 'Room options',
                  icon: Icon(Icons.more_vert_rounded,
                      size: 20, color: ColorName.greyText),
                  onSelected: (action) {
                    if (action == 'close') controller.closeBreakoutRoom(room);
                    if (action == 'remove') controller.removeBreakoutRoom(room);
                  },
                  itemBuilder: (_) => [
                    if (count > 0)
                      const PopupMenuItem(
                        value: 'close',
                        child: Text('Send everyone to main room'),
                      ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove room'),
                    ),
                  ],
                ),
            ],
          ),
          if (count > 0) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final participant in room.participants)
                  _ParticipantChip(
                    participant: participant,
                    from: room,
                    rooms: rooms,
                    canModerate: canModerate,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ParticipantChip extends GetView<CallRoomController> {
  final BreakoutParticipant participant;
  final BreakoutRoom from;
  final List<BreakoutRoom> rooms;
  final bool canModerate;
  const _ParticipantChip({
    required this.participant,
    required this.from,
    required this.rooms,
    required this.canModerate,
  });

  String get _name {
    final uuid = controller.knownUuidOf(participant.participantId);
    if (uuid != null) return controller.displayNameOf(uuid: uuid);
    return participant.displayName.isEmpty
        ? 'Someone'
        : participant.displayName;
  }

  @override
  Widget build(BuildContext context) {
    final targets = rooms.where((r) => r.id != from.id).toList();
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ColorName.white.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              _name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          if (canModerate && targets.isNotEmpty) ...[
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down_rounded,
                size: 16, color: ColorName.greyText),
          ],
        ],
      ),
    );
    if (!canModerate || targets.isEmpty) return chip;
    return PopupMenuButton<BreakoutRoom>(
      tooltip: 'Move to…',
      onSelected: (target) => controller.sendParticipantToRoom(
        participant.participantId,
        target,
      ),
      itemBuilder: (_) => [
        for (final target in targets)
          PopupMenuItem(
            value: target,
            child: Text('Move to ${target.label}'),
          ),
      ],
      child: chip,
    );
  }
}

class _CreateRoomDialog extends StatefulWidget {
  const _CreateRoomDialog();

  @override
  State<_CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends State<_CreateRoomDialog> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _create() {
    findCallRoom()?.createBreakoutRoom(_name.text);
    Get.closeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New breakout room'),
      content: TextField(
        controller: _name,
        autofocus: true,
        maxLength: 40,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _create(),
        decoration: const InputDecoration(
          hintText: 'Name (optional)',
          counterText: '',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.closeOverlay(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _create,
          style: FilledButton.styleFrom(backgroundColor: ColorName.primaryBlue),
          child: const Text('Create'),
        ),
      ],
    );
  }
}
