import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/widgets/loading_widget.dart';
import 'package:podium/app/modules/outpostDetail/controllers/outpost_detail_controller.dart';
import 'package:podium/root.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/widgets/ui/app_ui.dart';

class GroupByIdLandingScreen extends GetView<OutpostDetailController> {
  const GroupByIdLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final id = Get.parameters['id'];
    if (id == null || id.isEmpty) {
      l.e('GroupByIdLandingScreen: id is null or empty');
      return Scaffold(
        body: PageWrapper(
          child: Center(
            child: AppEmptyState(
              icon: Icons.travel_explore_rounded,
              title: 'Outpost not found',
              message: 'This link may be broken or the outpost was removed.',
              actionLabel: 'Go back',
              onAction: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
      );
    }
    Get.put(OutpostDetailController());
    controller.getOutpostInfo(id: id);
    return const Scaffold(
      body: PageWrapper(
        child: Center(
          child: LoadingWidget(),
        ),
      ),
    );
  }
}
