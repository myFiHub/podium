import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/throttleAndDebounce/debounce.dart';

final _deb = Debouncing(duration: const Duration(seconds: 1));

class SearchPageController extends GetxController with FireBaseUtils {
  final groupsController = Get.find<GroupsController>();
  final searchValue = ''.obs;
  final searchedGroups = Rx<Map<String, FirebaseGroup>>({});
  final searchedUsers = Rx<Map<String, UserInfoModel>>({});
  final selectedSearchTab = 0.obs;

  @override
  void onInit() {
    super.onInit();
    searchValue.listen((value) async {
      _deb.debounce(() async {
        final [groups, users] = await Future.wait([
          searchForGroupByName(value),
          searchForUserByName(value),
        ]);
        if (value.isEmpty) {
          searchedGroups.value = {};
          searchedUsers.value = {};
        } else {
          searchedGroups.value = groups as Map<String, FirebaseGroup>;
          searchedUsers.value = users as Map<String, UserInfoModel>;
        }
      });
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

  searchGroup(String v) async {
    if (v.isEmpty) {
      searchedGroups.value = {};
      return;
    }
    final foundGroups = await searchForGroupByName(v);
    searchedGroups.value = foundGroups;
  }

  searchUser(String v) async {
    if (v.isEmpty) {
      searchedUsers.value = {};
      return;
    }
    final foundUsers = await searchForUserByName(v);
    searchedUsers.value = foundUsers;
  }

  refreshSearchedGroup(FirebaseGroup group) {
    if (searchedGroups.value.isEmpty) {
      return;
    }
    final currentGroups = searchedGroups.value;
    if (currentGroups.containsKey(group.id)) {
      currentGroups[group.id] = group;
      searchedGroups.value = currentGroups;
      searchedGroups.refresh();
    }
  }
}
