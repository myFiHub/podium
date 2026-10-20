import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/services/blocked_users_service.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/call_room_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/call_sheet.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/member_interactions.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/member_sheet.dart';
import 'package:podium/providers/api/podium/models/outposts/liveData.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/ui/app_ui.dart';

/// Opens the chat, on the private conversation with [privateWith] if given.
Future<void> openChatSheet({String? privateWith}) async {
  final room = findCallRoom();
  if (room == null) return;
  room.setChatOpen(true);
  await Get.bottomSheet(
    ChatSheet(privateWith: privateWith),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
  findCallRoom()?.setChatOpen(false);
}

/// Present members other than me, by name.
List<LiveMember> _presentOthers() => Get.find<OutpostCallController>()
    .members
    .value
    .where((m) => m.is_present && m.uuid != myId)
    .sortedBy((m) => (m.name ?? '').toLowerCase())
    .toList();

LiveMember? _memberOf(String? uuid) => uuid == null
    ? null
    : Get.find<OutpostCallController>()
        .members
        .value
        .firstOrNullWhere((m) => m.uuid == uuid);

enum _ChatTab { room, private }

class ChatSheet extends StatefulWidget {
  final String? privateWith;
  const ChatSheet({super.key, this.privateWith});

  @override
  State<ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<ChatSheet> {
  final room = Get.find<CallRoomController>();
  late var _tab = widget.privateWith == null ? _ChatTab.room : _ChatTab.private;

  /// The open private conversation, or null for the list.
  String? _thread;

  /// Picking someone to start a conversation with.
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    if (widget.privateWith != null) _openThread(widget.privateWith!);
  }

  @override
  void dispose() {
    room.setOpenPrivateThread(null);
    super.dispose();
  }

  void _openThread(String uuid) {
    _thread = uuid;
    _picking = false;
    room.setOpenPrivateThread(uuid);
  }

  void _showTab(_ChatTab tab) {
    setState(() {
      _tab = tab;
      if (tab == _ChatTab.room) {
        room.setOpenPrivateThread(null);
      } else if (_thread != null) {
        room.setOpenPrivateThread(_thread);
      }
    });
  }

  void _back() {
    setState(() {
      _thread = null;
      _picking = false;
      room.setOpenPrivateThread(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final inThread = _tab == _ChatTab.private && _thread != null;
    return SizedBox(
      height: CallSheet.maxHeight(context, 0.75),
      child: CallSheet(
        title: 'Chat',
        subtitle: _tab == _ChatTab.room
            ? 'Visible to everyone in this room'
            : 'Only you and the person you message can see these',
        icon: _tab == _ChatTab.room
            ? Icons.chat_bubble_rounded
            : Icons.lock_rounded,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Obx(() {
                final unread = room.unreadPrivate.value;
                return AppSegmented<_ChatTab>(
                  value: _tab,
                  onChanged: _showTab,
                  segments: [
                    (_ChatTab.room, 'Room', Icons.forum_outlined),
                    (
                      _ChatTab.private,
                      unread == 0 || inThread
                          ? 'Private'
                          : 'Private · $unread',
                      Icons.lock_outline_rounded,
                    ),
                  ],
                );
              }),
            ),
            Expanded(
              child: switch (_tab) {
                _ChatTab.room => const _RoomChat(),
                _ChatTab.private when _thread != null => _PrivateThreadView(
                    key: ValueKey(_thread),
                    peerUuid: _thread!,
                    onBack: _back,
                  ),
                _ChatTab.private when _picking => _MemberPicker(
                    onPick: (uuid) => setState(() => _openThread(uuid)),
                    onBack: _back,
                  ),
                _ChatTab.private => _Conversations(
                    onOpen: (uuid) => setState(() => _openThread(uuid)),
                    onNew: () => setState(() => _picking = true),
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Room chat -------------------------------------------------------------------

class _RoomChat extends StatefulWidget {
  const _RoomChat();

  @override
  State<_RoomChat> createState() => _RoomChatState();
}

class _RoomChatState extends State<_RoomChat> {
  final room = Get.find<CallRoomController>();
  final blocks = Get.find<BlockedUsersService>();
  final input = TextEditingController();

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  void _send() {
    room.sendChat(input.text);
    input.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Obx(() {
            blocks.blocked.length;
            final messages = room.chat
                .where((m) => m.mine || !blocks.isBlocked(m.senderUuid))
                .toList()
                .reversed
                .toList();
            if (messages.isEmpty) {
              return const _EmptyChat(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'No messages yet',
                message: 'Messages are visible to everyone in this room and '
                    'disappear when the outpost ends.',
              );
            }
            return ListView.builder(
              reverse: true,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final older =
                    index + 1 < messages.length ? messages[index + 1] : null;
                if (message.system) {
                  return _SystemNotice(
                    key: ValueKey(message.id),
                    text: message.text,
                  );
                }
                final grouped = older != null &&
                    !older.system &&
                    older.senderUuid == message.senderUuid &&
                    older.senderName == message.senderName &&
                    message.at.difference(older.at).inMinutes < 2;
                return _ChatBubble(
                  key: ValueKey(message.id),
                  text: message.text,
                  at: message.at,
                  mine: message.mine,
                  faded: message.mine && message.pending,
                  senderUuid: message.senderUuid,
                  senderName: message.senderName,
                  showSender: !grouped,
                );
              },
            );
          }),
        ),
        _Composer(
          controller: input,
          hint: 'Say something to the room',
          maxLength: 1000,
          onSend: _send,
        ),
      ],
    );
  }
}

// Private conversations -------------------------------------------------------

class _Conversations extends GetView<CallRoomController> {
  final ValueChanged<String> onOpen;
  final VoidCallback onNew;
  const _Conversations({required this.onOpen, required this.onNew});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final threads = controller.sortedThreads
          .where((t) => t.messages.isNotEmpty)
          .toList();
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: AppSecondaryButton(
              label: 'New message',
              icon: Icons.edit_rounded,
              onPressed: onNew,
            ),
          ),
          Expanded(
            child: threads.isEmpty
                ? const _EmptyChat(
                    icon: Icons.lock_outline_rounded,
                    title: 'No private messages',
                    message: 'Message anyone in this outpost, even in another '
                        'room. Conversations disappear when you leave.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: threads.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final thread = threads[index];
                      return _ConversationTile(
                        key: ValueKey(thread.peerUuid),
                        thread: thread,
                        onTap: () => onOpen(thread.peerUuid),
                      );
                    },
                  ),
          ),
        ],
      );
    });
  }
}

class _ConversationTile extends StatelessWidget {
  final PrivateThread thread;
  final VoidCallback onTap;
  const _ConversationTile({
    super.key,
    required this.thread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final last = thread.last;
    final unread = thread.unread;
    final member = _memberOf(thread.peerUuid);
    final name = member?.name ?? thread.peerName;
    final preview = last == null
        ? ''
        : last.mine
            ? 'You: ${last.text}'
            : last.text;
    return AppCard(
      padding: EdgeInsets.zero,
      radius: AppRadius.md,
      color: unread > 0
          ? AppColors.primary.withAlpha(14)
          : ColorName.white.withAlpha(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ChatAvatar(uuid: thread.peerUuid, name: name, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.cardTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member?.is_present == false
                          ? 'Left the outpost'
                          : last?.status == PrivateMessageStatus.failed
                              ? 'Not delivered'
                              : preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(
                        color: unread > 0 ? ColorName.white : null,
                        fontWeight: unread > 0 ? FontWeight.w600 : null,
                      ),
                    ),
                  ],
                ),
              ),
              if (last != null) ...[
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      TimeOfDay.fromDateTime(last.at).format(context),
                      style: AppText.caption,
                    ),
                    if (unread > 0) ...[
                      const SizedBox(height: 4),
                      AppPill(
                        label: '$unread',
                        color: AppColors.primary,
                        filled: true,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberPicker extends StatefulWidget {
  final ValueChanged<String> onPick;
  final VoidCallback onBack;
  const _MemberPicker({required this.onPick, required this.onBack});

  @override
  State<_MemberPicker> createState() => _MemberPickerState();
}

class _MemberPickerState extends State<_MemberPicker> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blocks = Get.find<BlockedUsersService>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 12, 8),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Expanded(
                child: TextField(
                  controller: _query,
                  autofocus: true,
                  keyboardAppearance: Brightness.dark,
                  decoration: const InputDecoration(
                    hintText: 'Search people in this outpost',
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            blocks.blocked.length;
            Get.find<OutpostCallController>().members.value;
            return ValueListenableBuilder(
              valueListenable: _query,
              builder: (context, value, _) {
                final query = value.text.trim().toLowerCase();
                final people = _presentOthers()
                    .where((m) =>
                        query.isEmpty ||
                        (m.name ?? '').toLowerCase().contains(query))
                    .toList();
                if (people.isEmpty) {
                  return _EmptyChat(
                    icon: Icons.person_search_rounded,
                    title: query.isEmpty
                        ? "You're the only one here"
                        : 'Nobody found',
                    message: query.isEmpty
                        ? 'People show up here once they join the outpost.'
                        : 'Only people in this outpost can be messaged.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: people.length,
                  itemBuilder: (context, index) {
                    final member = people[index];
                    final blocked = blocks.isBlocked(member.uuid);
                    return ListTile(
                      key: ValueKey(member.uuid),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: Img(
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
                      subtitle: blocked
                          ? Text('Blocked', style: AppText.caption)
                          : null,
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: ColorName.greyText,
                      ),
                      onTap: () => widget.onPick(member.uuid),
                    );
                  },
                );
              },
            );
          }),
        ),
      ],
    );
  }
}

class _PrivateThreadView extends StatefulWidget {
  final String peerUuid;
  final VoidCallback onBack;
  const _PrivateThreadView({
    super.key,
    required this.peerUuid,
    required this.onBack,
  });

  @override
  State<_PrivateThreadView> createState() => _PrivateThreadViewState();
}

class _PrivateThreadViewState extends State<_PrivateThreadView> {
  final room = Get.find<CallRoomController>();
  final blocks = Get.find<BlockedUsersService>();
  final input = TextEditingController();

  String get _peer => widget.peerUuid;

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  void _send() {
    final error = room.sendPrivateMessage(_peer, input.text);
    if (error != null) {
      Toast.warning(title: 'Not sent', message: error);
      return;
    }
    input.clear();
  }

  Future<void> _toggleBlock(String name) async {
    if (blocks.isBlocked(_peer)) {
      await blocks.unblock(_peer);
      return;
    }
    if (await confirmBlockUser(name)) await room.blockUser(_peer);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final thread = room.privateThreads[_peer];
      final member = _memberOf(_peer);
      final name = member?.name ??
          thread?.peerName ??
          room.displayNameOf(uuid: _peer);
      final blocked = blocks.isBlocked(_peer);
      final present = member?.is_present ?? false;
      final messages = (thread?.messages ?? const <PrivateMessage>[])
          .reversed
          .toList();
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                ChatAvatar(uuid: _peer, name: name, size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.cardTitle,
                      ),
                      Text(
                        blocked
                            ? 'Blocked'
                            : present
                                ? 'In this outpost'
                                : 'Left the outpost',
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Options',
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: ColorName.greyText,
                  ),
                  onSelected: (action) {
                    if (action == 'profile') openMemberSheet(_peer);
                    if (action == 'block') _toggleBlock(name);
                  },
                  itemBuilder: (_) => [
                    if (member != null)
                      const PopupMenuItem(
                        value: 'profile',
                        child: Text('View in outpost'),
                      ),
                    PopupMenuItem(
                      value: 'block',
                      child: Text(
                        blocked ? 'Unblock' : 'Block',
                        style: TextStyle(
                          color: blocked ? null : AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: messages.isEmpty
                ? _EmptyChat(
                    icon: Icons.lock_outline_rounded,
                    title: 'Say hi to $name',
                    message: 'Only the two of you see this conversation. It '
                        'disappears when you leave the outpost.',
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final older = index + 1 < messages.length
                          ? messages[index + 1]
                          : null;
                      final grouped = older != null &&
                          older.mine == message.mine &&
                          message.at.difference(older.at).inMinutes < 2;
                      final failed =
                          message.status == PrivateMessageStatus.failed;
                      return GestureDetector(
                        key: ValueKey(message.clientId),
                        onTap: failed
                            ? () => room.retryPrivateMessage(message)
                            : null,
                        child: _ChatBubble(
                          text: message.text,
                          at: message.at,
                          mine: message.mine,
                          faded: message.status != PrivateMessageStatus.sent,
                          senderUuid: message.mine ? myId : _peer,
                          senderName: message.mine ? 'You' : name,
                          showSender: !grouped,
                          error: failed ? message.error : null,
                        ),
                      );
                    },
                  ),
          ),
          if (blocked)
            _ComposerNotice(
              text: "You blocked $name. They can't message you.",
              actionLabel: 'Unblock',
              onAction: () => blocks.unblock(_peer),
            )
          else if (!present)
            _ComposerNotice(text: '$name is not in this outpost anymore')
          else
            _Composer(
              controller: input,
              hint: 'Message $name privately',
              maxLength: 1000,
              onSend: _send,
            ),
        ],
      );
    });
  }
}

/// Asks before blocking [name]. Resolves to true when confirmed.
Future<bool> confirmBlockUser(String name) => showAppConfirm(
      title: 'Block $name?',
      message: "They won't be able to message you privately, and you won't "
          'see their messages in room chat. You can unblock them anytime.',
      confirmLabel: 'Block',
      destructive: true,
    );

// Shared pieces ---------------------------------------------------------------

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLength;
  final VoidCallback onSend;
  const _Composer({
    required this.controller,
    required this.hint,
    required this.maxLength,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(24),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              maxLength: maxLength,
              keyboardAppearance: Brightness.dark,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                counterText: '',
                hintText: hint,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(
                    color: AppColors.primary.withAlpha(150),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, value, _) {
              final canSend = value.text.trim().isNotEmpty;
              return AnimatedScale(
                scale: canSend ? 1 : 0.9,
                duration: const Duration(milliseconds: 160),
                child: AppGradientShell(
                  enabled: canSend,
                  borderRadius: BorderRadius.circular(22),
                  child: IconButton(
                    tooltip: 'Send',
                    onPressed: canSend ? onSend : null,
                    icon: const Icon(Icons.arrow_upward_rounded),
                    style: IconButton.styleFrom(
                      fixedSize: const Size.square(44),
                      backgroundColor: Colors.transparent,
                      foregroundColor: AppColors.onPrimary,
                      disabledBackgroundColor: AppColors.fill,
                      disabledForegroundColor: ColorName.greyText,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ComposerNotice extends StatelessWidget {
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _ComposerNotice({required this.text, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      constraints: const BoxConstraints(minHeight: 64),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(24),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(text, style: AppText.muted)),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _EmptyChat({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 180;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!compact) ...[
                      Icon(icon, size: 40, color: ColorName.greyText),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: ColorName.greyText),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ChatAvatar extends StatelessWidget {
  final String? uuid;
  final String name;
  final double size;
  const ChatAvatar({
    super.key,
    required this.uuid,
    required this.name,
    this.size = 30,
  });

  @override
  Widget build(BuildContext context) {
    final member = _memberOf(uuid);
    return GestureDetector(
      onTap: uuid == null ? null : () => openMemberSheet(uuid!),
      child: Img(
        src: member == null ? '' : memberAvatar(member),
        alt: member?.name ?? name,
        size: size,
        borderRadius: BorderRadius.circular(size),
      ),
    );
  }
}

class _SystemNotice extends StatelessWidget {
  final String text;
  const _SystemNotice({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: ColorName.white.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: ColorName.greyText),
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final DateTime at;
  final bool mine;

  /// Not confirmed yet.
  final bool faded;
  final String? senderUuid;
  final String senderName;
  final bool showSender;

  /// Shown under the bubble when sending failed.
  final String? error;
  const _ChatBubble({
    super.key,
    required this.text,
    required this.at,
    required this.mine,
    required this.faded,
    required this.senderUuid,
    required this.senderName,
    required this.showSender,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(at).format(context);
    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.7,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: mine
            ? ColorName.primaryBlue.withAlpha(faded ? 25 : 45)
            : ColorName.white.withAlpha(14),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(mine ? 16 : 4),
          bottomRight: Radius.circular(mine ? 4 : 16),
        ),
        border: error == null
            ? null
            : Border.all(color: AppColors.danger.withAlpha(120)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
    return Padding(
      padding: EdgeInsets.only(top: showSender ? 10 : 2),
      child: Row(
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!mine)
            SizedBox(
              width: 38,
              child: showSender
                  ? ChatAvatar(uuid: senderUuid, name: senderName)
                  : null,
            ),
          Column(
            crossAxisAlignment:
                mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (showSender)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3, left: 4, right: 4),
                  child: Text(
                    mine ? time : '$senderName · $time',
                    style: TextStyle(
                      fontSize: 12,
                      color: ColorName.greyText,
                    ),
                  ),
                ),
              bubble,
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 13,
                        color: AppColors.danger,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        error!,
                        style: TextStyle(fontSize: 11, color: AppColors.danger),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
