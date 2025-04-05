import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';

class AllOutpostsController extends GetxController {
  final outpostsController = Get.find<OutpostsController>();

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  Future<void> refresh() async {
    await outpostsController.fetchAllOutpostsPage(0);
  }
}
