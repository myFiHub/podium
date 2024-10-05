import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/utils/throttleAndDebounce/debounce.dart';

final _deb = Debouncing(duration: const Duration(seconds: 1));

class AllGroupsController extends GetxController with FireBaseUtils {
  final groupsController = Get.find<GroupsController>();
  final searchValue = ''.obs;
  final searchedGroups = Rx<Map<String, FirebaseGroup>>({});

  @override
  void onInit() {
    searchedGroups.value =
        getGroupsVisibleToMe(groupsController.groups.value, myId);
    groupsController.groups.listen((event) {
      search(searchValue.value);
    });
    super.onInit();
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
    final groups = Map<String, FirebaseGroup>.fromEntries(filtered);
    // Map<String, FirebaseGroup> searchedGroupsMap = {};
    // if (value.isEmpty) {
    //   searchedGroupsMap = groupsController.groups.value ?? {};
    // } else {
    //   searchedGroupsMap = groups;
    // }
    searchedGroups.value = getGroupsVisibleToMe(groups, myId);
    // });
  }

  refreshSearchedGroup(FirebaseGroup group) {
    if (searchedGroups.value.containsKey(group.id)) {
      searchedGroups.value[group.id] = group;
      searchedGroups.refresh();
    }
  }
}
