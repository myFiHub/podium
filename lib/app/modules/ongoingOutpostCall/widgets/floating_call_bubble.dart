import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/lib/jitsiMeet.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/widgets/img.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/call_room_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/ongoing_outpost_call_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/chat_sheet.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/control_dock.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/member_interactions.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/voice_level.dart';
import 'package:podium/utils/navigation/call_route_tracker.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/navbar.dart';
import 'package:podium/widgets/ui/app_ui.dart';

const _bubbleSize = 60.0;
const _edgeMargin = 12.0;
const _fanRadius = 104.0;
const _actionSize = 46.0;

/// Floating handle for a minimized outpost call. It sits above every page
/// (it's mounted in [Root], outside the Navigator), so it can't use Tooltips
/// or anything else that needs an Overlay.
class FloatingCallBubble extends StatefulWidget {
  const FloatingCallBubble({super.key});

  @override
  State<FloatingCallBubble> createState() => _FloatingCallBubbleState();
}

class _FloatingCallBubbleState extends State<FloatingCallBubble>
    with SingleTickerProviderStateMixin {
  /// Kept across rebuilds and calls so the bubble returns where it was left.
  static Offset? _savedTopLeft;

  late final AnimationController _fan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    reverseDuration: const Duration(milliseconds: 200),
  );
  bool _dragging = false;
  Offset? _topLeft;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CallRouteTracker.instance.attach();
    });
  }

  @override
  void dispose() {
    _fan.dispose();
    super.dispose();
  }

  bool get _expanded =>
      _fan.status == AnimationStatus.forward ||
      _fan.status == AnimationStatus.completed;

  void _toggle() {
    HapticFeedback.selectionClick();
    if (_expanded) {
      _fan.reverse();
    } else {
      _fan.forward();
    }
    setState(() {});
  }

  void _collapse() {
    if (!_expanded) return;
    _fan.reverse();
    setState(() {});
  }

  Rect _bounds(Size size, EdgeInsets viewInsets) {
    final bottomInset =
        viewInsets.bottom > 0 ? viewInsets.bottom : navbarHeight;
    return Rect.fromLTRB(
      _edgeMargin,
      _edgeMargin,
      math.max(_edgeMargin, size.width - _bubbleSize - _edgeMargin),
      math.max(
        _edgeMargin,
        size.height - bottomInset - _bubbleSize - _edgeMargin,
      ),
    );
  }

  Offset _clamp(Offset p, Rect b) => Offset(
        p.dx.clamp(b.left, b.right),
        p.dy.clamp(b.top, b.bottom),
      );

  Offset _snap(Offset p, Rect b) {
    final x = (p.dx + _bubbleSize / 2) < (b.left + b.right + _bubbleSize) / 2
        ? b.left
        : b.right;
    return _clamp(Offset(x, p.dy), b);
  }

  @override
  Widget build(BuildContext context) {
    final global = Get.find<GlobalController>();
    final call = Get.find<OutpostCallController>();
    final tracker = CallRouteTracker.instance;
    return Obx(() {
      final visible = global.loggedIn.value &&
          call.isInCall.value &&
          call.outpost.value != null &&
          !tracker.isCallPageVisible.value &&
          tracker.openPopups.value == 0 &&
          Get.isRegistered<OngoingOutpostCallController>();
      if (!visible) {
        if (_fan.value != 0) _fan.value = 0;
        return const SizedBox.shrink();
      }
      return Positioned.fill(
        child: Material(
          type: MaterialType.transparency,
          child: LayoutBuilder(
            builder: (context, constraints) =>
                _buildLayer(context, constraints.biggest),
          ),
        ),
      );
    });
  }

  Widget _buildLayer(BuildContext context, Size size) {
    final bounds = _bounds(size, MediaQuery.viewInsetsOf(context));
    final resting = _clamp(
      _topLeft ?? _savedTopLeft ?? Offset(bounds.right, bounds.bottom - 96),
      bounds,
    );
    final onRight = resting.dx + _bubbleSize / 2 > size.width / 2;
    // Leave room for the fan above and below the bubble while it's open.
    const fanReach = _fanRadius + _actionSize / 2 + 18;
    final open = _expanded;
    final topLeft = open
        ? Offset(
            resting.dx,
            resting.dy.clamp(
              math.min(bounds.top + fanReach - _bubbleSize / 2, bounds.bottom),
              math.max(
                bounds.top,
                bounds.bottom - fanReach + _bubbleSize / 2,
              ),
            ),
          )
        : resting;
    final center = topLeft + const Offset(_bubbleSize / 2, _bubbleSize / 2);

    return Stack(
      children: [
        if (open)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _collapse,
              child: FadeTransition(
                opacity: _fan,
                child: ColoredBox(color: Colors.black.withAlpha(110)),
              ),
            ),
          ),
        Positioned.fill(
          child: Obx(() {
            if (!Get.isRegistered<OngoingOutpostCallController>()) {
              return const SizedBox.shrink();
            }
            final room = findCallRoom();
            final actions = _actions(
              canTalk: Get.find<OutpostCallController>().canTalk.value,
              room: room,
              hasHands: room?.channelAvailable.value ?? false,
            );
            return Stack(
              children: [
                for (var i = 0; i < actions.length; i++)
                  _FanItem(
                    animation: _fan,
                    index: i,
                    count: actions.length,
                    center: center,
                    towardsLeft: onRight,
                    action: actions[i],
                  ),
              ],
            );
          }),
        ),
        AnimatedPositioned(
          duration:
              _dragging ? Duration.zero : const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          left: topLeft.dx,
          top: topLeft.dy,
          child: GestureDetector(
            onTap: _toggle,
            onPanStart: open
                ? null
                : (_) => setState(() {
                      _dragging = true;
                      _topLeft = resting;
                    }),
            onPanUpdate: open
                ? null
                : (d) => setState(() {
                      _topLeft = _clamp((_topLeft ?? resting) + d.delta,
                          bounds.inflate(_edgeMargin));
                    }),
            onPanEnd: open
                ? null
                : (_) => setState(() {
                      _dragging = false;
                      _topLeft = _snap(_topLeft ?? resting, bounds);
                      _savedTopLeft = _topLeft;
                    }),
            child: _BubbleFace(expanded: open, animation: _fan),
          ),
        ),
      ],
    );
  }

  /// Built inside the fan's Obx, so every observable read here rebuilds the
  /// fan; the buttons themselves hold plain values and no Obx.
  List<_BubbleAction> _actions({
    required bool canTalk,
    required CallRoomController? room,
    required bool hasHands,
  }) {
    final ongoing = Get.find<OngoingOutpostCallController>();
    final call = ongoing.outpostCallController;
    final muted = ongoing.amIMuted.value;
    final usable = ongoing.canUseMic;
    final raised = room?.myHandRaised ?? false;
    final unread = room?.unreadTotal ?? 0;
    return [
      if (canTalk)
        _BubbleAction(
          look: _ActionLook(
            icon: muted || !usable ? Icons.mic_off_rounded : Icons.mic_rounded,
            label: muted || !usable ? 'Unmute' : 'Mute',
            color: !muted && usable ? callSpeakingColor : ColorName.white,
            dimmed: !usable && muted,
          ),
          onTap: ongoing.toggleMyMic,
        ),
      if (room != null && hasHands)
        _BubbleAction(
          look: _ActionLook(
            icon: raised ? Icons.back_hand_rounded : Icons.back_hand_outlined,
            label: raised ? 'Lower' : 'Raise',
            color: raised ? callAccentColor : ColorName.white,
          ),
          onTap: room.toggleHand,
        ),
      if (room != null)
        _BubbleAction(
          look: _ActionLook(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Chat',
            color: ColorName.white,
            badge: unread == 0
                ? null
                : unread > 99
                    ? '99+'
                    : '$unread',
          ),
          onTap: () {
            _collapse();
            openChatSheet();
          },
        ),
      _BubbleAction(
        look: _ActionLook(
          icon: Icons.open_in_full_rounded,
          label: 'Open',
          color: ColorName.primaryBlue,
        ),
        onTap: () {
          _collapse();
          openCallPage();
        },
      ),
      _BubbleAction(
        look: _ActionLook(
          icon: Icons.call_end_rounded,
          label: 'Leave',
          color: callDangerColor,
        ),
        onTap: () {
          _collapse();
          confirmLeave(call);
        },
      ),
    ];
  }
}

class _BubbleAction {
  final _ActionLook look;
  final VoidCallback onTap;
  const _BubbleAction({required this.look, required this.onTap});
}

class _ActionLook {
  final IconData icon;
  final String label;
  final Color color;
  final bool dimmed;
  final String? badge;
  const _ActionLook({
    required this.icon,
    required this.label,
    required this.color,
    this.dimmed = false,
    this.badge,
  });
}

/// One action on the arc that opens beside the bubble, facing the screen
/// center. Items fly out from the bubble one after another.
class _FanItem extends StatefulWidget {
  final Animation<double> animation;
  final int index;
  final int count;
  final Offset center;
  final bool towardsLeft;
  final _BubbleAction action;
  const _FanItem({
    required this.animation,
    required this.index,
    required this.count,
    required this.center,
    required this.towardsLeft,
    required this.action,
  });

  @override
  State<_FanItem> createState() => _FanItemState();
}

class _FanItemState extends State<_FanItem> {
  static const _spread = 150 * math.pi / 180;

  /// Listens to the shared fan controller, so it must be disposed rather
  /// than recreated on every build.
  late CurvedAnimation _curved = _createCurve();

  CurvedAnimation _createCurve() {
    final start = (widget.index / widget.count) * 0.45;
    return CurvedAnimation(
      parent: widget.animation,
      curve:
          Interval(start, math.min(1, start + 0.55), curve: Curves.easeOutBack),
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void didUpdateWidget(_FanItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation ||
        oldWidget.index != widget.index ||
        oldWidget.count != widget.count) {
      _curved.dispose();
      _curved = _createCurve();
    }
  }

  @override
  void dispose() {
    _curved.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.count;
    final t = count == 1 ? 0.5 : widget.index / (count - 1);
    // From top to bottom along the arc.
    final angle = -_spread / 2 + _spread * t;
    final direction = Offset(
      (widget.towardsLeft ? -1 : 1) * math.cos(angle),
      math.sin(angle),
    );
    final center = widget.center;
    final animation = widget.animation;
    return AnimatedBuilder(
      animation: _curved,
      builder: (context, child) {
        final v = _curved.value;
        if (animation.value == 0) return const SizedBox.shrink();
        final pos = center + direction * (_fanRadius * v);
        return Positioned(
          left: pos.dx - _actionSize / 2 - 14,
          top: pos.dy - _actionSize / 2,
          width: _actionSize + 28,
          child: Opacity(
            opacity: v.clamp(0.0, 1.0),
            child: Transform.scale(
                scale: 0.4 + 0.6 * v.clamp(0.0, 1.2), child: child),
          ),
        );
      },
      child:
          _ActionButton(look: widget.action.look, onTap: widget.action.onTap),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final _ActionLook look;
  final VoidCallback onTap;
  const _ActionButton({required this.look, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = look.dimmed ? ColorName.greyText : look.color;
    return Semantics(
      button: true,
      label: look.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: _actionSize,
                  height: _actionSize,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised,
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withAlpha(120)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(90),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(look.icon, size: 22, color: color),
                ),
                if (look.badge != null)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: _Badge(text: look.badge!),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              look.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ColorName.white,
                shadows: const [Shadow(color: Colors.black, blurRadius: 6)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: ColorName.primaryBlue,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.onPrimary,
        ),
      ),
    );
  }
}

/// The round handle: outpost image with a ring that glows while you talk,
/// a muted badge and the unread chat count.
class _BubbleFace extends StatelessWidget {
  final bool expanded;
  final Animation<double> animation;
  const _BubbleFace({required this.expanded, required this.animation});

  @override
  Widget build(BuildContext context) {
    final ongoing = Get.find<OngoingOutpostCallController>();
    final call = ongoing.outpostCallController;
    final room = findCallRoom();
    return Semantics(
      button: true,
      label: expanded ? 'Close outpost controls' : 'Outpost controls',
      excludeSemantics: true,
      child: Obx(() {
        final outpost = call.outpost.value;
        final muted = ongoing.amIMuted.value;
        final live = !muted && ongoing.canUseMic;
        final unread = room?.unreadTotal ?? 0;
        final showMutedBadge = muted && call.canTalk.value;
        // Built once per Obx pass and reused by the level builder below, so
        // voice level changes don't rebuild the image.
        final image = ClipOval(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Img(
                src: outpost?.image ?? '',
                alt: outpost?.name,
                size: _bubbleSize - 6,
                borderRadius: BorderRadius.zero,
              ),
              FadeTransition(
                opacity: animation,
                child: ColoredBox(
                  color: Colors.black.withAlpha(150),
                  child: Icon(
                    Icons.close_rounded,
                    color: ColorName.white,
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
        );
        return VoiceLevelBuilder(
          uuid: myId,
          builder: (context, level) {
            final glow = live ? (0.35 + level).clamp(0.0, 1.0) : 0.0;
            return SizedBox(
              width: _bubbleSize,
              height: _bubbleSize,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: _bubbleSize,
                    height: _bubbleSize,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: live
                          ? AppGradients.aurora
                          : LinearGradient(
                              colors: [
                                ColorName.white.withAlpha(60),
                                ColorName.white.withAlpha(30),
                              ],
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(110),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                        if (live)
                          BoxShadow(
                            color: AppColors.violet
                                .withAlpha((60 + 120 * glow).round()),
                            blurRadius: 10 + 16 * glow,
                            spreadRadius: 1 + 4 * glow,
                          ),
                      ],
                    ),
                    child: image,
                  ),
                  if (showMutedBadge)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceRaised,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Icon(
                          Icons.mic_off_rounded,
                          size: 13,
                          color: ColorName.white,
                        ),
                      ),
                    ),
                  if (live)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: callSpeakingColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: VoiceBars(level: level, height: 10),
                        ),
                      ),
                    ),
                  if (unread > 0 && !expanded)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: _Badge(text: unread > 99 ? '99+' : '$unread'),
                    ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
