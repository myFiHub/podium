import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/widgets/outpostsList.dart';
import 'package:podium/app/modules/home/widgets/addOutpostButton.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/root.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/styles.dart';
import 'package:shimmer/shimmer.dart';

import '../controllers/home_controller.dart';

final _scrollController = ScrollController();

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageWrapper(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Button(
            //   text: 'test',
            //   onPressed: () async {
            //     //
            //   },
            // ),
            space16,
            const Row(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    "Home",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Spacer(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
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
                child: const _MyOutpostsList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyOutpostsList extends GetWidget<OutpostsController> {
  const _MyOutpostsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final myOutposts = controller.myOutposts.value;
        final isGettingMyOutposts = controller.isGettingMyOutposts.value;
        List<OutpostModel> outposts = myOutposts.values.toList();
        if (outposts.isEmpty && isGettingMyOutposts) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (outposts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                      route: Routes.ALL_OUTPOSTS,
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
        return OutpostsList(
          scrollController: _scrollController,
          listPage: ListPage.my,
        );
      },
    );
  }
}
