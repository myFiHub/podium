import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/groupDetail/controllers/group_detail_controller.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';

class GroupByIdLandingScreen extends GetView<GroupDetailController> {
  String? id;

  GroupByIdLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    id ??= Get.parameters['id'];
    if (id == null || id!.isEmpty) {
      log.e('GroupByIdLandingScreen: id is null or empty');
      return Scaffold(
        body: Container(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Room not found',
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
    Get.put(GroupDetailController());
    controller.getGroupInfo(id: id!);
    return Container(
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
