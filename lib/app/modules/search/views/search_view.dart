import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:podium/app/modules/global/widgets/groupsList.dart';
import 'package:podium/app/modules/groupDetail/widgets/usersList.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/models/user_info_model.dart';

import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/textField/textFieldRounded.dart';

import '../controllers/search_controller.dart';

class SearchView extends GetView<SearchPageController> {
  const SearchView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              space16,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Search",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    space10,
                    SizedBox(
                      height: 40,
                      child: Stack(
                        children: [
                          TextField(
                            controller: TextEditingController(
                                text: controller.searchValue.value),
                            decoration: InputDecoration(
                              hintText: "Search rooms, users or tags",
                              hintStyle: TextStyle(fontSize: 14),
                              prefixIcon: Icon(Icons.search),
                              contentPadding: const EdgeInsets.all(16),
                              filled: true,
                              fillColor: Colors.grey[200],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black,
                            ),
                            onChanged: (value) {
                              controller.searchValue.value = value;
                            },
                          ),
                          Positioned(
                            right: 25,
                            top: 20,
                            child: Obx(() {
                              final isSearching = controller.isSearching.value;
                              if (isSearching) {
                                return Container(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        ColorName.pageBgGradientStart),
                                  ),
                                );
                              }
                              return SizedBox();
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Lista de grupos
            ],
          ),
          Container(
            height: Get.height - 205,
            child: DefaultTabController(
              length: 3,
              child: Scaffold(
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  toolbarHeight: 0,
                  bottom: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorColor: ColorName.primaryBlue,
                    labelColor: ColorName.primaryBlue,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Obx(() {
                        final numberOfGroupsFound =
                            controller.searchedGroups.value?.length ?? 0;
                        if (numberOfGroupsFound == 0) {
                          return Tab(
                            child: Text("Groups"),
                          );
                        }
                        return Tab(
                          child: Text("Groups ($numberOfGroupsFound)"),
                        );
                      }),
                      Obx(() {
                        final numberOfUsersFound =
                            controller.searchedUsers.value?.length ?? 0;
                        if (numberOfUsersFound == 0) {
                          return Tab(text: "Users");
                        }
                        return Tab(text: "Users ($numberOfUsersFound)");
                      }),
                      Obx(() {
                        final numberOfTagsFound =
                            controller.searchedTags.value?.length ?? 0;
                        if (numberOfTagsFound == 0) {
                          return Tab(text: "Tags");
                        }
                        return Tab(text: "Tags ($numberOfTagsFound)");
                      }),
                    ],
                  ),
                ),
                body: TabBarView(
                  children: [
                    Obx(() {
                      final searchedGroups = controller.searchedGroups.value;
                      List<FirebaseGroup> groupsList = [];
                      if (searchedGroups != null) {
                        groupsList = searchedGroups.values.toList();
                      }
                      if (groupsList.isEmpty) {
                        return Container();
                      }
                      return Container(
                        child: GroupList(groupsList: groupsList),
                      );
                    }),
                    Obx(() {
                      final usersMap = controller.searchedUsers.value;
                      List<UserInfoModel> usersList = [];
                      if (usersMap != null) {
                        usersList = usersMap.values.toList();
                      }
                      if (usersList.isEmpty) {
                        return Container();
                      }
                      return Container(
                        child: UserList(usersList: usersList),
                      );
                    }),
                    Obx(() {
                      final tagsMap = controller.searchedTags.value;
                      final loadingName = controller.loadingTag_name.value;
                      List<Tag> tagsList = [];
                      tagsList = tagsMap.values.toList();

                      if (tagsList.isEmpty) {
                        return Container();
                      }
                      return ListView.builder(
                        itemCount: tagsList.length,
                        itemBuilder: (context, index) {
                          final tag = tagsList[index];
                          return GestureDetector(
                            key: Key(tag.tagName),
                            onTap: () {
                              controller.tagClicked(tag);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(tag.tagName),
                                  space10,
                                  Text('(${tag.groupIds!.length.toString()})'),
                                  if (loadingName == tag.tagName)
                                    Container(
                                      margin: const EdgeInsets.only(left: 10),
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                ColorName.primaryBlue),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
