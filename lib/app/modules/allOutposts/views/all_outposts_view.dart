import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/widgets/outpostsList.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';

import '../controllers/all_outposts_controller.dart';

final _scrollController = ScrollController();
// listen to scroll controller to show or hide the bottom button

class AllOutpostsView extends GetView<AllOutpostsController> {
  const AllOutpostsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              space16,
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "All Outposts",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    space10,
                    // SizedBox(
                    //   height: 40,
                    //   child: TextField(
                    //     controller: TextEditingController(
                    //         text: controller.searchValue.value),
                    //     decoration: InputDecoration(
                    //       hintText: "What are we looking for?",
                    //       hintStyle: const TextStyle(fontSize: 14),
                    //       prefixIcon: const Icon(Icons.search),
                    //       contentPadding: const EdgeInsets.all(16),
                    //       filled: true,
                    //       fillColor: Colors.grey[200],
                    //       border: OutlineInputBorder(
                    //         borderRadius: BorderRadius.circular(8),
                    //         borderSide: BorderSide.none,
                    //       ),
                    //     ),
                    //     style: const TextStyle(
                    //       fontSize: 18,
                    //       color: Colors.black,
                    //     ),
                    //     onChanged: (value) {
                    //       controller.search(value);
                    //     },
                    //   ),
                    // ),
                    // space10,
                  ],
                ),
              ),
              // Lista de grupos
              Expanded(
                child: Container(
                  child: AllOutpostsList(
                    scrollController: _scrollController,
                  ),
                ),
              ),
            ],
          ),
          const _FloatingCreateOutpostButton(),
        ],
      ),
    );
  }
}

class _FloatingCreateOutpostButton extends GetWidget<OutpostsController> {
  const _FloatingCreateOutpostButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final showCreateButton = controller.showCreateButton.value;
      return AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          bottom: showCreateButton ? 10 : -10,
          left: MediaQuery.of(context).size.width / 2 - 100,
          child: IgnorePointer(
            ignoring: !showCreateButton,
            child: AnimatedOpacity(
              opacity: showCreateButton ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 50,
                width: 200,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.green],
                    ),
                  ),
                  child: Button(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          "Start new Outpost",
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
                        route: Routes.CREATE_OUTPOST,
                      );
                    },
                  ),
                ),
              ),
            ),
          ));
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
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
      return GestureDetector(
        onVerticalDragDown: (details) {
          // detect direction of the drag
          if (details.localPosition.dy > _lastPosition) {
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
