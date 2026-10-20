import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/widgets/navbar.dart';

enum NavigationTypes {
  toNamed,
  offNamed,
  offAllNamed,
  offAllAndToNamed,
  offToNamed,
  offAndToNamed,
}

final Set<String> _tabRoutes = navbarItems.map((e) => e.route).toSet();

bool isTabRoute(String? route) => _tabRoutes.contains(route);

class Navigate {
  static Future to({
    required NavigationTypes type,
    required String route,
    dynamic id,
    Map<String, String>? parameters,
    dynamic arguments,
  }) async {
    if (isTabRoute(route)) {
      _switchTab(route);
      return;
    }
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
  }

  /// All tabs share one page, so switching only pops what's above it and
  /// changes the visible tab. The page is built only when it isn't in the
  /// stack yet, e.g. right after login.
  static void _switchTab(String route) {
    FocusManager.instance.primaryFocus?.unfocus();
    Get.find<GlobalController>().activeRoute.value = route;
    final pages = Get.rootController.rootDelegate.activePages;
    if (pages.any((page) => isTabRoute(page.route?.name))) {
      Get.until((page) => isTabRoute(page.name));
    } else {
      Get.offAllNamed(route);
    }
  }
}
