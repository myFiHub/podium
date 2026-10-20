import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/call_room_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/call_sheet.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/member_interactions.dart';
import 'package:podium/providers/api/podium/models/breakout/breakout_access.dart';
import 'package:podium/services/toast/toast.dart';
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
  Get.dialog(const _RoomDialog());
}

Future<void> _openEditAccessDialog(BreakoutRoom room) async {
  final controller = findCallRoom();
  if (controller == null) return;
  if (controller.accessOf(room) == null) {
    await controller.refreshBreakoutAccess();
  }
  final access = controller.accessOf(room);
  if (access == null) {
    Toast.error(
      title: "Can't edit this room",
      message: "Its access rules couldn't be loaded. Try again in a moment.",
    );
    return;
  }
  Get.dialog(_RoomDialog(editing: room, access: access));
}

/// Moves this device into [room], asking for the password or explaining a
/// refusal when the room is protected. True once the move is under way.
Future<bool> enterBreakoutRoom(
  BreakoutRoom room, {
  bool movedByHost = false,
}) async {
  final controller = findCallRoom();
  if (controller == null) return false;
  final result =
      await controller.joinBreakoutRoom(room.isMainRoom ? null : room);
  switch (result) {
    case BreakoutJoinResult.moved:
      if (movedByHost) {
        Toast.info(
          title: 'Moving rooms',
          message: 'A host moved you to ${room.label}',
        );
      }
      return true;
    case BreakoutJoinResult.passwordRequired:
      final moved = await Get.dialog<bool>(_PasswordDialog(room: room));
      return moved == true;
    case BreakoutJoinResult.wrongPassword:
    case BreakoutJoinResult.failed:
      Toast.error(
        title: "Couldn't join ${room.label}",
        message: 'Something went wrong. Try again in a moment.',
      );
    case BreakoutJoinResult.notInvited:
      Toast.warning(
        title: '${room.label} is invite only',
        message: 'Ask a host to invite you.',
      );
    case BreakoutJoinResult.tooManyAttempts:
      Toast.warning(
        title: 'Too many attempts',
        message: 'Wait a few minutes before trying ${room.label} again.',
      );
    case BreakoutJoinResult.gone:
      Toast.warning(
        title: '${room.label} is gone',
        message: 'A host closed this room.',
      );
      controller.refreshBreakoutAccess();
    case BreakoutJoinResult.unsupported:
      Toast.warning(
        title: "Can't join ${room.label}",
        message: 'This room is protected. Update Podium to join it.',
      );
  }
  return false;
}

String _peopleLabel(int count) => count == 1 ? '1 person' : '$count people';

/// The server drops an empty main room together with its breakout rooms.
Future<bool> _confirmLeavingEmptyMainRoom() => showAppConfirm(
      title: "You're alone in the main room",
      message: 'Leaving it empty closes the main room, and the breakout '
          'rooms created in it are lost. You can still come back to a new '
          'main room.',
      confirmLabel: 'Join anyway',
      cancelLabel: 'Stay',
      destructive: true,
    );

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
        // Read here because the room cards build outside this Obx.
        controller.breakoutAccess.length;
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
            _ToolButton(
              icon: Icons.call_merge_rounded,
              label: 'Bring all back',
              color: callDangerColor,
              onPressed: anyoneOut ? controller.closeAllBreakoutRooms : null,
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

  Future<void> _join(BuildContext context) async {
    HapticFeedback.selectionClick();
    final aloneInMain = !room.isMainRoom &&
        !controller.inBreakoutRoom &&
        controller.peers.isEmpty;
    if (aloneInMain && !await _confirmLeavingEmptyMainRoom()) return;
    final moved = await enterBreakoutRoom(room);
    if (moved && context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final count = room.participants.length;
    final tint = room.isMainRoom ? AppColors.primary : AppColors.violet;
    final access = controller.accessOf(room);
    final protected = room.podiumAccess != null;
    final locked = protected && access != null && !access.canJoin;
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
                    if (access != null &&
                        (access.isProtected || access.isInvited)) ...[
                      const SizedBox(height: 6),
                      _AccessPills(access: access),
                    ],
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
                  child: FilledButton.icon(
                    onPressed: locked ? null : () => _join(context),
                    icon: access?.requiresPassword == true || locked
                        ? const Icon(Icons.lock_rounded, size: 16)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: tint,
                      foregroundColor: AppColors.onColor(tint),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      shape: const StadiumBorder(),
                    ),
                    label: Text(locked ? 'Invite only' : 'Join'),
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
                    if (action == 'access') _openEditAccessDialog(room);
                    if (action == 'close') controller.closeBreakoutRoom(room);
                    if (action == 'remove') controller.removeBreakoutRoom(room);
                  },
                  itemBuilder: (_) => [
                    if (protected)
                      const PopupMenuItem(
                        value: 'access',
                        child: _MenuRow(
                          icon: Icons.admin_panel_settings_outlined,
                          label: 'Edit access',
                        ),
                      ),
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

class _AccessPills extends StatelessWidget {
  final BreakoutRoomAccess access;
  const _AccessPills({required this.access});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (access.accessType == BreakoutAccessType.password)
          AppPill(
            label: 'Password',
            icon: Icons.lock_rounded,
            color: AppColors.accent,
          ),
        if (access.accessType == BreakoutAccessType.inviteOnly)
          AppPill(
            label: 'Invite only',
            icon: Icons.how_to_reg_rounded,
            color: AppColors.magenta,
          ),
        if (access.isInvited)
          AppPill(
            label: 'Invited',
            icon: Icons.check_rounded,
            color: AppColors.success,
          ),
      ],
    );
  }
}

/// Asks for a protected room's password and moves in once it's accepted.
/// Resolves to true when the move is under way.
class _PasswordDialog extends StatefulWidget {
  final BreakoutRoom room;
  const _PasswordDialog({required this.room});

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _password.text;
    if (password.isEmpty || _busy) return;
    final controller = findCallRoom();
    if (controller == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result =
        await controller.joinBreakoutRoom(widget.room, password: password);
    if (!mounted) return;
    final error = switch (result) {
      BreakoutJoinResult.moved => null,
      BreakoutJoinResult.wrongPassword => 'Wrong password',
      BreakoutJoinResult.tooManyAttempts =>
        'Too many attempts. Wait a few minutes.',
      BreakoutJoinResult.notInvited => 'This room is invite only now',
      BreakoutJoinResult.gone => 'This room is gone',
      BreakoutJoinResult.unsupported => 'Update Podium to join this room',
      BreakoutJoinResult.passwordRequired ||
      BreakoutJoinResult.failed =>
        'Something went wrong. Try again.',
    };
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: '${widget.room.label} needs a password',
      message: 'Ask a host for it, or for an invite.',
      icon: Icons.lock_rounded,
      iconColor: AppColors.accent,
      content: TextField(
        controller: _password,
        autofocus: true,
        obscureText: _obscure,
        enableSuggestions: false,
        autocorrect: false,
        maxLength: 64,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        decoration: InputDecoration(
          hintText: 'Password',
          counterText: '',
          errorText: _error,
          prefixIcon: const Icon(Icons.key_rounded, size: 18),
          suffixIcon: IconButton(
            tooltip: _obscure ? 'Show password' : 'Hide password',
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(
              _obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 18,
            ),
          ),
        ),
      ),
      actions: [
        AppSecondaryButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        ValueListenableBuilder(
          valueListenable: _password,
          builder: (context, value, _) => AppPrimaryButton(
            label: 'Join',
            loading: _busy,
            onPressed: value.text.isEmpty ? null : _submit,
          ),
        ),
      ],
    );
  }
}

/// Creates a room, or edits the access of [editing].
class _RoomDialog extends StatefulWidget {
  final BreakoutRoom? editing;
  final BreakoutRoomAccess? access;
  const _RoomDialog({this.editing, this.access});

  @override
  State<_RoomDialog> createState() => _RoomDialogState();
}

class _RoomDialogState extends State<_RoomDialog> {
  static const _suggestions = ['Q&A', 'Ideas', 'Deep dive', 'Hangout'];
  static const _minPassword = 4;

  final _name = TextEditingController();
  final _password = TextEditingController();
  late var _accessType = widget.access?.accessType ?? BreakoutAccessType.open;
  late final _invited = {...?widget.access?.invitedUserUuids};
  bool _busy = false;
  bool _obscure = true;

  bool get _editing => widget.editing != null;

  /// Editing a password room may keep its password.
  bool get _hasPassword =>
      widget.access?.accessType == BreakoutAccessType.password;

  @override
  void initState() {
    super.initState();
    if (_editing) _name.text = widget.access?.name ?? widget.editing!.name;
  }

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  String? get _problem {
    if (_accessType != BreakoutAccessType.password) return null;
    final length = _password.text.length;
    if (length == 0 && _hasPassword) return null;
    if (length < _minPassword) {
      return 'Use at least $_minPassword characters';
    }
    return null;
  }

  Future<void> _submit() async {
    final controller = findCallRoom();
    if (controller == null || _busy) return;
    if (_problem != null) {
      setState(() {});
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _busy = true);
    final password = _accessType == BreakoutAccessType.password &&
            _password.text.isNotEmpty
        ? _password.text
        : null;
    final invited = _invited.toList();
    final error = _editing
        ? await controller.updateBreakoutAccess(
            widget.editing!,
            name: _name.text,
            access: _accessType,
            password: password,
            invitedUuids: invited,
          )
        : await controller.createBreakoutRoom(
            name: _name.text,
            access: _accessType,
            password: password,
            invitedUuids: invited,
          );
    if (!mounted) return;
    if (error != null) {
      setState(() => _busy = false);
      Toast.error(
        title: _editing ? "Couldn't save" : "Couldn't create the room",
        message: error,
      );
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _pickInvitees() async {
    final picked = await showAppSheet<Set<String>>(
      _InviteePickerSheet(selected: _invited),
    );
    if (picked != null && mounted) {
      setState(() => _invited
        ..clear()
        ..addAll(picked));
    }
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
    final canProtect = _editing || findCallRoom()?.canProtectRooms == true;
    final problem = _password.text.isEmpty ? null : _problem;
    return AppDialog(
      title: _editing ? 'Room access' : 'New breakout room',
      message: _editing
          ? 'Hosts and invited people can always join. People no longer '
              'allowed are sent back to the main room.'
          : 'People can join it from the Rooms sheet. Leave the name empty '
              'to number it automatically.',
      icon: _editing
          ? Icons.admin_panel_settings_rounded
          : Icons.meeting_room_rounded,
      iconColor: AppColors.violet,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            autofocus: !_editing,
            maxLength: 40,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: _editing ? 'Room name' : 'Room name (optional)',
              prefixIcon: const Icon(Icons.edit_rounded, size: 18),
              counterText: '',
            ),
          ),
          if (!_editing) ...[
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
          if (canProtect) ...[
            const SizedBox(height: 18),
            Text('WHO CAN JOIN', style: AppText.label),
            const SizedBox(height: 8),
            AppSegmented<BreakoutAccessType>(
              color: AppColors.violet,
              value: _accessType,
              onChanged: (type) => setState(() => _accessType = type),
              segments: const [
                (BreakoutAccessType.open, 'Anyone', Icons.public_rounded),
                (BreakoutAccessType.password, 'Password', Icons.lock_rounded),
                (
                  BreakoutAccessType.inviteOnly,
                  'Invited',
                  Icons.how_to_reg_rounded,
                ),
              ],
            ),
            if (_accessType == BreakoutAccessType.password) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: _obscure,
                enableSuggestions: false,
                autocorrect: false,
                maxLength: 64,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: _hasPassword
                      ? 'New password (empty keeps the current one)'
                      : 'Password',
                  counterText: '',
                  errorText: problem,
                  prefixIcon: const Icon(Icons.key_rounded, size: 18),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
            if (_accessType != BreakoutAccessType.open) ...[
              const SizedBox(height: 12),
              _InviteesButton(
                count: _invited.length,
                passwordRoom: _accessType == BreakoutAccessType.password,
                onPressed: _pickInvitees,
              ),
            ],
          ],
        ],
      ),
      actions: [
        AppSecondaryButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppPrimaryButton(
          label: _editing ? 'Save' : 'Create',
          icon: _editing ? Icons.check_rounded : Icons.add_rounded,
          loading: _busy,
          onPressed: _problem == null ? _submit : null,
        ),
      ],
    );
  }
}

class _InviteesButton extends StatelessWidget {
  final int count;
  final bool passwordRoom;
  final VoidCallback onPressed;
  const _InviteesButton({
    required this.count,
    required this.passwordRoom,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final label = count == 0
        ? 'Invite people'
        : count == 1
            ? '1 person invited'
            : '$count people invited';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSecondaryButton(
          label: label,
          icon: Icons.group_add_rounded,
          onPressed: onPressed,
        ),
        const SizedBox(height: 6),
        Text(
          passwordRoom
              ? 'Invited people join without the password.'
              : 'Only hosts and invited people can join.',
          style: AppText.caption,
        ),
      ],
    );
  }
}

/// Picks invitees from the people in the outpost right now. Resolves to the
/// new selection, or null when dismissed.
class _InviteePickerSheet extends StatefulWidget {
  final Set<String> selected;
  const _InviteePickerSheet({required this.selected});

  @override
  State<_InviteePickerSheet> createState() => _InviteePickerSheetState();
}

class _InviteePickerSheetState extends State<_InviteePickerSheet> {
  late final _selected = {...widget.selected};
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = findCallRoom();
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: CallSheet.maxHeight(context, 0.8)),
      child: CallSheet(
        title: 'Invite people',
        subtitle: 'From the people in this outpost now',
        icon: Icons.group_add_rounded,
        iconColor: AppColors.violet,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _query,
              keyboardAppearance: Brightness.dark,
              decoration: const InputDecoration(
                hintText: 'Search',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Obx(() {
                final members = Get.find<OutpostCallController>()
                    .members
                    .value
                    .where((m) =>
                        m.is_present &&
                        !(room?.isHostUuid(m.uuid) ?? false))
                    .sortedBy((m) => (m.name ?? '').toLowerCase())
                    .toList();
                return ValueListenableBuilder(
                  valueListenable: _query,
                  builder: (context, value, _) {
                    final query = value.text.trim().toLowerCase();
                    final shown = members
                        .where((m) =>
                            query.isEmpty ||
                            (m.name ?? '').toLowerCase().contains(query))
                        .toList();
                    if (shown.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          members.isEmpty
                              ? 'Nobody else is here yet'
                              : 'Nobody found',
                          textAlign: TextAlign.center,
                          style: AppText.muted,
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: shown.length,
                      itemBuilder: (context, index) {
                        final member = shown[index];
                        final checked = _selected.contains(member.uuid);
                        return CheckboxListTile(
                          key: ValueKey(member.uuid),
                          value: checked,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.trailing,
                          onChanged: (on) => setState(() {
                            if (on == true) {
                              _selected.add(member.uuid);
                            } else {
                              _selected.remove(member.uuid);
                            }
                          }),
                          secondary: Img(
                            src: memberAvatar(member),
                            alt: member.name,
                            size: 36,
                            borderRadius: BorderRadius.circular(36),
                          ),
                          title: Text(
                            member.name ?? 'User',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    );
                  },
                );
              }),
            ),
            const SizedBox(height: 12),
            AppPrimaryButton(
              label: _selected.isEmpty
                  ? 'Nobody invited'
                  : 'Invite ${_selected.length}',
              icon: Icons.check_rounded,
              onPressed: () => Navigator.of(context).pop(_selected),
            ),
          ],
        ),
      ),
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
