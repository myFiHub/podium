import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/widgets/groupsList.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:podium/widgets/textField/textFieldRounded.dart';

import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
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
                final seachValue = controller.searchValue.value;
                final myGroups = controller.groupsImIn.value.values
                    .where((element) => element.creator.id == myId)
                    .toList();
                final notArchived = myGroups
                    .where((element) => element.archived != true)
                    .toList();
                final notArchivedAndSearched = notArchived
                    .where((element) => element.name
                        .toLowerCase()
                        .contains(seachValue.toLowerCase()))
                    .toList();
                return Tab(
                    child: Row(
                  children: [
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                        "Created ${notArchivedAndSearched.length > 0 ? "(${notArchivedAndSearched.length})" : ""}"),
                  ],
                ));
              }),
              Obx(() {
                final notCreatedByMe = controller.groupsImIn.value.values
                    .where((element) => element.creator.id != myId)
                    .toList();
                final searchValue = controller.searchValue.value;
                final searchedGroups = notCreatedByMe
                    .where((element) => element.name
                        .toLowerCase()
                        .contains(searchValue.toLowerCase()))
                    .toList();
                return Tab(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                          "Joined ${searchedGroups.length > 0 ? "(${searchedGroups.length})" : ""}"),
                    ],
                  ),
                );
              }),
              Obx(() {
                final archived = controller.groupsImIn.value.values
                    .where((element) => element.archived)
                    .toList();
                final searchValue = controller.searchValue.value;
                final searchedGroups = archived
                    .where((element) => element.name
                        .toLowerCase()
                        .contains(searchValue.toLowerCase()))
                    .toList();
                return Tab(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        "Archive ${searchedGroups.length > 0 ? "(${searchedGroups.length})" : ""}",
                        textAlign: TextAlign.start,
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        body: Column(
          children: [
            SearchInput(),
            Expanded(
              child: TabBarView(
                children: [
                  Obx(() {
                    final seachValue = controller.searchValue.value;
                    final groupsImIn = controller.groupsImIn.value;
                    final myGroups = controller.groupsImIn.value.values
                        .where((element) => element.creator.id == myId)
                        .toList();
                    final notArchived = myGroups
                        .where((element) => element.archived != true)
                        .toList();
                    final notArchivedAndSearched = notArchived
                        .where((element) => element.name
                            .toLowerCase()
                            .contains(seachValue.toLowerCase()))
                        .toList();
                    final allGroups =
                        controller.allGroups.value.values.toList();
                    if (allGroups.length == 0) {
                      return Container(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (groupsImIn.isEmpty) {
                      return Container(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                  "You have not joined, or created any rooms yet"),
                              space10,
                              Button(
                                type: ButtonType.gradient,
                                blockButton: true,
                                onPressed: () {
                                  Navigate.to(
                                    type: NavigationTypes.offAllNamed,
                                    route: Routes.ALL_GROUPS,
                                  );
                                },
                                child: Text("See all rooms"),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (myGroups.length == 0) {
                      return Container(
                        child: Center(
                          child: Text("You have not created any rooms yet"),
                        ),
                      );
                    }
                    if (notArchived.length == 0) {
                      return Container(
                        child: Center(
                          child: Text("All your rooms are archived"),
                        ),
                      );
                    }
                    if (seachValue.isNotEmpty &&
                        notArchivedAndSearched.length == 0) {
                      return Container(
                        child: Center(
                          child: Text("not found!"),
                        ),
                      );
                    }

                    return Container(
                      child: GroupList(groupsList: notArchivedAndSearched),
                    );
                  }),
                  Obx(() {
                    final notCreatedByMe = controller.groupsImIn.value.values
                        .where((element) => element.creator.id != myId)
                        .toList();
                    final searchValue = controller.searchValue.value;
                    if (notCreatedByMe.length == 0) {
                      return Container(
                        child: Center(
                          child: Text("You have not joined any rooms yet"),
                        ),
                      );
                    }
                    final searchedGroups = notCreatedByMe
                        .where((element) => element.name
                            .toLowerCase()
                            .contains(searchValue.toLowerCase()))
                        .toList();
                    if (searchValue.isNotEmpty && searchedGroups.length == 0) {
                      return Container(
                        child: Center(
                          child: Text("not found!"),
                        ),
                      );
                    }
                    return Container(
                      child: GroupList(groupsList: searchedGroups),
                    );
                  }),
                  Obx(() {
                    final archived = controller.groupsImIn.value.values
                        .where((element) => element.archived == true)
                        .toList();
                    final searchValue = controller.searchValue.value;
                    if (archived.length == 0) {
                      return Container(
                        child: Center(
                          child: Text("Your archive is empty"),
                        ),
                      );
                    }
                    final searchedGroups = archived
                        .where((element) => element.name
                            .toLowerCase()
                            .contains(searchValue.toLowerCase()))
                        .toList();
                    if (searchValue.isNotEmpty && searchedGroups.length == 0) {
                      return Container(
                        child: Center(
                          child: Text("not found!"),
                        ),
                      );
                    }
                    return Container(
                      child: GroupList(groupsList: searchedGroups),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchInput extends GetWidget<HomeController> {
  const SearchInput({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Input(
          hintText: "search among your created/joined rooms",
          onChanged: controller.search),
      height: 60,
    );
  }
}
