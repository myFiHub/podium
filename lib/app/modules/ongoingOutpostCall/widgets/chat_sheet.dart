import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/call_room_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/call_sheet.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/member_interactions.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/member_sheet.dart';
import 'package:podium/utils/palette.dart';

Future<void> openChatSheet() async {
  final room = findCallRoom();
  if (room == null) return;
  room.setChatOpen(true);
  await Get.bottomSheet(
    const ChatSheet(),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
  findCallRoom()?.setChatOpen(false);
}

class ChatSheet extends StatefulWidget {
  const ChatSheet({super.key});

  @override
  State<ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<ChatSheet> {
  final room = Get.find<CallRoomController>();
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
    return SizedBox(
      height: CallSheet.maxHeight(context, 0.75),
      child: CallSheet(
        title: 'Chat',
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                final messages = room.chat.reversed.toList();
                if (messages.isEmpty) return const _EmptyChat();
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final older = index + 1 < messages.length
                        ? messages[index + 1]
                        : null;
                    final grouped = older != null &&
                        older.senderUuid == message.senderUuid &&
                        older.senderName == message.senderName &&
                        message.at.difference(older.at).inMinutes < 2;
                    return _ChatBubble(
                      key: ValueKey(message.id),
                      message: message,
                      showSender: !grouped,
                    );
                  },
                );
              }),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: ColorName.cardBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: input,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 1000,
                      keyboardAppearance: Brightness.dark,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        isDense: true,
                        counterText: '',
                        hintText: 'Say something to the room',
                        filled: true,
                        fillColor: ColorName.white.withAlpha(10),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  ValueListenableBuilder(
                    valueListenable: input,
                    builder: (context, value, _) => IconButton(
                      tooltip: 'Send',
                      onPressed: value.text.trim().isEmpty ? null : _send,
                      icon: const Icon(Icons.send_rounded),
                      color: ColorName.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

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
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 40,
                        color: ColorName.greyText,
                      ),
                      const SizedBox(height: 12),
                    ],
                    const Text(
                      'No messages yet',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Messages are visible to everyone in this outpost and disappear when it ends.',
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
    final member = Get.find<OutpostCallController>()
        .members
        .value
        .firstOrNullWhere((m) => m.uuid == uuid);
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

class _ChatBubble extends StatelessWidget {
  final CallChatMessage message;
  final bool showSender;
  const _ChatBubble({
    super.key,
    required this.message,
    required this.showSender,
  });

  @override
  Widget build(BuildContext context) {
    final mine = message.mine;
    final time = TimeOfDay.fromDateTime(message.at).format(context);
    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.7,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: mine
            ? ColorName.primaryBlue.withAlpha(mine && message.pending ? 25 : 45)
            : ColorName.white.withAlpha(14),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(mine ? 16 : 4),
          bottomRight: Radius.circular(mine ? 4 : 16),
        ),
      ),
      child: Text(message.text, style: const TextStyle(fontSize: 14)),
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
                  ? ChatAvatar(
                      uuid: message.senderUuid, name: message.senderName)
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
                    mine ? time : '${message.senderName} · $time',
                    style: TextStyle(
                      fontSize: 12,
                      color: ColorName.greyText,
                    ),
                  ),
                ),
              bubble,
            ],
          ),
        ],
      ),
    );
  }
}
