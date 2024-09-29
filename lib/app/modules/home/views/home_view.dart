import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/widgets/groupsList.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/utils/styles.dart';

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
              Tab(
                child: Text("My Rooms"),
              ),
              Tab(
                child: Text("Joined"),
              ),
              Tab(
                child: Text("archived"),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Obx(() {
              final List<FirebaseGroup> createdByMe = controller
                  .groupsImIn.value.values
                  .where((element) => element.creator.id == myId)
                  .toList();
              final notArchived = createdByMe
                  .where((element) => element.archived != true)
                  .toList();

              if (createdByMe.length == 0) {
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

              return Container(
                child: GroupList(groupsList: notArchived),
              );
            }),
            Obx(() {
              final notCreatedByMe = controller.groupsImIn.value.values
                  .where((element) => element.creator.id != myId)
                  .toList();
              if (notCreatedByMe.length == 0) {
                return Container(
                  child: Center(
                    child: Text("You have not joined any rooms yet"),
                  ),
                );
              }
              return Container(
                child: GroupList(groupsList: notCreatedByMe),
              );
            }),
            Obx(() {
              final archived = controller.groupsImIn.value.values
                  .where((element) => element.archived)
                  .toList();
              if (archived.length == 0) {
                return Container(
                  child: Center(
                    child: Text("Your archive is empty"),
                  ),
                );
              }
              return Container(
                child: GroupList(groupsList: archived),
              );
            }),
          ],
        ),
      ),
    );
  }
}
