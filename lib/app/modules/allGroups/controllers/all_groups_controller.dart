import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/utils/throttleAndDebounce/debounce.dart';

final _deb = Debouncing(duration: const Duration(seconds: 1));

class AllGroupsController extends GetxController with FireBaseUtils {
  final groupsController = Get.find<GroupsController>();
  final searchValue = ''.obs;
  final searchedGroups = Rxn<Map<String, FirebaseGroup>>({});

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

  search(String value) {
    searchValue.value = value;
    _deb.debounce(() async {
      final groups = await searchForGroupByName(value);
      Map<String, FirebaseGroup> searchedGroupsMap = {};
      if (value.isEmpty) {
        searchedGroupsMap = groupsController.groups.value ?? {};
      } else {
        searchedGroupsMap = groups;
      }
      final myId = groupsController.globalController.currentUserInfo.value!.id;
      searchedGroups.value = getGroupsVisibleToMe(searchedGroupsMap, myId);
    });
  }
}
