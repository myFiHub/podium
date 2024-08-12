import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:podium/widgets/textField/textFieldRounded.dart';

import '../controllers/create_group_controller.dart';

class CreateGroupView extends GetView<CreateGroupController> {
  const CreateGroupView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Input(
              hintText: 'Room Name',
              onChanged: (value) => controller.groupName.value = value,
            ),
            Obx(() {
              final loading = controller.isCreatingNewGroup.value;
              return Button(
                loading: loading,
                blockButton: true,
                type: ButtonType.gradient,
                onPressed: () {
                  controller.create();
                },
                text: 'create',
              );
            }),
          ],
        ),
      ),
    );
  }
}
