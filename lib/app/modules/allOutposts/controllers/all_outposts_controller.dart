import 'package:get/get.dart';
import 'package:podium/app/modules/allOutposts/controllers/discover_controller.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';

class AllOutpostsController extends GetxController {
  final outpostsController = Get.find<OutpostsController>();

  @override
  void onInit() {
    super.onInit();
  }

  @override
  Future<void> refresh() async {
    await Future.wait([
      outpostsController.fetchAllOutpostsPage(0),
      Get.find<DiscoverController>().refreshAll(),
    ]);
  }
}
