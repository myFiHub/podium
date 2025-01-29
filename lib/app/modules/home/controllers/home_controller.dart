import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/models/firebase_group_model.dart';

class HomeController extends GetxController {
  final OutpostsController groupsController = Get.find<OutpostsController>();
  final globalController = Get.find<GlobalController>();
  final groupsImIn = Rx<Map<String, FirebaseGroup>>({});
  final allGroups = Rx<Map<String, FirebaseGroup>>({});
  final showArchived = false.obs;

  @override
  void onInit() async {
    super.onInit();
    allGroups.value = groupsController.groups.value;
    showArchived.value = globalController.showArchivedGroups.value;
    if (allGroups.value.isNotEmpty) {
      extractMyGroups(allGroups.value);
    }
    groupsController.groups.listen((groups) {
      extractMyGroups(groups);
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

  extractMyGroups(Map<String, FirebaseGroup> groups) {
    final groupsImInMap = groups.entries
        .where((element) => element.value.members.keys.contains(myId))
        .toList();
    final groupsImInMapConverted = Map<String, FirebaseGroup>.fromEntries(
      groupsImInMap,
    );
    groupsImIn.value = groupsImInMapConverted;
    allGroups.value = groups;
  }
}
