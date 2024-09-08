import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/utils/logger.dart';
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
      dynamic arguments}) {
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
