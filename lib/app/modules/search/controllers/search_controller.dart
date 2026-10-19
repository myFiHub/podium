import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/widgets/outpostsList.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/providers/api/podium/models/tag/tag.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/root.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/throttleAndDebounce/debounce.dart';
import 'package:podium/widgets/ui/app_ui.dart';

final _deb = Debouncing(duration: const Duration(milliseconds: 600));

class SearchPageController extends GetxController {
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
          HttpApis.podium.searchOutpostByName(name: value),
          HttpApis.podium.searchUserByName(name: value),
          HttpApis.podium.searchTag(tagName: value),
        ]);
        searchedOutposts.value = outposts as Map<String, OutpostModel>;
        searchedUsers.value = users as Map<String, UserModel>;
        searchedTags.value = tags as Map<String, TagModel>;
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
    searchValueListener?.cancel();
    super.onClose();
  }

  setSeachValue(String value) {
    searchValue.value = value;
    textFieldController.text = value;
  }

  updateOutpost_local(OutpostModel outpost) {
    final outpostIndex = searchedOutposts.value.values
        .toList()
        .indexWhere((element) => element.uuid == outpost.uuid);
    if (outpostIndex != -1) {
      searchedOutposts.value[outpost.uuid] = outpost;
      searchedOutposts.refresh();
    }
  }

  updateUserFollow(String id) async {
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

  searchOutpost(String v) async {
    if (v.isEmpty) {
      searchedOutposts.value = {};
      return;
    }
    final foundOutposts = await filterOutpostName(v);
    searchedOutposts.value = foundOutposts;
  }

  tagClicked(TagModel tag) async {
    loadingTag_name.value = tag.name;
    final foundOutposts = await HttpApis.podium.getOutpostsByTagId(id: tag.id);
    if (foundOutposts.isEmpty) {
      l.e('No groups found for tag: ${tag.name}');
      return;
    } else {
      final parsedOutposts = foundOutposts.values.toList();

      Get.dialog(
        Scaffold(
          body: PageWrapper(
            child: SafeArea(
              child: Column(
                children: [
                  AppPageHeader(
                    title: '#${tag.name}',
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                    actions: [
                      AppIconButton(
                        icon: Icons.close_rounded,
                        tooltip: 'Close',
                        onTap: Get.close,
                      ),
                    ],
                  ),
                  Expanded(
                    child: OutpostsList(
                      outpostsList: parsedOutposts,
                      listPage: ListPage.search,
                    ),
                  ),
                ],
              ),
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
    final foundUsers = await HttpApis.podium.searchUserByName(name: v);
    searchedUsers.value = foundUsers;
  }

  refreshSearchedGroup(OutpostModel group) {
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
