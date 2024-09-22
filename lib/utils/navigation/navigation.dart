import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/ongoingGroupCall/controllers/ongoing_group_call_controller.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/widgets/navbar.dart';

enum NavigationTypes {
  toNamed,
  offNamed,
  offAllNamed,
  offAllAndToNamed,
  offToNamed,
  offAndToNamed,
}

final List<String> _validRoutesForNavigation =
    List.from(navbarItems.map((e) => e.route));

class Navigate {
  static to(
      {required NavigationTypes type,
      required String route,
      dynamic arguments}) async {
    switch (type) {
      case NavigationTypes.toNamed:
        Get.toNamed(route, arguments: arguments);
        break;
      case NavigationTypes.offNamed:
        Get.offNamed(route, arguments: arguments);
        break;
      case NavigationTypes.offAllNamed:
        Get.offAllNamed(route, arguments: arguments);
        break;
      case NavigationTypes.offAllAndToNamed:
        Get.offAndToNamed(route, arguments: arguments);
        break;
      case NavigationTypes.offToNamed:
        Get.offNamed(route, arguments: arguments);
        break;
      case NavigationTypes.offAndToNamed:
        Get.offAndToNamed(route, arguments: arguments);
        break;
    }
    if (_validRoutesForNavigation.contains(route) ||
        _validRoutesForNavigation.contains(route.split('/')[0])) {
      final globalController = Get.find<GlobalController>();
      globalController.activeRoute.value = route;
    }
  }
}

Future<bool> canNavigate() async {
  final hasOngoingCall = Get.isRegistered<OngoingGroupCallController>();
  if (!hasOngoingCall) return true;
  final can = await Get.dialog(
    AlertDialog(
      backgroundColor: ColorName.cardBackground,
      title: const Text('Are you sure?'),
      content: RichText(
        text: TextSpan(
          // Note: Styles for TextSpans must be explicitly defined.
          // Child text spans will inherit styles from parent
          style: TextStyle(height: 2),
          children: <TextSpan>[
            TextSpan(text: 'By navigating to another page, you will also '),
            TextSpan(
              text: 'LEAVE THE ROOM',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            TextSpan(text: ', Continue?'),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(Get.overlayContext!).pop(false);
          },
          child: const Text('No'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(Get.overlayContext!).pop(true);
          },
          child: const Text('Yes'),
        ),
      ],
    ),
  );
  return can;
}
