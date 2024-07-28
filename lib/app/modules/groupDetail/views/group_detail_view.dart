import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/group_call_controller.dart';
import 'package:podium/app/modules/groupDetail/widgets/usersList.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';

import '../controllers/group_detail_controller.dart';

class GroupDetailView extends GetView<GroupDetailController> {
  const GroupDetailView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () {
          final isLoading = controller.isGettingMembers.value;
          final members = controller.membersList.value;
          final group = controller.group.value;
          if (group == null) {
            return Center(
              child: Text(
                'Group is empty, don\'t forget to add a group to controller then navigate to this view',
              ),
            );
          }
          if (isLoading) {
            return Center(child: CircularProgressIndicator());
          } else {
            return Column(
              children: <Widget>[
                Expanded(
                  child: UserList(
                    usersList: members,
                  ),
                ),
                Button(
                  blockButton: true,
                  type: ButtonType.gradient,
                  onPressed: () {
                    final groupCallController = Get.find<GroupCallController>();
                    groupCallController.startCall(group);
                  },
                  child: Text('join the room'),
                ),
                space10,
                space10,
              ],
            );
          }
        },
      ),
    );
  }
}
