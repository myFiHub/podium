import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/controllers/referral_controller.dart';
import 'package:podium/app/modules/global/controllers/users_controller.dart';
import 'package:podium/app/modules/global/services/oneSignal.dart';
import 'package:podium/app/modules/notifications/controllers/notifications_controller.dart';
import 'package:podium/app/services/image_service.dart';
import 'package:podium/data/repositories/repositories.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/services/call_overlay/call_overlay.dart';

// Repositories are stateless; fenix lets smart management drop and recreate
// them freely. They must come before the controllers that find them.
final globalBindings = [
  Bind.lazyPut<OutpostRepository>(
    () => OutpostRepository(HttpApis.podium),
    fenix: true,
  ),
  Bind.lazyPut<UserRepository>(
    () => UserRepository(HttpApis.podium),
    fenix: true,
  ),
  Bind.lazyPut<NotificationRepository>(
    () => NotificationRepository(HttpApis.podium),
    fenix: true,
  ),
  Bind.lazyPut<AuthRepository>(
    () => AuthRepository(
      HttpApis.podium,
      connectSocket: (token) =>
          Get.find<GlobalController>().initializeWebSocket(token: token),
    ),
    fenix: true,
  ),
  Bind.put<GlobalController>(GlobalController(), permanent: true),
  Bind.put<OutpostsController>(OutpostsController(), permanent: true),
  Bind.put<UsersController>(UsersController(), permanent: true),
  Bind.put<OutpostCallController>(OutpostCallController(), permanent: true),
  Bind.put<NotificationsController>(NotificationsController(), permanent: true),
  Bind.put<ReferalController>(ReferalController(), permanent: true),
  Bind.put<OneSignalService>(OneSignalService(), permanent: true),
  Bind.put<OutpostImageService>(OutpostImageService(), permanent: true),
  Bind.put<CallOverlayService>(CallOverlayService(), permanent: true),
];

class GlobalBindings extends Binding {
  @override
  List<Bind> dependencies() => globalBindings;
}
