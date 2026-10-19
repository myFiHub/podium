import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/widgets/outpostsList.dart';
import 'package:podium/app/modules/home/widgets/addOutpostButton.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/root.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/widgets/ui/app_ui.dart';

import '../controllers/home_controller.dart';

final _scrollController = ScrollController();

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageWrapper(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const AppPageHeader(
              title: "Home",
              padding: EdgeInsets.fromLTRB(20, 16, 16, 4),
              actions: [AddOutpostButton()],
            ),
            AppSectionHeader(
              title: "My Outposts",
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
              trailing: AppIconButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Refresh',
                size: 34,
                onTap: () {
                  controller.refreshOutposts();
                },
              ),
            ),
            const Expanded(
              child: _MyOutpostsList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyOutpostsList extends GetWidget<OutpostsController> {
  const _MyOutpostsList();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final myOutposts = controller.myOutposts.value;
        final isGettingMyOutposts = controller.isGettingMyOutposts.value;
        List<OutpostModel> outposts = myOutposts.values.toList();
        if (outposts.isEmpty && isGettingMyOutposts) {
          return ListView.builder(
            padding: const EdgeInsets.only(top: 4),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) => const OutpostCardSkeleton(),
          );
        }

        if (outposts.isEmpty) {
          return const _MyOutpostsEmpty();
        }
        return OutpostsList(
          scrollController: _scrollController,
          listPage: ListPage.my,
        );
      },
    );
  }
}

class _MyOutpostsEmpty extends StatelessWidget {
  const _MyOutpostsEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: AppCard(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 150,
                child: Assets.images.explore.image(),
              ),
              const SizedBox(height: 16),
              Text(
                "Hi ${myUser.name},",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppText.title,
              ),
              const SizedBox(height: 6),
              Text(
                "You haven't participated yet. Try joining an outpost and enjoy! ✨",
                textAlign: TextAlign.center,
                style: AppText.muted.copyWith(height: 1.45),
              ),
              const SizedBox(height: 20),
              AppPrimaryButton(
                label: "Explore Outposts",
                icon: Icons.explore_rounded,
                onPressed: () {
                  Navigate.to(
                    type: NavigationTypes.offAllNamed,
                    route: Routes.ALL_OUTPOSTS,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
