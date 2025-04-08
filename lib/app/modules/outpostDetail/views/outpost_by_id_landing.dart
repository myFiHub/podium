import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/widgets/loading_widget.dart';
import 'package:podium/app/modules/outpostDetail/controllers/outpost_detail_controller.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';

class GroupByIdLandingScreen extends GetView<OutpostDetailController> {
  String? id;

  GroupByIdLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    id ??= Get.parameters['id'];
    if (id == null || id!.isEmpty) {
      l.e('GroupByIdLandingScreen: id is null or empty');
      return Scaffold(
        body: Container(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Outpost not found',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.red,
                  ),
                ),
                space10,
                Button(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  text: 'Go back',
                  type: ButtonType.outline,
                ),
              ],
            ),
          ),
        ),
      );
    }
    Get.put(OutpostDetailController());
    controller.getOutpostInfo(id: id!);
    return Container(
      child: const Center(
        child: LoadingWidget(),
      ),
    );
  }
}
