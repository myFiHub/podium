import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/notifications/controllers/notifications_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/utils/navigation/navigation.dart';

const navbarHeight = 60.0;
const _routesWithoutNavbar = [
  Routes.LOGIN,
  Routes.SIGNUP,
];

class NavbarItem {
  final String route;
  final IconData icon;
  final String label;
  final Widget? overlay;

  NavbarItem({
    required this.route,
    required this.icon,
    required this.label,
    this.overlay,
  });
}

final List<NavbarItem> navbarItems = [
  NavbarItem(
    route: Routes.HOME,
    icon: Icons.home_outlined,
    label: 'Home',
  ),
  NavbarItem(
    route: Routes.ALL_GROUPS,
    icon: Icons.group_outlined,
    label: 'Groups',
  ),
  NavbarItem(
    route: Routes.SEARCH,
    icon: Icons.search_outlined,
    label: 'Search',
  ),
  NavbarItem(
    route: Routes.NOTIFICATIONS,
    icon: Icons.notifications_outlined,
    label: 'Notifications',
    overlay: NotificationBadge(),
  ),
  NavbarItem(
    route: Routes.MY_PROFILE,
    icon: Icons.person_outline,
    label: 'Profile',
  ),
];

class PodiumNavbar extends GetWidget<GlobalController> {
  const PodiumNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final activeRoute = controller.activeRoute.value;
      if (_routesWithoutNavbar.contains(activeRoute)) {
        return Container(
          height: 0,
        );
      }
      return Container(
        height: navbarHeight,
        color: ColorName.navbarBackground,
        child: BottomNav(
          activeRoute: activeRoute,
        ),
      );
    });
  }
}

class BottomNav extends StatelessWidget {
  final String activeRoute;
  const BottomNav({super.key, required this.activeRoute});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.from(
          navbarItems.map(
            (item) => _buildNavItem(
              route: item.route,
              icon: item.icon,
              label: item.label,
              overlay: item.overlay,
            ),
          ),
        ),
      ),
    );
  }
}

final _animationDuration = const Duration(milliseconds: 200);
Widget _buildNavItem({
  required String route,
  required IconData icon,
  required String label,
  Widget? overlay,
}) {
  final activeRoute = Get.find<GlobalController>().activeRoute.value;
  final isActive = activeRoute == route;
  return GestureDetector(
    onTap: () {
      Navigate.to(type: NavigationTypes.offAllAndToNamed, route: route);
    },
    child: Column(
      children: [
        AnimatedContainer(
          duration: _animationDuration,
          width: 24,
          padding: EdgeInsets.only(bottom: 8, top: 18),
          decoration: isActive
              ? BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.blue,
                      width: 2,
                    ),
                  ),
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                )
              : BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.transparent,
                      width: 0,
                    ),
                  ),
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(0),
                    bottomLeft: Radius.circular(0),
                  ),
                ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedScale(
                scale: isActive ? 1.3 : 1,
                child: Icon(
                  icon,
                  color: isActive ? Colors.blue : Colors.grey,
                ),
                duration: _animationDuration,
              ),
              if (overlay != null) overlay,
            ],
          ),
        ),
        const SizedBox(height: 5),
      ],
    ),
  );
}

class NotificationBadge extends GetWidget<NotificationsController> {
  const NotificationBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final numberOfUnreadNotifications =
          controller.numberOfUnreadNotifications.value;
      return numberOfUnreadNotifications > 0
          ? Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Text(
                  numberOfUnreadNotifications.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Container();
    });
  }
}
