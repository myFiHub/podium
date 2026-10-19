import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/widgets/navbar.dart';
import 'package:podium/widgets/ui/app_ui.dart';

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
  static Future to({
    required NavigationTypes type,
    required String route,
    dynamic id,
    Map<String, String>? parameters,
    dynamic arguments,
  }) async {
    switch (type) {
      case NavigationTypes.toNamed:
        Get.toNamed(
          route,
          arguments: arguments,
          parameters: parameters,
        );
        break;
      case NavigationTypes.offNamed:
        Get.offNamed(route, arguments: arguments, parameters: parameters);
        break;
      case NavigationTypes.offAllNamed:
        Get.offAllNamed(route, arguments: arguments, parameters: parameters);
        break;
      case NavigationTypes.offAllAndToNamed:
        Get.offAndToNamed(route, arguments: arguments, parameters: parameters);
        break;
      case NavigationTypes.offToNamed:
        Get.offNamed(route, arguments: arguments, parameters: parameters);
        break;
      case NavigationTypes.offAndToNamed:
        Get.offAndToNamed(route, arguments: arguments, parameters: parameters);
        break;
    }
    if (_validRoutesForNavigation.contains(route) ||
        _validRoutesForNavigation.contains(route.split('/')[0])) {
      final globalController = Get.find<GlobalController>();
      globalController.activeRoute.value = route;
    }
  }
}

Future<bool?> canNavigate() async {
  final hasOngoingCall = Get.isRegistered<OutpostCallController>() &&
      Get.find<OutpostCallController>().isInCall.value;
  if (!hasOngoingCall) return true;
  return showAppConfirm(
    title: 'Leave this outpost?',
    message: 'Opening another page will take you out of the live outpost. '
        'You can rejoin while it is still live.',
    confirmLabel: 'Leave',
    cancelLabel: 'Stay',
    destructive: true,
  );
}
