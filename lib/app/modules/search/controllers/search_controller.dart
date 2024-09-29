import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/mixins/firbase_tags.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/widgets/groupsList.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/throttleAndDebounce/debounce.dart';

final _deb = Debouncing(duration: const Duration(seconds: 1));

class SearchPageController extends GetxController
    with FireBaseUtils, FirebaseTags {
  final groupsController = Get.find<GroupsController>();
  final searchValue = ''.obs;
  final searchedGroups = Rx<Map<String, FirebaseGroup>>({});
  final searchedUsers = Rx<Map<String, UserInfoModel>>({});
  final searchedTags = Rx<Map<String, Tag>>({});
  final loadingTag_name = ''.obs;
  final selectedSearchTab = 0.obs;
  final isSearching = false.obs;

  @override
  void onInit() {
    super.onInit();
    searchValue.listen((value) async {
      if (value.isEmpty) {
        searchedTags.value = {};
        searchedGroups.value = {};
        searchedUsers.value = {};
        isSearching.value = false;
        return;
      }
      final Map<String, FirebaseGroup> groups = await filterGroupName(value);
      searchedGroups.value = groups;
      isSearching.value = true;
      _deb.debounce(() async {
        if (searchValue.value.isEmpty) {
          searchedTags.value = {};
          searchedGroups.value = {};
          searchedUsers.value = {};
          isSearching.value = false;
          return;
        }

        final [users, tags] = await Future.wait([
          // searchForGroupByName(value),
          searchForUserByName(value),
          searchTags(value)
        ]);
        searchedUsers.value = users as Map<String, UserInfoModel>;
        searchedTags.value = tags as Map<String, Tag>;
        isSearching.value = false;
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

  Future<Map<String, FirebaseGroup>> filterGroupName(String name) async {
    final allGroups = groupsController.groups.value;
    final filteredGroups = allGroups.entries
        .where((element) =>
            element.value.name.toLowerCase().contains(name.toLowerCase()))
        .toList();
    final filteredGroupsMap = Map<String, FirebaseGroup>.fromEntries(
      filteredGroups,
    );
    return filteredGroupsMap;
  }

  searchGroup(String v) async {
    if (v.isEmpty) {
      searchedGroups.value = {};
      return;
    }
    final foundGroups = await searchForGroupByName(v);
    searchedGroups.value = foundGroups;
  }

  tagClicked(Tag tag) async {
    final groupIds = tag.groupIds;
    loadingTag_name.value = tag.tagName;
    if (groupIds == null) {
      return;
    }
    final foundGroups =
        await Future.wait(groupIds.map((e) => getGroupInfoById(e)));
    if (foundGroups.isEmpty) {
      log.e('No groups found for tag: ${tag.tagName}');
      return;
    } else {
      final parsedGroups = foundGroups
          .where((element) => element != null)
          .toList()
          .cast<FirebaseGroup>();
      Get.dialog(
        SafeArea(
          child: Scaffold(
            backgroundColor: ColorName.pageBackground,
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: Get.width - 100,
                        child: Text(
                          '#${tag.tagName}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: Get.close,
                      ),
                    ],
                  ),
                ),
                Container(
                  height: Get.height - 150,
                  color: ColorName.pageBackground,
                  child: GroupList(groupsList: parsedGroups),
                ),
              ],
            ),
          ),
        ),
      );
    }
    loadingTag_name.value = '';
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
