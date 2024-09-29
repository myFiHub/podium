import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/models/firebase_group_model.dart';

class HomeController extends GetxController {
  final GroupsController groupsController = Get.find<GroupsController>();
  final groupsImIn = Rx<Map<String, FirebaseGroup>>({});
  final allGroups = Rx<Map<String, FirebaseGroup>>({});
  final searchValue = Rx<String>("");

  @override
  void onInit() async {
    allGroups.value = groupsController.groups.value;
    if (allGroups.value.isNotEmpty) {
      extractMyGroups(allGroups.value);
    }
    groupsController.groups.listen((groups) {
      extractMyGroups(groups);
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

  extractMyGroups(Map<String, FirebaseGroup> groups) {
    final groupsImInMap = groups.entries
        .where((element) => element.value.members.contains(myId))
        .toList();
    final groupsImInMapConverted = Map<String, FirebaseGroup>.fromEntries(
      groupsImInMap,
    );
    groupsImIn.value = groupsImInMapConverted;
    allGroups.value = groups;
  }

  search(String value) {
    searchValue.value = value;
  }
}
