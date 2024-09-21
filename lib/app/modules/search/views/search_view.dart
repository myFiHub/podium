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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
              height: 60,
              child: Input(
                hintText: "search room / users",
                autofocus: true,
                onChanged: (v) {
                  controller.searchValue.value = v;
                },
              )),
          Container(
            height: Get.height - 185,
            child: DefaultTabController(
              length: 2,
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
                  ],
                ),
              ),
            ),
          ),

          // Obx(() {
          //   final searchedGroups = controller.searchedGroups.value;
          //   List<FirebaseGroup> groupsList = [];
          //   if (searchedGroups != null) {
          //     groupsList = searchedGroups.values.toList();
          //   }
          //   if (groupsList.isEmpty) {
          //     return Container();
          //   }
          //   return Container(
          //       child: Expanded(
          //     child: GroupList(groupsList: groupsList),
          //   ));
          // }),
          // Obx(() {
          //   final usersMap = controller.searchedUsers.value;
          //   List<UserInfoModel> usersList = [];
          //   if (usersMap != null) {
          //     usersList = usersMap.values.toList();
          //   }
          //   if (usersList.isEmpty) {
          //     return Container();
          //   }
          //   return Container(
          //       child: Expanded(
          //     child: UserList(usersList: usersList),
          //   ));
          // }),
          space10,
          space10,
        ],
      ),
    );
  }
}
