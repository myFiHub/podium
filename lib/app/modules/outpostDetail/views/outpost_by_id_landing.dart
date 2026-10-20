import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/widgets/loading_widget.dart';
import 'package:podium/app/modules/outpostDetail/controllers/outpost_detail_controller.dart';
import 'package:podium/root.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/widgets/ui/app_ui.dart';

class GroupByIdLandingScreen extends StatefulWidget {
  const GroupByIdLandingScreen({super.key});

  @override
  State<GroupByIdLandingScreen> createState() => _GroupByIdLandingScreenState();
}

class _GroupByIdLandingScreenState extends State<GroupByIdLandingScreen> {
  final id = Get.parameters['id'];

  @override
  void initState() {
    super.initState();
    final outpostId = id;
    if (outpostId == null || outpostId.isEmpty) {
      l.e('GroupByIdLandingScreen: id is null or empty');
      return;
    }
    final controller = Get.isRegistered<OutpostDetailController>()
        ? Get.find<OutpostDetailController>()
        : Get.put(OutpostDetailController());
    controller.getOutpostInfo(id: outpostId);
  }

  @override
  Widget build(BuildContext context) {
    final outpostId = id;
    if (outpostId == null || outpostId.isEmpty) {
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
    return const Scaffold(
      body: PageWrapper(
        child: Center(
          child: LoadingWidget(),
        ),
      ),
    );
  }
}
