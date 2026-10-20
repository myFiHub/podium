import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/allOutposts/views/tag_outposts_view.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/data/repositories/repositories.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/providers/api/podium/models/tag/tag.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/utils/throttleAndDebounce/debounce.dart';

final _deb = Debouncing(duration: const Duration(milliseconds: 600));

class SearchPageController extends GetxController {
  final _outpostRepository = Get.find<OutpostRepository>();
  final _userRepository = Get.find<UserRepository>();
  final groupsController = Get.find<OutpostsController>();
  final GlobalController globalController = Get.find<GlobalController>();
  final searchValue = ''.obs;
  final searchedOutposts = Rx<Map<String, OutpostModel>>({});
  final searchedUsers = Rx<Map<String, UserModel>>({});
  final searchedTags = Rx<Map<String, TagModel>>({});
  final loadingTag_name = ''.obs;
  final selectedSearchTab = 0.obs;
  final isSearching = false.obs;
  StreamSubscription<String>? searchValueListener;
  final textFieldController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    searchValueListener = searchValue.listen((value) async {
      textFieldController.text = value;
      // move the cursor to the end of the text field if it's at the start. because a bug happened on Majid's phone
      if (textFieldController.selection.start == 0) {
        textFieldController.selection = TextSelection.fromPosition(
          TextPosition(offset: value.length),
        );
      }
      isSearching.value = true;
      if (value.isEmpty || value.length < 3) {
        searchedTags.value = {};
        searchedOutposts.value = {};
        searchedUsers.value = {};
        isSearching.value = false;
        return;
      }
      _deb.debounce(() async {
        if (searchValue.value.isEmpty) {
          searchedTags.value = {};
          searchedOutposts.value = {};
          searchedUsers.value = {};
          isSearching.value = false;
          return;
        }

        final [outposts, users, tags] = await Future.wait([
          _outpostRepository.searchOutpostByName(name: value),
          _userRepository.searchUserByName(name: value),
          _outpostRepository.searchTag(tagName: value),
        ]);
        searchedOutposts.value = outposts as Map<String, OutpostModel>;
        searchedUsers.value = users as Map<String, UserModel>;
        searchedTags.value = tags as Map<String, TagModel>;
        isSearching.value = false;
      });
    });
  }

  @override
  void onClose() {
    searchValueListener?.cancel();
    super.onClose();
  }

  void setSeachValue(String value) {
    searchValue.value = value;
    textFieldController.text = value;
  }

  void updateOutpost_local(OutpostModel outpost) {
    final outpostIndex = searchedOutposts.value.values
        .toList()
        .indexWhere((element) => element.uuid == outpost.uuid);
    if (outpostIndex != -1) {
      searchedOutposts.value[outpost.uuid] = outpost;
      searchedOutposts.refresh();
    }
  }

  Future<void> updateUserFollow(String id) async {
    final user = searchedUsers.value[id];
    if (user != null) {
      final opposite =
          user.followed_by_me != null ? !user.followed_by_me! : true;
      searchedUsers.value[id] = user.copyWith.followed_by_me(opposite);
      searchedUsers.refresh();
    }
  }

  Future<Map<String, OutpostModel>> filterOutpostName(String name) async {
    final allOutposts = groupsController.outposts.value;
    final filteredOutposts = allOutposts.entries
        .where((element) =>
            element.value.name.toLowerCase().contains(name.toLowerCase()))
        .toList();
    final filteredOutpostsMap = Map<String, OutpostModel>.fromEntries(
      filteredOutposts,
    );
    return filteredOutpostsMap;
  }

  Future<void> searchOutpost(String v) async {
    if (v.isEmpty) {
      searchedOutposts.value = {};
      return;
    }
    final foundOutposts = await filterOutpostName(v);
    searchedOutposts.value = foundOutposts;
  }

  void tagClicked(TagModel tag) {
    openTagOutposts(id: tag.id, name: tag.name);
  }

  Future<void> searchUser(String v) async {
    if (v.isEmpty) {
      searchedUsers.value = {};
      return;
    }
    final foundUsers = await _userRepository.searchUserByName(name: v);
    searchedUsers.value = foundUsers;
  }

  void refreshSearchedGroup(OutpostModel group) {
    if (searchedOutposts.value.isEmpty) {
      return;
    }
    final currentGroups = searchedOutposts.value;
    if (currentGroups.containsKey(group.uuid)) {
      currentGroups[group.uuid] = group;
      searchedOutposts.value = currentGroups;
      searchedOutposts.refresh();
    }
  }
}
