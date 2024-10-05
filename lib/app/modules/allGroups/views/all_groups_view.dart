import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/widgets/groupsList.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:podium/widgets/textField/textFieldRounded.dart';

import '../controllers/all_groups_controller.dart';

class AllGroupsView extends GetView<AllGroupsController> {
  const AllGroupsView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.refresh();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              "All Rooms",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(
              height: 70,
              child: Input(
                hintText: "search a room",
                initialValue: controller.searchValue.value,
                autofocus: false,
                onChanged: (v) {
                  controller.search(v);
                },
              ),
            ),
            Expanded(
              child: Container(
                child: AllGroupsList(),
              ),
            ),
            Button(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Create Room'),
                    const SizedBox(width: 10),
                    const Icon(Icons.add, color: Colors.white, size: 24),
                  ],
                ),
                shape: ButtonShape.pills,
                type: ButtonType.gradient,
                onPressed: () {
                  Navigate.to(
                    type: NavigationTypes.toNamed,
                    route: Routes.CREATE_GROUP,
                  );
                }),
            space10,
            space10,
          ],
        ),
      ),
    );
  }
}

class AllGroupsList extends GetWidget<AllGroupsController> {
  const AllGroupsList({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<GlobalController>(
        id: GlobalUpdateIds.showArchivedGroups,
        builder: (globalController) {
          return Obx(() {
            final groups = controller.searchedGroups.value;
            final showArchived = globalController.showArchivedGroups.value;
            // final groupsController = Get.find<GroupsController>();
            List<FirebaseGroup> groupsList =
                // ignore: unnecessary_null_comparison
                groups != null ? groups.values.toList() : [];
            // if (groupsList.isEmpty && groupsController.groups.value != null) {
            //   groupsList = groupsController.groups.value!.values.toList();
            // }
            if (!showArchived) {
              groupsList =
                  groupsList.where((group) => group.archived != true).toList();
            }
            return GroupList(
              groupsList: groupsList,
            );
          });
        });
  }
}
