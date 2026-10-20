import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/call_room_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/call_sheet.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/member_interactions.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/ui/app_ui.dart';

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
  Get.dialog(const _CreateRoomDialog());
}

String _peopleLabel(int count) => count == 1 ? '1 person' : '$count people';

/// Main room and breakout rooms. Everyone can move between rooms; hosts
/// with Jitsi moderation can also create, fill and close them.
class BreakoutSheet extends GetView<CallRoomController> {
  const BreakoutSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: CallSheet.maxHeight(context, 0.85)),
      child: Obx(() {
        final breakoutRooms = controller.breakout.value.breakoutRooms;
        final canModerate = controller.canModerate;
        final out = breakoutRooms.sumBy((r) => r.participants.length);
        return CallSheet(
          title: 'Rooms',
          subtitle: breakoutRooms.isEmpty
              ? 'Split into smaller groups'
              : '${breakoutRooms.length} breakout · ${_peopleLabel(out)} out',
          icon: Icons.meeting_room_rounded,
          iconColor: AppColors.violet,
          trailing: canModerate && breakoutRooms.isNotEmpty
              ? const _NewRoomButton()
              : null,
          child: _body(),
        );
      }),
    );
  }

  Widget _body() {
    final state = controller.breakout.value;
    final canModerate = controller.canModerate;
    if (state.breakoutRooms.isEmpty) {
      return _NoRooms(canModerate: canModerate);
    }
    final current = state.currentRoom;
    final anyoneOut = state.breakoutRooms.any((r) => r.participants.isNotEmpty);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canModerate) ...[
            Row(
              children: [
                Expanded(
                  child: _ToolButton(
                    icon: Icons.shuffle_rounded,
                    label: 'Auto-assign',
                    color: AppColors.primary,
                    onPressed: controller.autoAssignBreakoutRooms,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ToolButton(
                    icon: Icons.call_merge_rounded,
                    label: 'Bring all back',
                    color: callDangerColor,
                    onPressed:
                        anyoneOut ? controller.closeAllBreakoutRooms : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          for (final (i, room) in state.rooms.indexed)
            AppEntrance(
              index: i,
              id: 'breakout-${room.id}',
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RoomCard(
                  room: room,
                  isCurrent: current?.id == room.id,
                  rooms: state.rooms,
                  canModerate: canModerate,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NewRoomButton extends StatelessWidget {
  const _NewRoomButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: FilledButton.icon(
        onPressed: openCreateBreakoutRoomDialog,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('New'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.violet.withAlpha(40),
          foregroundColor: AppColors.violet,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.fromLTRB(10, 0, 14, 0),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: StadiumBorder(
            side: BorderSide(color: AppColors.violet.withAlpha(110)),
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fg = enabled ? color : ColorName.greyText;
    return AppPressScale(
      enabled: enabled,
      child: TextButton.icon(
        onPressed: onPressed == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPressed!();
              },
        icon: Icon(icon, size: 18),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: TextButton.styleFrom(
          foregroundColor: fg,
          disabledForegroundColor: fg.withAlpha(140),
          backgroundColor: fg.withAlpha(enabled ? 24 : 10),
          minimumSize: const Size.fromHeight(44),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: fg.withAlpha(enabled ? 80 : 30)),
          ),
        ),
      ),
    );
  }
}

class _NoRooms extends StatelessWidget {
  final bool canModerate;
  const _NoRooms({required this.canModerate});

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      compact: true,
      icon: Icons.meeting_room_outlined,
      title: canModerate ? 'Break into groups' : 'No breakout rooms yet',
      message: canModerate
          ? 'Create rooms for focused side conversations. Everyone can hop '
              'back to the main room anytime.'
          : 'When the host opens rooms, they will show up here.',
      actionLabel: 'Create a room',
      onAction: canModerate ? openCreateBreakoutRoomDialog : null,
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

  void _join() {
    HapticFeedback.selectionClick();
    controller.moveToRoom(room.isMainRoom ? null : room);
    Get.closeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    final count = room.participants.length;
    final tint = room.isMainRoom ? AppColors.primary : AppColors.violet;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
      radius: AppRadius.lg,
      color: isCurrent ? tint.withAlpha(18) : ColorName.white.withAlpha(6),
      borderColor: isCurrent ? tint.withAlpha(140) : AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconTile(
                icon: room.isMainRoom
                    ? Icons.home_rounded
                    : Icons.meeting_room_rounded,
                color: tint,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.cardTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      count == 0 ? 'Empty' : _peopleLabel(count),
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
              if (isCurrent)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: AppPill(
                    label: "You're here",
                    color: tint,
                    icon: Icons.check_rounded,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: FilledButton(
                    onPressed: _join,
                    style: FilledButton.styleFrom(
                      backgroundColor: tint,
                      foregroundColor: AppColors.onColor(tint),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Join'),
                  ),
                ),
              if (canModerate && !room.isMainRoom)
                PopupMenuButton<String>(
                  tooltip: 'Room options',
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: ColorName.greyText,
                  ),
                  onSelected: (action) {
                    if (action == 'close') controller.closeBreakoutRoom(room);
                    if (action == 'remove') controller.removeBreakoutRoom(room);
                  },
                  itemBuilder: (_) => [
                    if (count > 0)
                      const PopupMenuItem(
                        value: 'close',
                        child: _MenuRow(
                          icon: Icons.call_merge_rounded,
                          label: 'Send everyone to main room',
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: _MenuRow(
                        icon: Icons.delete_outline_rounded,
                        label: 'Remove room',
                        danger: true,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (count > 0) ...[
            const SizedBox(height: 12),
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

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  const _MenuRow({
    required this.icon,
    required this.label,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? callDangerColor : ColorName.white;
    return Row(
      children: [
        Icon(icon, size: 18, color: danger ? color : ColorName.greyText),
        const SizedBox(width: 12),
        Flexible(child: Text(label, style: TextStyle(color: color))),
      ],
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

  @override
  Widget build(BuildContext context) {
    final uuid = controller.knownUuidOf(participant.participantId);
    final name = uuid != null
        ? controller.displayNameOf(uuid: uuid)
        : participant.displayName.isEmpty
            ? 'Someone'
            : participant.displayName;
    final member = uuid == null
        ? null
        : Get.find<OutpostCallController>()
            .members
            .value
            .firstOrNullWhere((m) => m.uuid == uuid);
    final targets = rooms.where((r) => r.id != from.id).toList();
    final movable = canModerate && targets.isNotEmpty;
    final chip = Container(
      padding: EdgeInsets.fromLTRB(3, 3, movable ? 4 : 10, 3),
      decoration: BoxDecoration(
        color: ColorName.white.withAlpha(12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Img(
            src: member == null ? '' : memberAvatar(member),
            alt: member?.name ?? name,
            size: 22,
            borderRadius: BorderRadius.circular(22),
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          if (movable) ...[
            const SizedBox(width: 2),
            Icon(
              Icons.swap_horiz_rounded,
              size: 15,
              color: ColorName.greyText,
            ),
          ],
        ],
      ),
    );
    if (!movable) return chip;
    return PopupMenuButton<BreakoutRoom>(
      tooltip: 'Move $name',
      onSelected: (target) => controller.sendParticipantToRoom(
        participant.participantId,
        target,
      ),
      itemBuilder: (_) => [
        for (final target in targets)
          PopupMenuItem(
            value: target,
            child: _MenuRow(
              icon: target.isMainRoom
                  ? Icons.home_rounded
                  : Icons.meeting_room_rounded,
              label: 'Move to ${target.label}',
            ),
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
  static const _suggestions = ['Q&A', 'Ideas', 'Deep dive', 'Hangout'];

  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _create() {
    HapticFeedback.lightImpact();
    findCallRoom()?.createBreakoutRoom(_name.text);
    Get.closeOverlay();
  }

  void _suggest(String name) {
    HapticFeedback.selectionClick();
    _name.value = TextEditingValue(
      text: name,
      selection: TextSelection.collapsed(offset: name.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'New breakout room',
      message: 'People can join it from the Rooms sheet. Leave the name '
          'empty to number it automatically.',
      icon: Icons.meeting_room_rounded,
      iconColor: AppColors.violet,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            maxLength: 40,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _create(),
            decoration: const InputDecoration(
              hintText: 'Room name (optional)',
              prefixIcon: Icon(Icons.edit_rounded, size: 18),
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder(
            valueListenable: _name,
            builder: (context, value, _) => Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final name in _suggestions)
                  _SuggestionChip(
                    label: name,
                    selected: value.text == name,
                    onTap: () => _suggest(name),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        AppSecondaryButton(
          label: 'Cancel',
          onPressed: () => Get.closeOverlay(),
        ),
        AppPrimaryButton(
          label: 'Create',
          icon: Icons.add_rounded,
          onPressed: _create,
        ),
      ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SuggestionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tint = selected ? AppColors.violet : ColorName.greyText;
    return AppPressScale(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? tint.withAlpha(36) : AppColors.fill,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? tint.withAlpha(140) : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? tint : ColorName.white,
            ),
          ),
        ),
      ),
    );
  }
}
