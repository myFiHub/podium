import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/floating_call_bubble.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/navbar.dart';
import 'package:podium/widgets/ui/aurora.dart';

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
        // ConnectedNetworks(),
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

/// Shows a banner once the connection has been down for a few seconds, so
/// brief network hiccups don't flash it.
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
    return Positioned(
      bottom: navbarHeight + 16,
      left: 16,
      right: 16,
      child: IgnorePointer(
        child: AnimatedSlide(
          offset: _visible ? Offset.zero : const Offset(0, 0.4),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: const Duration(milliseconds: 250),
            child: const Center(child: _ConnectionIssueBanner()),
          ),
        ),
      ),
    );
  }
}

class _ConnectionIssueBanner extends StatelessWidget {
  const _ConnectionIssueBanner();

  static Color get _danger => ColorName.danger;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
        decoration: BoxDecoration(
          color: ColorName.cardBackground.withAlpha(240),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _danger.withAlpha(90)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(90),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _danger.withAlpha(36),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                color: _danger,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'No connection. Reconnecting…',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ColorName.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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
