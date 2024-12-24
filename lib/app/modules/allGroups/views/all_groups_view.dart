import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hidable/hidable.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/widgets/groupsList.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';

import '../controllers/all_groups_controller.dart';

final _scrollController = ScrollController();

class AllGroupsView extends GetView<AllGroupsController> {
  const AllGroupsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await controller.refresh();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                space16,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "All Outposts",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      space10,
                      SizedBox(
                        height: 40,
                        child: TextField(
                          controller: TextEditingController(
                              text: controller.searchValue.value),
                          decoration: InputDecoration(
                            hintText: "What are we looking for?",
                            hintStyle: const TextStyle(fontSize: 14),
                            prefixIcon: const Icon(Icons.search),
                            contentPadding: const EdgeInsets.all(16),
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                          ),
                          onChanged: (value) {
                            controller.search(value);
                          },
                        ),
                      ),
                      space10,
                    ],
                  ),
                ),
                // Lista de grupos
                Expanded(
                  child: Container(
                    child: AllGroupsList(
                      scrollController: _scrollController,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 10,
            left: MediaQuery.of(context).size.width / 2 - 100,
            child: Hidable(
              controller: _scrollController,
              enableOpacityAnimation: true,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.green],
                  ),
                ),
                child: Button(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 16),
                      SizedBox(width: 10),
                      Text(
                        "Start new outpost",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  type: ButtonType.gradient,
                  onPressed: () {
                    Navigate.to(
                      type: NavigationTypes.toNamed,
                      route: Routes.CREATE_GROUP,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AllGroupsList extends GetWidget<AllGroupsController> {
  final ScrollController scrollController;
  const AllGroupsList({
    super.key,
    required this.scrollController,
  });

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
              scrollController: scrollController,
              groupsList: groupsList,
            );
          });
        });
  }
}
