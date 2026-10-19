import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/widgets/loading_widget.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/ongoing_outpost_call_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/utils.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/likePath.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/widgetWithTimer/widgetWrapper.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/providers/api/podium/models/outposts/liveData.dart';
import 'package:podium/services/websocket/incomingMessage.dart';
import 'package:podium/services/websocket/outgoingMessage.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/dateUtils.dart';

Color get callSpeakingColor => ColorName.success;
Color get callDangerColor => ColorName.danger;
Color get callAccentColor => ColorName.warning;

String memberAvatar(LiveMember member) {
  final avatar = member.image ?? '';
  if (avatar.isEmpty || avatar == defaultAvatar) {
    return avatarPlaceHolder(member.name);
  }
  return avatar;
}

String formatTalkTime(int seconds) {
  final [hh, mm, ss] = formatDuration(seconds < 0 ? 0 : seconds);
  return hh == '0' ? '$mm:$ss' : '$hh:$mm:$ss';
}

class ConfettiDetector extends StatefulWidget {
  final String userId;
  const ConfettiDetector({super.key, required this.userId});

  @override
  State<ConfettiDetector> createState() => _ConfettiDetectorState();
}

class _ConfettiDetectorState extends State<ConfettiDetector> {
  /// Each event is a new [Reaction]; remembering the last one keeps unrelated
  /// rebuilds from firing the same confetti again.
  Reaction? _lastShot;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OngoingOutpostCallController>(
      id: 'confetti${widget.userId}',
      builder: (controller) {
        final lastReaction = controller.lastReaction.value;
        if (lastReaction.targetId == widget.userId &&
            !identical(lastReaction, _lastShot)) {
          _lastShot = lastReaction;
          _shootReaction(context: context, reaction: lastReaction);
        }
        return const IgnorePointer(child: SizedBox.expand());
      },
    );
  }
}

({double x, double y}) _origin(BuildContext context) {
  final renderBox = context.findRenderObject() as RenderBox;
  final center = renderBox.localToGlobal(renderBox.size.center(Offset.zero));
  return (x: center.dx / Get.width, y: center.dy / Get.height);
}

void _shootLike(BuildContext context) {
  final origin = _origin(context);
  const colors = [
    Color.fromARGB(255, 255, 0, 0),
    Color.fromARGB(255, 255, 0, 123),
    Color.fromARGB(255, 232, 0, 0),
    Color.fromARGB(255, 255, 108, 172),
    Color.fromARGB(255, 255, 184, 233)
  ];
  final options = ConfettiOptions(
    spread: 30,
    ticks: 70,
    gravity: 0.5,
    decay: 0.97,
    y: origin.y,
    x: origin.x,
    startVelocity: 5,
    colors: colors,
  );
  Confetti.launch(
    context,
    options: options.copyWith(particleCount: 1),
    particleBuilder: (index) => LikePath(),
  );
}

void _shootDisLike(BuildContext context) {
  final origin = _origin(context);
  const colors = [
    Color.fromARGB(255, 255, 0, 0),
    Color.fromARGB(255, 255, 0, 123),
    Color.fromARGB(255, 232, 0, 0),
    Color.fromARGB(255, 255, 108, 172),
    Color.fromARGB(255, 255, 184, 233)
  ];
  final options = ConfettiOptions(
    spread: 30,
    ticks: 40,
    gravity: 0.5,
    decay: 0.97,
    y: origin.y,
    x: origin.x,
    startVelocity: 0,
    colors: colors,
  );
  Confetti.launch(
    context,
    options: options.copyWith(particleCount: 1),
    particleBuilder: (index) => DislikePath(),
  );
}

void _shootCheer(BuildContext context) {
  final origin = _origin(context);
  const colors = [
    Colors.green,
    Colors.red,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
  ];
  final options = ConfettiOptions(
    spread: 30,
    ticks: 120,
    gravity: 0.5,
    decay: 0.97,
    y: origin.y,
    x: origin.x,
    startVelocity: 10,
    colors: colors,
  );
  Confetti.launch(
    context,
    options: options.copyWith(particleCount: 1),
    particleBuilder: (index) => CheerPath(),
  );
  Confetti.launch(
    context,
    options: options.copyWith(particleCount: 50, scalar: 1),
  );
}

void _shootBoo(BuildContext context) {
  final origin = _origin(context);
  const colors = [Colors.red];
  final options = ConfettiOptions(
    spread: 30,
    ticks: 120,
    gravity: 0.4,
    decay: 0.97,
    y: origin.y,
    x: origin.x,
    startVelocity: 0,
    colors: colors,
  );
  Confetti.launch(
    context,
    options: options.copyWith(particleCount: 1),
    particleBuilder: (index) => BooPath(),
  );
  Confetti.launch(
    context,
    options: options.copyWith(particleCount: 50, gravity: 2, startVelocity: 5),
  );
}

void _shootReaction({
  required BuildContext context,
  required Reaction reaction,
}) {
  final shoot = switch (reaction.reaction) {
    IncomingMessageType.userLiked => _shootLike,
    IncomingMessageType.userDisliked => _shootDisLike,
    IncomingMessageType.userCheered => _shootCheer,
    IncomingMessageType.userBooed => _shootBoo,
    _ => null,
  };
  if (shoot == null) return;
  Timer(Duration.zero, () {
    if (context.mounted) shoot(context);
  });
}

class ReactionCounts extends GetView<OutpostCallController> {
  final String address;
  final bool showEmpty;
  const ReactionCounts({
    super.key,
    required this.address,
    this.showEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final reactions = controller.reactionsMap.value[address] ?? const {};
      final items = [
        (
          Icons.thumb_up_rounded,
          OutgoingMessageTypeEnums.like,
          ColorName.success
        ),
        (
          Icons.thumb_down_rounded,
          OutgoingMessageTypeEnums.dislike,
          ColorName.danger
        ),
        (Icons.celebration, OutgoingMessageTypeEnums.cheer, ColorName.success),
        (
          Icons.sentiment_very_dissatisfied,
          OutgoingMessageTypeEnums.boo,
          ColorName.danger
        ),
      ];
      return Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final (icon, type, color) in items)
            if (showEmpty || (reactions[type] ?? 0) > 0)
              _ReactionChip(
                icon: icon,
                count: reactions[type] ?? 0,
                color: color,
              ),
        ],
      );
    });
  }
}

class _ReactionChip extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;
  const _ReactionChip({
    required this.icon,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Labeled square action used in the member sheet and the intro demo card.
class CallActionButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  const CallActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(28),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPressed!();
              },
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withAlpha(70)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 26, child: Center(child: icon)),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LikeDislikeButton extends GetView<OngoingOutpostCallController> {
  final bool isLike;
  final String userId;
  const LikeDislikeButton({
    super.key,
    required this.userId,
    required this.isLike,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLike ? ColorName.success : ColorName.danger;
    final label = isLike
        ? 'Like +${amountToAddForLikeInSeconds}s'
        : 'Dislike −${amountToReduceForDislikeInSeconds}s';
    return Obx(() {
      final timers = controller.timers.value;
      final key = generateKeyForStorageAndObserver(
        userId: userId,
        groupId: controller.outpostCallController.outpost.value!.uuid,
        like: isLike,
      );
      final finishAt = timers[key];
      final coolingDown = finishAt != null;
      return CallActionButton(
        color: coolingDown ? ColorName.greyText : color,
        label: label,
        onPressed: coolingDown
            ? null
            : () {
                isLike
                    ? controller.onLikeClicked(userId: userId)
                    : controller.onDislikeClicked(userId: userId);
              },
        icon: WidgetWithTimer(
          finishAt: finishAt,
          onComplete: () {
            if (controller.timers.value[key] == null) return;
            controller.timers.update((val) {
              val!.remove(key);
              return val;
            });
            // ignore: invalid_use_of_protected_member
            controller.timers.refresh();
          },
          child: Icon(
            isLike ? Icons.thumb_up_rounded : Icons.thumb_down_rounded,
            color: color,
            size: 22,
          ),
        ),
      );
    });
  }
}

class CheerBooButton extends GetView<OngoingOutpostCallController> {
  final bool cheer;
  final String userId;
  const CheerBooButton({super.key, required this.cheer, required this.userId});

  @override
  Widget build(BuildContext context) {
    final color = cheer ? ColorName.success : ColorName.danger;
    return Obx(() {
      if (!Get.isRegistered<OngoingOutpostCallController>()) {
        return const SizedBox();
      }
      final loading = controller.loadingWalletAddressForUser
          .contains("$userId-${cheer ? 'cheer' : 'boo'}");
      return CallActionButton(
        color: color,
        label: cheer ? 'Cheer' : 'Boo',
        onPressed: loading
            ? null
            : () {
                controller.cheerBoo(targetUserUuid: userId, cheer: cheer);
              },
        icon: loading
            ? const SizedBox(width: 20, height: 20, child: LoadingWidget())
            : (cheer ? Assets.images.cheer : Assets.images.boo).image(
                width: 24,
                height: 24,
                color: color,
              ),
      );
    });
  }
}
