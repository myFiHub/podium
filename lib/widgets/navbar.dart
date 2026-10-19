import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/lib/jitsiMeet.dart';
import 'package:podium/app/modules/notifications/controllers/notifications_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/utils/navigation/navigation.dart';

const navbarHeight = 60.0;
const _routesWithoutNavbar = [
  Routes.LOGIN,
];

class NavbarItem {
  final String route;
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final Widget? overlay;

  NavbarItem({
    required this.route,
    required this.icon,
    required this.label,
    this.activeIcon,
    this.overlay,
  });
}

final List<NavbarItem> navbarItems = [
  NavbarItem(
    route: Routes.HOME,
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label: 'Home',
  ),
  NavbarItem(
    route: Routes.ALL_OUTPOSTS,
    icon: Icons.group_outlined,
    activeIcon: Icons.group_rounded,
    label: 'Outposts',
  ),
  NavbarItem(
    route: Routes.SEARCH,
    icon: Icons.search_outlined,
    activeIcon: Icons.search_rounded,
    label: 'Search',
  ),
  NavbarItem(
    route: Routes.NOTIFICATIONS,
    icon: Icons.notifications_outlined,
    activeIcon: Icons.notifications_rounded,
    label: 'Alerts',
    overlay: const NotificationBadge(),
  ),
  NavbarItem(
    route: Routes.MY_PROFILE,
    icon: Icons.person_outline,
    activeIcon: Icons.person_rounded,
    label: 'Profile',
    overlay: const ProfileBadge(),
  ),
];

class PodiumNavbar extends GetView<GlobalController> {
  const PodiumNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loggedIn = controller.loggedIn.value;
      final activeRoute = controller.activeRoute.value;
      if (_routesWithoutNavbar.contains(activeRoute) || loggedIn == false) {
        return const SizedBox(
          height: 0,
        );
      }
      final bottomSpace = MediaQuery.viewInsetsOf(context).bottom;
      return Container(
        height: bottomSpace == 0 ? navbarHeight : 0,
        decoration: const BoxDecoration(
          color: ColorName.navbarBackground,
          border: Border(top: BorderSide(color: ColorName.cardBorder)),
        ),
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.15,
          child: BottomNav(
            activeRoute: activeRoute,
          ),
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
      color: Colors.transparent,
      child: Row(
        children: List.from(
          navbarItems.map(
            (item) => Expanded(
              child: _buildNavItem(
                route: item.route,
                icon: item.icon,
                activeIcon: item.activeIcon,
                label: item.label,
                overlay: item.overlay,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _animationDuration = Duration(milliseconds: 220);
Widget _buildNavItem({
  required String route,
  required IconData icon,
  IconData? activeIcon,
  required String label,
  Widget? overlay,
}) {
  final activeRoute = Get.find<GlobalController>().activeRoute.value;
  final isActive = activeRoute == route;
  final color = isActive ? Colors.white : ColorName.secondaryText;
  return Semantics(
    button: true,
    selected: isActive,
    label: label,
    excludeSemantics: true,
    child: InkWell(
      splashColor: ColorName.primaryBlue.withAlpha(30),
      highlightColor: Colors.transparent,
      onTap: () async {
        HapticFeedback.selectionClick();
        final canNavigateToNewRoute = await canNavigate();
        if (canNavigateToNewRoute != true) {
          return;
        }
        jitsiMeet.hangUp();
        Navigate.to(
          type: NavigationTypes.offAllNamed,
          route: route,
        );
      },
      child: _NavItemBody(
        isActive: isActive,
        icon: icon,
        activeIcon: activeIcon,
        label: label,
        color: color,
        overlay: overlay,
      ),
    ),
  );
}

class _NavItemBody extends StatelessWidget {
  final bool isActive;
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final Color color;
  final Widget? overlay;
  const _NavItemBody({
    required this.isActive,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
    required this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: _animationDuration,
            curve: Curves.easeOutCubic,
            width: isActive ? 56 : 44,
            height: 30,
            decoration: BoxDecoration(
              color: isActive
                  ? ColorName.primaryBlue.withAlpha(46)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: _animationDuration,
                  child: Icon(
                    isActive ? (activeIcon ?? icon) : icon,
                    key: ValueKey(isActive),
                    size: 22,
                    color: isActive ? ColorName.primaryBlue : color,
                  ),
                ),
                if (overlay != null) overlay!,
              ],
            ),
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: AnimatedDefaultTextStyle(
                duration: _animationDuration,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.2,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileBadge extends GetView<GlobalController> {
  const ProfileBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentUser = controller.myUserInfo.value;
      if (currentUser == null) {
        return const SizedBox.shrink();
      }
      final accounts = currentUser.accounts;
      final primaryAccount = accounts.firstWhere(
        (account) => account.is_primary,
        orElse: () => ConnectedAccount(
            address: currentUser.address,
            aptos_address: currentUser.aptos_address!,
            image: currentUser.image,
            is_primary: true,
            login_type: currentUser.login_type,
            login_type_identifier: currentUser.login_type_identifier ?? '',
            uuid: currentUser.uuid),
      );

      final isThisAccountPrimary =
          primaryAccount.address == currentUser.address;
      return !isThisAccountPrimary
          ? Positioned(
              right: 8,
              top: 2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _badgeColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ColorName.navbarBackground,
                    width: 2,
                  ),
                ),
              ),
            )
          : const SizedBox.shrink();
    });
  }
}

const _badgeColor = ColorName.danger;

class NotificationBadge extends GetWidget<NotificationsController> {
  const NotificationBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final numberOfUnreadNotifications =
          controller.numberOfUnreadNotifications.value;
      return numberOfUnreadNotifications > 0
          ? Positioned(
              right: 2,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: _badgeColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: ColorName.navbarBackground,
                    width: 2,
                  ),
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 18,
                ),
                alignment: Alignment.center,
                child: Text(
                  numberOfUnreadNotifications > 99
                      ? '99+'
                      : numberOfUnreadNotifications.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : const SizedBox.shrink();
    });
  }
}
