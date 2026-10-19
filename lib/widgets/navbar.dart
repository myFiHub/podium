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
import 'package:podium/widgets/ui/app_ui.dart';

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
        color: ColorName.navbarBackground,
        child: Stack(
          children: [
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.15,
              child: BottomNav(
                activeRoute: activeRoute,
              ),
            ),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0x0054E4EF),
                      Color(0x8054E4EF),
                      Color(0x808B5CF6),
                      Color(0x80FF4FD8),
                      Color(0x00FF4FD8),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
      child: AppPressScale(
        scale: 0.92,
        child: _NavItemBody(
          isActive: isActive,
          icon: icon,
          activeIcon: activeIcon,
          label: label,
          color: color,
          overlay: overlay,
        ),
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
              gradient: LinearGradient(
                colors: isActive
                    ? [
                        ColorName.primaryBlue.withAlpha(56),
                        ColorName.auroraViolet.withAlpha(56),
                      ]
                    : [
                        ColorName.primaryBlue.withAlpha(0),
                        ColorName.auroraViolet.withAlpha(0),
                      ],
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: ColorName.auroraViolet.withAlpha(isActive ? 50 : 0),
                  blurRadius: 14,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween(begin: 0.6, end: 1.0).animate(animation),
                      child: child,
                    ),
                  ),
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
      return Positioned(
        right: 2,
        top: -4,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: numberOfUnreadNotifications > 0
              ? Container(
                  key: const ValueKey('badge'),
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
                  child: AppRollingText(
                    numberOfUnreadNotifications > 99
                        ? '99+'
                        : numberOfUnreadNotifications.toString(),
                    alignment: Alignment.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('none')),
        ),
      );
    });
  }
}
