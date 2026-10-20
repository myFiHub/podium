import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/login/controllers/login_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/navigation/navigation.dart';

/// Ids carried by app links such as `/outpost-detail/<id>` and
/// `/referral/<id>`.
abstract final class DeepLink {
  static String? outpostId(String route) =>
      _idAfter(route, Routes.OUTPOST_DETAIL);

  static String? referrerId(String route) => _idAfter(route, Routes.REFERRED);

  static String? _idAfter(String route, String marker) {
    final index = route.indexOf(marker);
    if (index < 0) return null;
    final id = route.substring(index + marker.length).replaceAll('/', '');
    return id.isEmpty ? null : id;
  }
}

/// Holds the link the app was opened with until it can be acted on: outpost
/// links once logged in, referral links on the login page.
class DeepLinkHandler {
  DeepLinkHandler({required this.isLoggedIn, required this.logout});

  final bool Function() isLoggedIn;
  final void Function() logout;

  /// Pending link; empty once handled.
  final route = ''.obs;

  String? get pendingReferrerId => DeepLink.referrerId(route.value);

  void handle(String link) {
    route.value = link;
    if (isLoggedIn()) {
      if (!openPendingOutpost()) l.e("deep link not handled: $link");
    } else if (DeepLink.referrerId(link) != null) {
      _openLoginWithReferral(link);
    }
  }

  /// Opens the pending outpost link, if any. Returns whether there was one.
  bool openPendingOutpost() {
    final outpostId = DeepLink.outpostId(route.value);
    if (outpostId == null) return false;
    Navigate.to(type: NavigationTypes.offAllNamed, route: Routes.HOME);
    Get.find<OutpostsController>().joinOutpostAndOpenOutpostDetailPage(
      outpostId: outpostId,
      joiningByLink: true,
    );
    route.value = '';
    return true;
  }

  void _openLoginWithReferral(String link) {
    if (isLoggedIn()) {
      logout();
      return;
    }
    Navigate.to(
      type: NavigationTypes.offAllNamed,
      route: Routes.LOGIN,
      parameters: {
        LoginParametersKeys.referrerId: DeepLink.referrerId(link) ?? '',
      },
    );
  }
}
