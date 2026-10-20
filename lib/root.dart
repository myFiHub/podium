import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/floating_call_bubble.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/navbar.dart';
import 'package:podium/widgets/ui/app_ui.dart';

class Root extends StatelessWidget {
  final Widget child;
  const Root({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: child,
            ),
            const PodiumNavbar(),
          ],
        ),
        const InternetConnectionChecker(),
        const FloatingCallBubble(),
      ],
    );
  }
}

class PageWrapper extends StatelessWidget {
  final Widget child;
  const PageWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBgbWrapper(
      child: child,
    );
  }
}

/// Shows a tiny badge in the top-right corner once the connection has been
/// down for a few seconds, so brief network hiccups don't flash it.
class InternetConnectionChecker extends StatefulWidget {
  const InternetConnectionChecker({super.key});

  @override
  State<InternetConnectionChecker> createState() =>
      _InternetConnectionCheckerState();
}

class _InternetConnectionCheckerState extends State<InternetConnectionChecker> {
  static const _showDelay = Duration(seconds: 3);

  Worker? _worker;
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<GlobalController>()) return;
    final connection = Get.find<GlobalController>().isConnectedToInternet;
    _onChange(connection.value);
    _worker = ever<bool>(connection, _onChange);
  }

  void _onChange(bool connected) {
    _timer?.cancel();
    if (connected) {
      if (_visible && mounted) setState(() => _visible = false);
      return;
    }
    _timer = Timer(_showDelay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _worker?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sits just under the status bar, outside the 12px gutter page headers
    // keep around their trailing buttons, and never takes touches.
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 2,
      right: 4,
      child: IgnorePointer(
        child: Semantics(
          liveRegion: true,
          label: _visible ? 'No connection, reconnecting' : null,
          child: AnimatedScale(
            scale: _visible ? 1 : 0.4,
            duration: const Duration(milliseconds: 260),
            curve: _visible ? Curves.easeOutBack : Curves.easeInCubic,
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: _ConnectionIssueBadge(active: _visible),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectionIssueBadge extends StatelessWidget {
  final bool active;
  const _ConnectionIssueBadge({required this.active});

  static const double _size = 15;

  @override
  Widget build(BuildContext context) {
    final danger = ColorName.danger;
    return AppBreathing(
      active: active,
      period: const Duration(milliseconds: 1600),
      builder: (context, glow) => Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: danger,
          shape: BoxShape.circle,
          border: Border.all(color: ColorName.pageBackground, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: danger.withAlpha(60 + (90 * glow).round()),
              blurRadius: 4 + 6 * glow,
              spreadRadius: 1 * glow,
            ),
          ],
        ),
        child: Icon(
          Icons.wifi_off_rounded,
          size: 9,
          color: AppColors.onColor(danger),
        ),
      ),
    );
  }
}

class AnimatedBgbWrapper extends GetView<GlobalController> {
  final Widget child;
  const AnimatedBgbWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AuroraBackground(
        intensity: controller.loggedIn.value ? 1 : 1.3,
        child: child,
      ),
    );
  }
}
