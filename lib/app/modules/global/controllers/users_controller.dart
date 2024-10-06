import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/profile/controllers/profile_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/models/notification_model.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:uuid/uuid.dart';

class UsersController extends GetxController
    with FireBaseUtils, BlockChainInteractions {
  final globalController = Get.find<GlobalController>();
  // current user is set by listening to global controller's currentUserInfo
  final currentUserInfo = Rxn<UserInfoModel>();
  final GroupsController groupsController = Get.find<GroupsController>();
  // final users = Map<String, UserInfoModel>();
  final followingsInProgress = Map<String, String>().obs;

  @override
  void onInit() {
    super.onInit();
    followingsInProgress.assignAll({});
    globalController.currentUserInfo.listen((user) {
      currentUserInfo.value = user;
    });
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  Future<UserInfoModel?> getUserById(String id) async {
    final users = await getUsersByIds([id]);
    if (users.isNotEmpty) {
      return users[0];
    }
    return null;
  }

  followUnfollow(String id, bool startFollowing) async {
    final user = await getUserById(id);
    if (user != null) {
      try {
        followingsInProgress[id] = id;
        followingsInProgress.refresh();
        await startFollowing
            ? Future.wait<void>(
                [follow(id), addFollowerToUser(userId: id, followerId: myId)])
            : [unfollow(id), unfollowUser(user.id)];
        final globalController = Get.find<GlobalController>();
        final myUser = globalController.currentUserInfo.value;
        if (startFollowing) {
          myUser!.following.add(id);
          final notifId = Uuid().v4();
          sendNotification(
            notification: FirebaseNotificationModel(
                id: notifId,
                title: 'New follower',
                body: '${myUser.fullName} followed you',
                type: NotificationTypes.follow.toString(),
                targetUserId: id,
                isRead: false,
                timestamp: DateTime.now().millisecondsSinceEpoch),
          );
        } else {
          myUser!.following.remove(id);
        }
        globalController.currentUserInfo.value = myUser;
        followingsInProgress.remove(id);
        followingsInProgress.refresh();
        Get.closeCurrentSnackbar();
        Get.snackbar(
          "${startFollowing ? "" : "un"}followed",
          "${startFollowing ? "" : "un"}followed ${user.fullName}",
          colorText: Colors.white,
        );
      } catch (e) {
        followingsInProgress.remove(id);
        followingsInProgress.refresh();
        Get.snackbar(
            'Error', 'Error ${startFollowing ? "" : "un"}following user');
      }
    }
  }

  openUserProfile(String userId) async {
    final user = await getUserById(userId);
    if (user != null) {
      Navigate.to(
        type: NavigationTypes.toNamed,
        route: Routes.PROFILE,
        parameters: {UserProfileParamsKeys.userInfo: jsonEncode(user.toJson())},
      );
    }
  }
}
