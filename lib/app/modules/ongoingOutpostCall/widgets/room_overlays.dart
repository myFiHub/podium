import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/call_room_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/chat_sheet.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/member_interactions.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/participants_sheet.dart';
import 'package:podium/gen/colors.gen.dart';

/// Overlays drawn above the member grid: floating reactions, the reaction
/// tray and the incoming chat preview.
class RoomOverlays extends StatelessWidget {
  const RoomOverlays({super.key});

  @override
  Widget build(BuildContext context) {
    final room = findCallRoom();
    if (room == null) return const SizedBox.shrink();
    return const Stack(
      children: [
        Positioned.fill(child: IgnorePointer(child: _FloatingReactions())),
        Positioned(left: 12, right: 12, bottom: 8, child: _BottomStack()),
      ],
    );
  }
}

class _BottomStack extends GetView<CallRoomController> {
  const _BottomStack();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final preview = controller.chatPreview.value;
      final trayOpen = controller.reactionTrayOpen.value;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: _slideFade,
            child: preview == null
                ? const SizedBox.shrink()
                : _ChatPreview(key: ValueKey(preview.id), message: preview),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: _slideFade,
            child: trayOpen ? const ReactionTray() : const SizedBox.shrink(),
          ),
        ],
      );
    });
  }
}

Widget _slideFade(Widget child, Animation<double> animation) {
  return FadeTransition(
    opacity: animation,
    child: SlideTransition(
      position: Tween(begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(animation),
      child: child,
    ),
  );
}

class ReactionTray extends GetView<CallRoomController> {
  const ReactionTray({super.key});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: ColorName.navbarBackground,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: ColorName.cardBorder),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 16),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final emoji in CallRoomController.reactionEmojis)
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => controller.sendReaction(emoji),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChatPreview extends StatelessWidget {
  final CallChatMessage message;
  const _ChatPreview({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: openChatSheet,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
          decoration: BoxDecoration(
            color: ColorName.navbarBackground,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: ColorName.cardBorder),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 12),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChatAvatar(
                uuid: message.senderUuid,
                name: message.senderName,
                size: 28,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${message.senderName}  ',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: ColorName.primaryBlue,
                        ),
                      ),
                      TextSpan(text: message.text),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingReactions extends GetView<CallRoomController> {
  const _FloatingReactions();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Obx(() {
        final reactions = controller.reactions.toList();
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final reaction in reactions)
              _FloatingEmoji(
                key: ValueKey(reaction.id),
                reaction: reaction,
                height: constraints.maxHeight,
              ),
          ],
        );
      }),
    );
  }
}

class _FloatingEmoji extends StatelessWidget {
  final FloatingReaction reaction;
  final double height;
  const _FloatingEmoji({
    super.key,
    required this.reaction,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 2600),
      curve: Curves.easeOut,
      builder: (context, t, child) {
        final opacity = t < 0.1 ? t * 10 : (t > 0.7 ? (1 - t) / 0.3 : 1.0);
        return Positioned(
          right: 20 + reaction.lane * 90 + sin(t * pi * 3) * 12,
          bottom: 70 + t * height * 0.55,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child:
                Transform.scale(scale: 0.6 + min(t * 4, 1) * 0.5, child: child),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(reaction.emoji, style: const TextStyle(fontSize: 34)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              reaction.senderName,
              maxLines: 1,
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Host-only strip listing raised hands in the order they were raised.
class RaisedHandsBanner extends StatelessWidget {
  const RaisedHandsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final room = findCallRoom();
    if (room == null) return const SizedBox.shrink();
    return Obx(() {
      final hands = room.raisedHandUuids;
      if (!room.amIHost || hands.isEmpty) return const SizedBox.shrink();
      final names = hands
          .take(2)
          .map((uuid) => room.displayNameOf(uuid: uuid))
          .join(', ');
      final more = hands.length > 2 ? ' +${hands.length - 2}' : '';
      return GestureDetector(
        onTap: () => openParticipantsSheet(showHands: true),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: callAccentColor.withAlpha(24),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: callAccentColor.withAlpha(90)),
          ),
          child: Row(
            children: [
              const Text('✋', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hands.length == 1
                          ? '1 raised hand'
                          : '${hands.length} raised hands',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: callAccentColor,
                      ),
                    ),
                    Text(
                      '$names$more',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ColorName.greyText,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Review',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: callAccentColor,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: callAccentColor,
                size: 18,
              ),
            ],
          ),
        ),
      );
    });
  }
}
