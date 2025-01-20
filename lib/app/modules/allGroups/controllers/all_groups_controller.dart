import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';

class AllGroupsController extends GetxController {
  final groupsController = Get.find<OutpostsController>();
  final searchValue = ''.obs;
  final searchedGroups = Rx<Map<String, OutpostModel>>({});

  @override
  void onInit() {
    super.onInit();
    searchedGroups.value =
        getGroupsVisibleToMe(groupsController.groups.value, myId);
    groupsController.groups.listen((event) {
      search(searchValue.value);
    });
  }

  @override
  void onReady() {
    super.onReady();
  }

  Future<void> refresh() async {
    await groupsController.getAllGroups();
    search(searchValue.value);
  }

  @override
  void onClose() {
    super.onClose();
  }

  search(String value) {
    searchValue.value = value;
    // _deb.debounce(() async {
    final filtered = groupsController.groups.value.entries.where((element) =>
        element.value.name.toLowerCase().contains(value.toLowerCase()));
    //await searchForGroupByName(value);
    final groups = Map<String, OutpostModel>.fromEntries(filtered);
    // Map<String, FirebaseGroup> searchedGroupsMap = {};
    // if (value.isEmpty) {
    //   searchedGroupsMap = groupsController.groups.value ?? {};
    // } else {
    //   searchedGroupsMap = groups;
    // }
    searchedGroups.value = getGroupsVisibleToMe(groups, myId);
    // });
  }

  refreshSearchedGroup(OutpostModel group) {
    if (searchedGroups.value.containsKey(group.uuid)) {
      searchedGroups.value[group.uuid] = group;
      searchedGroups.refresh();
    }
  }
}
