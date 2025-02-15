import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/mixins/firbase_tags.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/widgets/outpostsList.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/providers/api/podium/models/tag/tag.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/throttleAndDebounce/debounce.dart';

final _deb = Debouncing(duration: const Duration(seconds: 1));

class SearchPageController extends GetxController with FirebaseTags {
  final groupsController = Get.find<OutpostsController>();
  final GlobalController globalController = Get.find<GlobalController>();
  final searchValue = ''.obs;
  final searchedOutposts = Rx<Map<String, OutpostModel>>({});
  final searchedUsers = Rx<Map<String, UserModel>>({});
  final searchedTags = Rx<Map<String, TagModel>>({});
  final loadingTag_name = ''.obs;
  final selectedSearchTab = 0.obs;
  final isSearching = false.obs;

  @override
  void onInit() {
    super.onInit();
    searchValue.listen((value) async {
      isSearching.value = true;
      if (value.isEmpty) {
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
    super.onClose();
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
                          '#${tag.name}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: Get.close,
                      ),
                    ],
                  ),
                ),
                Container(
                  height: Get.height - 220,
                  color: ColorName.pageBackground,
                  child: OutpostsList(outpostsList: parsedOutposts),
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
