import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';

class AllOutpostsController extends GetxController {
  final outpostsController = Get.find<OutpostsController>();
  final searchValue = ''.obs;
  final searchedOutposts = Rx<Map<String, OutpostModel>>({});

  @override
  void onInit() {
    super.onInit();
    searchedOutposts.value =
        getOutpostsVisibleToMe(outpostsController.outposts.value, myId);

    outpostsController.outposts.listen((event) {
      search(searchValue.value);
    });
  }

  @override
  void onReady() {
    super.onReady();
  }

  Future<void> refresh() async {
    await outpostsController.getAllOutposts();
    search(searchValue.value);
  }

  @override
  void onClose() {
    super.onClose();
  }

  search(String value) {
    searchValue.value = value;
    // _deb.debounce(() async {
    final filtered = outpostsController.outposts.value.entries.where(
        (element) =>
            element.value.name.toLowerCase().contains(value.toLowerCase()));
    //await searchForGroupByName(value);
    final groups = Map<String, OutpostModel>.fromEntries(filtered);
    // Map<String, FirebaseGroup> searchedGroupsMap = {};
    // if (value.isEmpty) {
    //   searchedGroupsMap = groupsController.groups.value ?? {};
    // } else {
    //   searchedGroupsMap = groups;
    // }
    searchedOutposts.value = getOutpostsVisibleToMe(groups, myId);
    // });
  }

  refreshSearchedGroup(OutpostModel group) {
    if (searchedOutposts.value.containsKey(group.uuid)) {
      searchedOutposts.value[group.uuid] = group;
      searchedOutposts.refresh();
    }
  }
}
