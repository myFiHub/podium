import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:podium/app/routes/app_pages.dart';

/// Follows the root page stack to know where the call page is. Get 5 keeps
/// its own page list in the root delegate, so that is the source of truth.
class CallRouteTracker {
  CallRouteTracker._();
  static final instance = CallRouteTracker._();

  /// True while the call page is the top page (dialogs and sheets aside).
  final isCallPageVisible = false.obs;
  final isCallPageInStack = false.obs;

  /// Dialogs and bottom sheets live outside the page list, so a navigator
  /// observer counts them.
  final openPopups = 0.obs;
  late final NavigatorObserver observer = _PopupObserver(openPopups);

  GetDelegate? _delegate;

  void attach() {
    if (_delegate != null) return;
    final delegate = Get.rootController.rootDelegate;
    _delegate = delegate;
    delegate.addListener(_sync);
    _sync();
  }

  List<RouteDecoder> get _pages => _delegate?.activePages ?? const [];

  bool _isCallPage(RouteDecoder page) =>
      page.route?.name == Routes.ONGOING_OUTPOST_CALL;

  void _sync() {
    final pages = _pages;
    isCallPageInStack.value = pages.any(_isCallPage);
    isCallPageVisible.value = pages.isNotEmpty && _isCallPage(pages.last);
  }

  /// Removes the call page wherever it is in the stack.
  void removeCallPage() {
    final delegate = _delegate ?? Get.rootController.rootDelegate;
    final pages = delegate.activePages;
    final index = pages.indexWhere(_isCallPage);
    if (index == -1) return;
    if (index == pages.length - 1) {
      if (pages.length > 1) {
        Get.back();
      } else {
        Get.offAllNamed(Routes.HOME);
      }
      return;
    }
    final removed = pages.removeAt(index);
    final completer = removed.route?.completer;
    if (completer != null && !completer.isCompleted) completer.complete();
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    delegate.notifyListeners();
  }
}

class _PopupObserver extends NavigatorObserver {
  final RxInt count;
  _PopupObserver(this.count);

  void _add(Route? route, int delta) {
    if (route is! PopupRoute) return;
    count.value = (count.value + delta).clamp(0, 1 << 20);
  }

  @override
  void didPush(Route route, Route? previousRoute) => _add(route, 1);

  @override
  void didPop(Route route, Route? previousRoute) => _add(route, -1);

  @override
  void didRemove(Route route, Route? previousRoute) => _add(route, -1);

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    _add(oldRoute, -1);
    _add(newRoute, 1);
  }
}
