import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/lib/BlockChain.dart';
import 'package:podium/app/modules/global/widgets/chainIcons.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/navbar.dart';

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
              child: AnimatedBgbWrapper(
                child: child,
              ),
            ),
            PodiumNavbar(),
          ],
        ),
        // InternetConnectionChecker(),
        // ConnectedNetworks(),
      ],
    );
  }
}

class InternetConnectionChecker extends GetView<GlobalController> {
  const InternetConnectionChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final connected = controller.isConnectedToInternet.value;
      final AppLifecycleState state = controller.appLifecycleState.value;
      return connected && state != AppLifecycleState.paused
          ? const SizedBox()
          : Positioned(
              child: Material(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Row(
                    children: [
                      Text(
                        'connection issue',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.wifi_off,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
              bottom: 70,
              left: Get.width / 2 - 100,
            );
    });
  }
}

class AnimatedBgbWrapper extends GetView<GlobalController> {
  final Widget child;
  const AnimatedBgbWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loggedIn = controller.loggedIn.value;
      return AnimatedContainer(
          child: child,
          duration: const Duration(seconds: 1),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: loggedIn ? Alignment(0, -1) : Alignment(-0.0, -0.1),
              colors: loggedIn ? _linearColors : _cirularColors,
              radius: loggedIn ? 2.0 : 1.0,
            ),
          ));
    });
  }
}

final _linearColors = [
  ColorName.pageBgGradientStart,
  ColorName.pageBgGradientEnd,
];
final _cirularColors = [
  ColorName.pageBgGradientStart.withOpacity(0.6),
  ColorName.pageBgGradientStart.withOpacity(0.5),
  ColorName.pageBgGradientStart.withOpacity(0.4),
  ColorName.pageBgGradientStart.withOpacity(0.3),
  ColorName.pageBgGradientStart.withOpacity(0.2),
  // ColorName.pageBgGradientStart.withOpacity(0.1),
];
