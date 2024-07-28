import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
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

  NavbarItem({
    required this.route,
    required this.icon,
    required this.label,
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
}) {
  final activeRoute = Get.find<GlobalController>().activeRoute.value;
  final isActive = activeRoute == route;
  return GestureDetector(
    onTap: () {
      Navigate.to(type: NavigationTypes.offNamed, route: route);
    },
    child: Column(
      children: [
        AnimatedContainer(
          duration: _animationDuration,
          width: 30,
          padding: EdgeInsets.only(bottom: 8, top: 18),
          decoration: isActive
              ? BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.blue,
                      width: 5,
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isActive ? 1.3 : 1,
                child: Icon(
                  icon,
                  color: isActive ? Colors.blue : Colors.grey,
                ),
                duration: _animationDuration,
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
      ],
    ),
  );
}
