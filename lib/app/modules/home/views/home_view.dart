import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/widgets/groupsList.dart';
import 'package:podium/app/modules/home/widgets/addOutpostButton.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/constants/constantKeys.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/models/metadata/movementAptos.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:shimmer/shimmer.dart';

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
          // Button(
          //   text: 'test',
          //   onPressed: () async {
          //     // final referralEnabledRef = FirebaseDatabase.instance
          //     //     .ref(FireBaseConstants.referralsEnabled);
          //     // await referralEnabledRef.set(false);
          //   },
          // ),
          space16,
          Row(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: const Text(
                  "Home",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: AddOutpostButton(),
              ),
            ],
          ),
          space14,
          const Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: const Text(
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
                              (group) => group.members.keys.contains(myId),
                            )
                            .toList();

                        if (!showArchived) {
                          groups = groups
                              .where((group) => group.archived != true)
                              .toList();
                        }
                        if (isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (groups.isEmpty) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  height: 200,
                                  child: Assets.images.explore.image(),
                                ),
                                Text(
                                  "Hi ${myUser.name},",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Text(
                                  "You haven't participated yet. Try joining an outpost and enjoy! ✨",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14.0,
                                  ),
                                ),
                                space10,
                                GestureDetector(
                                  onTap: () {
                                    Navigate.to(
                                      type: NavigationTypes.offAllNamed,
                                      route: Routes.ALL_GROUPS,
                                    );
                                  },
                                  child: Shimmer.fromColors(
                                    baseColor: Colors.white,
                                    highlightColor: ColorName.primaryBlue,
                                    child: const Text(
                                      "Explore Outposts >",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
