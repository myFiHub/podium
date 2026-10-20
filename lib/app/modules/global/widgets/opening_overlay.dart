import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/controllers/users_controller.dart';
import 'package:podium/app/modules/global/widgets/loading_widget.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/rx_selector.dart';
import 'package:podium/widgets/ui/app_ui.dart';
import 'package:shimmer/shimmer.dart';

/// Covers [child] with a sweeping sheen and a spinner while [busy], so a tap
/// that waits on the network visibly does something.
class BusyOverlay extends StatelessWidget {
  const BusyOverlay({
    super.key,
    required this.busy,
    required this.child,
    this.radius = AppRadius.lg,
  });

  final bool busy;
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: busy ? _Sheen(radius: radius) : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

class _Sheen extends StatelessWidget {
  const _Sheen({required this.radius});

  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: ColorName.pageBackground.withAlpha(120)),
          Shimmer.fromColors(
            baseColor: Colors.transparent,
            highlightColor: ColorName.white.withAlpha(36),
            period: const Duration(milliseconds: 1100),
            child: ColoredBox(color: ColorName.white),
          ),
          const Center(child: LoadingWidget(size: 18)),
        ],
      ),
    );
  }
}

/// [BusyOverlay] while the outpost with [outpostId] is being opened.
class OpeningOutpostOverlay extends StatelessWidget {
  const OpeningOutpostOverlay({
    super.key,
    required this.outpostId,
    required this.child,
  });

  final String outpostId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final joining = Get.find<OutpostsController>().joiningOutpostId;
    return RxSelector<bool>(
      sources: [joining],
      select: () => joining.value == outpostId,
      child: child,
      builder: (context, busy, child) => BusyOverlay(busy: busy, child: child!),
    );
  }
}

/// [BusyOverlay] while the profile of [userId] is being opened.
class OpeningProfileOverlay extends StatelessWidget {
  const OpeningProfileOverlay({
    super.key,
    required this.userId,
    required this.child,
  });

  final String userId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final loading = Get.find<UsersController>().gettingUserInfo_uuid;
    return RxSelector<bool>(
      sources: [loading],
      select: () => loading.value == userId,
      child: child,
      builder: (context, busy, child) => BusyOverlay(busy: busy, child: child!),
    );
  }
}
