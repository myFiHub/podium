import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/widgets/groupsList.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/utils/styles.dart';

class HomeBody extends StatelessWidget {
  const HomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        space5,
        Text(
          "My Rooms",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        Expanded(
          child: Container(
            child: HomePageGroupsList(),
          ),
        )
      ],
    );
  }
}

class HomePageGroupsList extends GetView<GroupsController> {
  const HomePageGroupsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final groups = controller.groupsImIn.value;
        final List<FirebaseGroup> groupsList =
            groups != null ? groups.values.toList() : [];
        if (groupsList.isEmpty) {
          return Container(
            child: Center(
              child: Text('Welcome to Podium, try joining some rooms'),
            ),
          );
        }
        return GroupList(groupsList: groupsList);
      },
    );
  }
}
