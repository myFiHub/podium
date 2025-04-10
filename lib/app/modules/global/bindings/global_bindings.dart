import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/controllers/recorder_controller.dart';
import 'package:podium/app/modules/global/controllers/referral_controller.dart';
import 'package:podium/app/modules/global/controllers/users_controller.dart';
import 'package:podium/app/modules/notifications/controllers/notifications_controller.dart';
import 'package:podium/app/modules/global/controllers/oneSignal_controller.dart';

final globalBindings = [
  Bind.put<GlobalController>(GlobalController(), permanent: true),
  Bind.put<OutpostsController>(OutpostsController(), permanent: true),
  Bind.put<UsersController>(UsersController(), permanent: true),
  Bind.put<OutpostCallController>(OutpostCallController(), permanent: true),
  Bind.put<NotificationsController>(NotificationsController(), permanent: true),
  Bind.put<ReferalController>(ReferalController(), permanent: true),
  Bind.put<RecorderController>(RecorderController(), permanent: true),
  Bind.put<OneSignalController>(OneSignalController(), permanent: true),
];

class GlobalBindings extends Binding {
  @override
  List<Bind> dependencies() => globalBindings;
}
