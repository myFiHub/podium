import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/widgets/navbar.dart';

class Root extends StatelessWidget {
  final Widget child;
  const Root({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: AnimatedBgbWrapper(
            child: child,
          ),
        ),
        PodiumNavbar(),
      ],
    );
  }
}

class AnimatedBgbWrapper extends GetWidget<GlobalController> {
  final Widget child;
  const AnimatedBgbWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loggedIn = controller.loggedIn.value;
      return AnimatedContainer(
          child: child,
          duration: const Duration(seconds: 2),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: loggedIn ? Alignment(0, -1) : Alignment(-0.1, -0.4),
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
  ColorName.pageBgGradientStart.withOpacity(0.5),
  ColorName.pageBgGradientStart.withOpacity(0.4),
  ColorName.pageBgGradientStart.withOpacity(0.1),
  ColorName.pageBgGradientStart.withOpacity(0.05),
  ColorName.pageBgGradientStart.withOpacity(0),
];
