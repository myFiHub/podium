import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:podium/root.dart';
import 'package:podium/widgets/ui/app_ui.dart';

import '../controllers/edit_group_controller.dart';

class EditGroupView extends GetView<EditGroupController> {
  const EditGroupView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const PageWrapper(
      child: Scaffold(
        body: Column(
          children: [
            AppPageHeader(
              title: 'Edit Outpost',
              showBack: true,
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: AppEmptyState(
                    icon: Icons.edit_note_rounded,
                    title: 'Editing is coming soon',
                    message:
                        "You'll be able to update your outpost details here.",
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
