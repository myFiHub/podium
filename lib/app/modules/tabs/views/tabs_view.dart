import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/allOutposts/views/all_outposts_view.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/home/views/home_view.dart';
import 'package:podium/app/modules/myProfile/views/my_profile_view.dart';
import 'package:podium/app/modules/notifications/views/notifications_view.dart';
import 'package:podium/app/modules/search/views/search_view.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/widgets/navbar.dart';
import 'package:podium/widgets/ui/aurora.dart';

const _tabViews = <String, Widget>{
  Routes.HOME: HomeView(),
  Routes.ALL_OUTPOSTS: AllOutpostsView(),
  Routes.SEARCH: SearchView(),
  Routes.NOTIFICATIONS: NotificationsView(),
  Routes.MY_PROFILE: MyProfileView(),
};

/// A second back press within this window closes the app.
const _exitWindow = Duration(seconds: 2);

/// Every navbar tab, kept alive in one page so switching tabs keeps scroll
/// positions and loaded data. Tabs are built on first visit; hidden tabs stop
/// their animations.
class TabsView extends StatefulWidget {
  const TabsView({super.key});

  @override
  State<TabsView> createState() => _TabsViewState();
}

class _TabsViewState extends State<TabsView>
    with SingleTickerProviderStateMixin {
  final _activeRoute = Get.find<GlobalController>().activeRoute;
  final _visited = <int>{};
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic);
  late final Animation<Offset> _rise = Tween(
    begin: const Offset(0, 0.012),
    end: Offset.zero,
  ).animate(_fade);
  late final Worker _tabWorker;
  DateTime? _lastBackAt;

  @override
  void initState() {
    super.initState();
    _tabWorker = ever(_activeRoute, (_) {
      if (!mounted) return;
      if (reduceMotion(context)) {
        _enter.value = 1;
      } else {
        _enter.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _tabWorker.dispose();
    _enter.dispose();
    super.dispose();
  }

  int _indexOf(String route) =>
      navbarItems.indexWhere((item) => item.route == route);

  int _currentIndex() {
    var index = _indexOf(_activeRoute.value);
    if (index == -1) {
      index = _indexOf(ModalRoute.of(context)?.settings.name ?? '');
    }
    return index == -1 ? 0 : index;
  }

  void _onBack(bool didPop, Object? _) {
    if (didPop) return;
    if (_currentIndex() != 0) {
      Navigate.to(type: NavigationTypes.offAllNamed, route: Routes.HOME);
      return;
    }
    final now = DateTime.now();
    final last = _lastBackAt;
    if (last != null && now.difference(last) < _exitWindow) {
      SystemNavigator.pop();
      return;
    }
    _lastBackAt = now;
    Toast.info(
      title: 'Press back again to exit',
      message: '',
      duration: _exitWindow.inSeconds,
      position: SnackPosition.bottom,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onBack,
      child: Obx(() {
        final index = _currentIndex();
        _visited.add(index);
        return IndexedStack(
          index: index,
          sizing: StackFit.expand,
          children: [
            for (var i = 0; i < navbarItems.length; i++)
              _visited.contains(i)
                  ? _Tab(
                      active: i == index,
                      fade: i == index ? _fade : kAlwaysCompleteAnimation,
                      rise: i == index
                          ? _rise
                          : const AlwaysStoppedAnimation(Offset.zero),
                      child: _tabViews[navbarItems[i].route]!,
                    )
                  : const SizedBox.shrink(),
          ],
        );
      }),
    );
  }
}

class _Tab extends StatelessWidget {
  final bool active;
  final Animation<double> fade;
  final Animation<Offset> rise;
  final Widget child;
  const _Tab({
    required this.active,
    required this.fade,
    required this.rise,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TickerMode(
      enabled: active,
      child: HeroMode(
        enabled: active,
        child: FadeTransition(
          opacity: fade,
          child: SlideTransition(position: rise, child: child),
        ),
      ),
    );
  }
}
