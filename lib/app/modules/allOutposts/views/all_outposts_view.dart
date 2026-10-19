import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/widgets/outpostsList.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/root.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/widgets/ui/app_ui.dart';

import '../controllers/all_outposts_controller.dart';

final _scrollController = ScrollController();
// listen to scroll controller to show or hide the bottom button

class AllOutpostsView extends GetView<AllOutpostsController> {
  const AllOutpostsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageWrapper(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppPageHeader(
                  title: "All Outposts",
                  subtitle: "Live and upcoming conversations",
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                  actions: [
                    AppIconButton(
                      icon: Icons.refresh_rounded,
                      tooltip: 'Refresh',
                      onTap: () {
                        controller.refresh();
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: AllOutpostsList(
                    scrollController: _scrollController,
                  ),
                ),
              ],
            ),
            const _FloatingCreateOutpostButton(),
          ],
        ),
      ),
    );
  }
}

class _FloatingCreateOutpostButton extends GetWidget<OutpostsController> {
  const _FloatingCreateOutpostButton();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final numberOfAllOutposts = controller.outposts.value.length;
      bool showCreateButton = controller.showCreateButton.value;
      if (numberOfAllOutposts < 5) {
        showCreateButton = true;
      }
      return AnimatedPositioned(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        bottom: showCreateButton ? 16 : -8,
        left: 0,
        right: 0,
        child: Center(
          child: IgnorePointer(
            ignoring: !showCreateButton,
            child: AnimatedOpacity(
              opacity: showCreateButton ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shadowColor: AppColors.primary.withAlpha(90),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: const StadiumBorder(),
                ),
                onPressed: () {
                  Navigate.to(
                    type: NavigationTypes.toNamed,
                    route: Routes.CREATE_OUTPOST,
                  );
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 20),
                    SizedBox(width: 8),
                    Text("Start new Outpost"),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

int _lastPosition = 0;

class AllOutpostsList extends GetWidget<OutpostsController> {
  final ScrollController scrollController;
  const AllOutpostsList({
    super.key,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isGettingAllOutposts = controller.isGettingAllOutposts.value;
      if (isGettingAllOutposts) {
        return ListView.builder(
          padding: const EdgeInsets.only(top: 4),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (context, index) => const OutpostCardSkeleton(),
        );
      }
      return GestureDetector(
        onVerticalDragDown: (details) {
          final difference = details.localPosition.dy - _lastPosition;
          // detect direction of the drag
          if (difference > 0 && difference > 20) {
            // up
            _lastPosition = details.localPosition.dy.toInt();
            controller.showCreateButton.value = false;
          } else {
            // down
            _lastPosition = details.localPosition.dy.toInt();
            controller.showCreateButton.value = true;
          }
        },
        child: OutpostsList(
          scrollController: scrollController,
          listPage: ListPage.all,
        ),
      );
    });
  }
}
