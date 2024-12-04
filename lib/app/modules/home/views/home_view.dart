import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/widgets/groupsList.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';

import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          space16,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Home",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          space14,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "My Outposts",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          space10,
          Expanded(
            child: Container(
              width: Get.width,
              child: GetBuilder<GlobalController>(
                  id: GlobalUpdateIds.showArchivedGroups,
                  builder: (globalController) {
                    return Obx(
                      () {
                        final showArchived =
                            globalController.showArchivedGroups.value;
                        final allGroups = controller.allGroups.value;
                        final isLoading = allGroups.isEmpty;
                        List<FirebaseGroup> groups = allGroups.values
                            .where(
                              (group) => group.members.contains(myId),
                            )
                            .toList();

                        if (!showArchived) {
                          groups = groups
                              .where((group) => group.archived != true)
                              .toList();
                        }
                        if (isLoading) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (groups.isEmpty) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Hero(
                                tag: 'logo',
                                child: Container(
                                  height: 100,
                                  child: Assets.images.logo.image(),
                                ),
                              ),
                              Text(
                                'Welcome to Podium',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                myUser.fullName,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'try joining an Outpost',
                              ),
                              space10,
                              Button(
                                  text: 'See All Outposts',
                                  type: ButtonType.gradient,
                                  blockButton: true,
                                  onPressed: () async {
                                    Navigate.to(
                                      type: NavigationTypes.offAllNamed,
                                      route: Routes.ALL_GROUPS,
                                    );
                                  })
                            ],
                          );
                        }
                        return GroupList(groupsList: groups);
                      },
                    );
                  }),
            ),
          ),
        ],
      ),
    );
  }
}
