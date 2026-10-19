import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/call_room_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/member_interactions.dart';
import 'package:podium/utils/palette.dart';

/// Banner for my own share plus the minimized stage for someone else's.
/// Sits above the scrolling member list so the native stage never scrolls.
class ScreenShareArea extends StatelessWidget {
  const ScreenShareArea({super.key});

  @override
  Widget build(BuildContext context) {
    final room = findCallRoom();
    if (room == null) return const SizedBox.shrink();
    return Obx(() {
      final sharing = room.localSharing.value;
      final share = room.remoteShare.value;
      final maximized = room.stageMaximized.value;
      return AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (sharing) _LocalShareBanner(room: room),
            if (share != null && !maximized) _MinimizedStage(room: room),
          ],
        ),
      );
    });
  }
}

class _LocalShareBanner extends StatelessWidget {
  final CallRoomController room;
  const _LocalShareBanner({required this.room});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: callSpeakingColor.withAlpha(26),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: callSpeakingColor.withAlpha(90)),
      ),
      child: Row(
        children: [
          _LiveDot(color: callSpeakingColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "You're sharing your screen",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Everyone can see it · uses your talk time',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: ColorName.greyText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: room.stopScreenShare,
            style: FilledButton.styleFrom(
              backgroundColor: callDangerColor,
              foregroundColor: ColorName.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: const Size(0, 38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Stop',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _MinimizedStage extends StatelessWidget {
  final CallRoomController room;
  const _MinimizedStage({required this.room});

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _LiveDot(color: callDangerColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "${room.sharerName}'s screen",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              _StageButton(
                icon: Icons.open_in_full_rounded,
                tooltip: 'Maximize',
                onTap: room.toggleStageMaximized,
              ),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) => Obx(() {
              final aspect = room.stageAspect.value;
              final height = (constraints.maxWidth / aspect)
                  .clamp(150.0, screen.height * 0.36);
              return GestureDetector(
                onDoubleTap: room.toggleStageMaximized,
                child: _StageFrame(
                  height: height,
                  radius: 16,
                  child: const StageSlot(),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Full-screen stage, layered over the whole call page.
class FullscreenStage extends StatelessWidget {
  const FullscreenStage({super.key});

  @override
  Widget build(BuildContext context) {
    final room = findCallRoom();
    if (room == null) return const SizedBox.shrink();
    return Obx(() {
      final share = room.remoteShare.value;
      if (share == null || !room.stageMaximized.value) {
        return const SizedBox.shrink();
      }
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) room.stageMaximized.value = false;
        },
        child: ColoredBox(
          color: Colors.black,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  child: Row(
                    children: [
                      _LiveDot(color: callDangerColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "${room.sharerName}'s screen",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      _StageButton(
                        icon: Icons.close_fullscreen_rounded,
                        tooltip: 'Minimize',
                        onTap: room.toggleStageMaximized,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onDoubleTap: room.toggleStageMaximized,
                    child: const StageSlot(),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Double-tap to minimize',
                  style: TextStyle(fontSize: 12, color: ColorName.greyText),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _StageFrame extends StatelessWidget {
  final double height;
  final double radius;
  final Widget child;
  const _StageFrame({
    required this.height,
    required this.radius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: ColorName.cardBorder),
      ),
      child: child,
    );
  }
}

class _StageButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _StageButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: ColorName.white.withAlpha(16),
        foregroundColor: ColorName.white,
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  final Color color;
  const _LiveDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withAlpha(140), blurRadius: 6)],
      ),
    );
  }
}

/// The area the native stage window is placed over. It's hidden whenever
/// another route (sheet, dialog, page) is on top, since Flutter can't draw
/// over a native view.
class StageSlot extends StatefulWidget {
  const StageSlot({super.key});

  @override
  State<StageSlot> createState() => _StageSlotState();
}

class _StageSlotState extends State<StageSlot> {
  final room = findCallRoom();

  @override
  void dispose() {
    room?.setStageRect(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = ModalRoute.of(context)?.isCurrent ?? true;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return _RectReporter(
      active: active,
      onRect: (rect) {
        if (mounted) room?.setStageRect(rect, dpr);
      },
      child: ColoredBox(
        color: Colors.black,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ColorName.greyText,
            ),
          ),
        ),
      ),
    );
  }
}

class _RectReporter extends SingleChildRenderObjectWidget {
  final bool active;
  final ValueChanged<Rect?> onRect;
  const _RectReporter({
    required this.active,
    required this.onRect,
    super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderRectReporter(active: active, onRect: onRect);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderRectReporter renderObject,
  ) {
    renderObject
      ..onRect = onRect
      ..active = active;
  }
}

/// Reports its global rect after every paint where it changed.
class _RenderRectReporter extends RenderProxyBox {
  _RenderRectReporter({required bool active, required this.onRect})
      : _active = active;

  ValueChanged<Rect?> onRect;
  bool _active;
  Rect? _reported;
  bool _reportedOnce = false;

  set active(bool value) {
    if (value == _active) return;
    _active = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    final rect = _active ? localToGlobal(Offset.zero) & size : null;
    if (_reportedOnce && rect == _reported) return;
    _reportedOnce = true;
    _reported = rect;
    SchedulerBinding.instance.addPostFrameCallback((_) => onRect(rect));
  }
}
