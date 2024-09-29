import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/models/firebase_group_model.dart';

class HomeController extends GetxController {
  final GroupsController groupsController = Get.find<GroupsController>();
  final groupsImIn = Rx<Map<String, FirebaseGroup>>({});

  @override
  void onInit() async {
    groupsController.groups.listen((groups) {
      if (groups != null) {
        final groupsImInMap = groups.entries
            .where((element) => element.value.members.contains(myId))
            .toList();
        final groupsImInMapConverted = Map<String, FirebaseGroup>.fromEntries(
          groupsImInMap,
        );
        groupsImIn.value = groupsImInMapConverted;
      }
    });
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
}
