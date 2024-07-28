import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/utils/styles.dart';

import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              UserInfo(),
            ],
          ),
        ),
      ),
    );
  }
}

class UserInfo extends GetWidget<ProfileController> {
  const UserInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final myUser = controller.userInfo.value;
      if (myUser == null) {
        return Container();
      }
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GFAvatar(
              backgroundImage: NetworkImage(myUser.avatar),
              shape: GFAvatarShape.standard,
              size: 100,
            ),
            space10,
            space10,
            Text(
              myUser.fullName,
              style: const TextStyle(
                fontSize: 33,
                fontWeight: FontWeight.w700,
              ),
            ),
            space10,
            Text(
              myUser.email,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w700,
                color: ColorName.greyText,
              ),
            ),
          ],
        ),
      );
    });
  }
}
