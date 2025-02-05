import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';

class HomeController extends GetxController {
  final OutpostsController outpostsController = Get.find<OutpostsController>();
  final globalController = Get.find<GlobalController>();
  final outpostsImIn = Rx<Map<String, OutpostModel>>({});
  final allOutposts = Rx<Map<String, OutpostModel>>({});
  final showArchived = false.obs;

  @override
  void onInit() async {
    super.onInit();
    allOutposts.value = outpostsController.outposts.value;
    showArchived.value = globalController.showArchivedGroups.value;
    if (allOutposts.value.isNotEmpty) {
      extractMyOutposts(allOutposts.value);
    }
    outpostsController.outposts.listen((groups) {
      extractMyOutposts(groups);
    });
    globalController.showArchivedGroups.listen((value) {
      showArchived.value = value;
    });
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  extractMyOutposts(Map<String, OutpostModel> outposts) {
    final outpostsImInMap =
        outposts.entries.where((element) => element.value.iAmMember).toList();
    final outpostsImInMapConverted = Map<String, OutpostModel>.fromEntries(
      outpostsImInMap,
    );
    outpostsImIn.value = outpostsImInMapConverted;
    allOutposts.value = outposts;
  }
}
