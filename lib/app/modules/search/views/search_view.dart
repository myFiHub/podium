import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/widgets/outpostsList.dart';
import 'package:podium/app/modules/outpostDetail/widgets/usersList.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/providers/api/podium/models/tag/tag.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/utils/styles.dart';

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
              space10,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Search",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    space5,
                    SizedBox(
                      height: 40,
                      child: Stack(
                        children: [
                          TextField(
                            controller: TextEditingController(
                              text: controller.searchValue.value,
                            ),
                            decoration: InputDecoration(
                              hintText: "Search Outposts, Users or Tags",
                              hintStyle: const TextStyle(fontSize: 14),
                              prefixIcon: const Icon(Icons.search),
                              contentPadding: const EdgeInsets.all(10),
                              filled: true,
                              fillColor: Colors.grey[200],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                            onChanged: (value) {
                              controller.searchValue.value = value;
                            },
                          ),
                          Positioned(
                            right: 20,
                            top: 10,
                            child: Obx(() {
                              final isSearching = controller.isSearching.value;
                              if (isSearching) {
                                return Container(
                                  width: 20,
                                  height: 20,
                                  child: const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        ColorName.pageBgGradientStart),
                                  ),
                                );
                              }
                              return const SizedBox();
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
                            controller.searchedOutposts.value.length ?? 0;
                        if (numberOfGroupsFound == 0) {
                          return const Tab(
                            child: Text("Outposts"),
                          );
                        }
                        return Tab(
                          child: Text("Outposts ($numberOfGroupsFound)"),
                        );
                      }),
                      Obx(() {
                        final numberOfUsersFound =
                            controller.searchedUsers.value.length ?? 0;
                        if (numberOfUsersFound == 0) {
                          return const Tab(text: "Users");
                        }
                        return Tab(text: "Users ($numberOfUsersFound)");
                      }),
                      Obx(() {
                        final numberOfTagsFound =
                            controller.searchedTags.value.length ?? 0;
                        if (numberOfTagsFound == 0) {
                          return const Tab(text: "Tags");
                        }
                        return Tab(text: "Tags ($numberOfTagsFound)");
                      }),
                    ],
                  ),
                ),
                body: TabBarView(
                  children: [
                    Obx(() {
                      final searchedGroups = controller.searchedOutposts.value;
                      List<OutpostModel> outpostsList = [];
                      outpostsList = searchedGroups.values.toList();
                      if (outpostsList.isEmpty) {
                        return Container();
                      }
                      return Container(
                        child: OutpostsList(outpostsList: outpostsList),
                      );
                    }),
                    Obx(() {
                      final usersMap = controller.searchedUsers.value;
                      List<UserModel> usersList = [];
                      usersList = usersMap.values.toList();
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
                      List<TagModel> tagsList = [];
                      tagsList = tagsMap.values.toList();

                      if (tagsList.isEmpty) {
                        return Container();
                      }
                      return ListView.builder(
                        itemCount: tagsList.length,
                        itemBuilder: (context, index) {
                          final tag = tagsList[index];
                          return GestureDetector(
                            key: Key(tag.name),
                            onTap: () {
                              controller.tagClicked(tag);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(tag.name),
                                  space10,
                                  Text('(${tag.outpostIds.length.toString()})'),
                                  if (loadingName == tag.name)
                                    Container(
                                      margin: const EdgeInsets.only(left: 10),
                                      width: 20,
                                      height: 20,
                                      child: const CircularProgressIndicator(
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
