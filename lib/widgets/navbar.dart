import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/notifications/controllers/notifications_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/widgets/ui/app_ui.dart';

const navbarHeight = 64.0;
const _routesWithoutNavbar = [
  Routes.LOGIN,
];

class NavbarItem {
  final String route;
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final Widget? overlay;

  const NavbarItem({
    required this.route,
    required this.icon,
    required this.label,
    this.activeIcon,
    this.overlay,
  });
}

const List<NavbarItem> navbarItems = [
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
    overlay: NotificationBadge(),
  ),
  NavbarItem(
    route: Routes.MY_PROFILE,
    icon: Icons.person_outline,
    activeIcon: Icons.person_rounded,
    label: 'Profile',
    overlay: ProfileBadge(),
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
        decoration: BoxDecoration(
          color: ColorName.navbarBackground,
          border: Border(
            top: BorderSide(color: ColorName.white.withAlpha(16)),
          ),
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
    final activeIndex =
        navbarItems.indexWhere((item) => item.route == activeRoute);
    final motion = reduceMotion(context) ? Duration.zero : _animationDuration;
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / navbarItems.length;
        return Stack(
          children: [
            if (activeIndex >= 0)
              AnimatedPositioned(
                duration: motion,
                curve: Curves.easeOutCubic,
                left: activeIndex * itemWidth + _indicatorInset,
                width: itemWidth - _indicatorInset * 2,
                top: _indicatorTop,
                height: _indicatorHeight,
                child: const _ActiveIndicator(),
              ),
            Row(
              children: [
                for (final item in navbarItems)
                  Expanded(
                    child: _NavItem(
                      item: item,
                      isActive: item.route == activeRoute,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

const _animationDuration = Duration(milliseconds: 240);
const _indicatorInset = 10.0;
const _indicatorTop = 6.0;
const _indicatorHeight = 32.0;

class _ActiveIndicator extends StatelessWidget {
  const _ActiveIndicator();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: [
            ColorName.primaryBlue.withAlpha(46),
            ColorName.auroraViolet.withAlpha(46),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final NavbarItem item;
  final bool isActive;
  const _NavItem({
    required this.item,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? ColorName.primaryBlue : ColorName.secondaryText;
    return Semantics(
      button: true,
      selected: isActive,
      label: item.label,
      excludeSemantics: true,
      child: AppPressScale(
        scale: 0.96,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                Navigate.to(
                  type: NavigationTypes.offAllNamed,
                  route: item.route,
                );
              },
            ),
            IgnorePointer(
              child: _NavItemBody(
                isActive: isActive,
                icon: item.icon,
                activeIcon: item.activeIcon,
                label: item.label,
                color: color,
                overlay: item.overlay,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    final motion = reduceMotion(context) ? Duration.zero : _animationDuration;
    return Column(
      children: [
        const SizedBox(height: _indicatorTop),
        SizedBox(
          width: 44,
          height: _indicatorHeight,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              AnimatedSwitcher(
                duration: motion,
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.72, end: 1.0).animate(animation),
                    child: child,
                  ),
                ),
                child: Icon(
                  isActive ? (activeIcon ?? icon) : icon,
                  key: ValueKey(isActive),
                  size: 22,
                  color: color,
                ),
              ),
              if (overlay != null) overlay!,
            ],
          ),
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedDefaultTextStyle(
              duration: motion,
              style: TextStyle(
                fontSize: 11,
                height: 1.1,
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
              right: 2,
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

Color get _badgeColor => ColorName.danger;

class NotificationBadge extends GetWidget<NotificationsController> {
  const NotificationBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final numberOfUnreadNotifications =
          controller.numberOfUnreadNotifications.value;
      return Positioned(
        right: -6,
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
                    style: TextStyle(
                      color: ColorName.white,
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
