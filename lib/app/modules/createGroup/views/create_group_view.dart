import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:getwidget/components/text_field/gf_text_field_rounded.dart';
import 'package:podium/widgets/button/button.dart';

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
            GFTextFieldRounded(
              editingbordercolor: Colors.blueAccent,
              idlebordercolor: Colors.black,
              borderwidth: 1,
              cornerradius: 8,
              hintText: 'group name',
              onChanged: (value) => controller.groupName.value = value,
            ),
            Obx(() {
              final loading = controller.isCreatingNewGroup.value;
              return Button(
                onPressed: () {
                  controller.create();
                },
                text: loading ? 'creating . ..' : 'create',
              );
            }),
          ],
        ),
      ),
    );
  }
}
