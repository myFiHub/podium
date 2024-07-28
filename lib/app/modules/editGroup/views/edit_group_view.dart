import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/edit_group_controller.dart';

class EditGroupView extends GetView<EditGroupController> {
  const EditGroupView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EditGroupView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'EditGroupView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
