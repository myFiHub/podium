import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/modules/groupDetail/widgets/usersList.dart';
import 'package:podium/utils/constants.dart';
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
              FollowButton(userId: controller.userInfo.value!.id),
              space10,
              // BuyTicket(
              //   user: controller.userInfo.value!,
              // )
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
      final user = controller.userInfo.value;
      if (user == null) {
        return Container();
      }
      String avatar = user.avatar;
      if (avatar == defaultAvatar) {
        avatar = avatarPlaceHolder(user.fullName);
      }
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Hero(
              tag: user.id,
              child: Img(
                src: avatar,
                alt: user.fullName,
                size: 100,
              ),
            ),
            space10,
            space10,
            Text(
              user.fullName,
              style: const TextStyle(
                fontSize: 33,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    });
  }
}
