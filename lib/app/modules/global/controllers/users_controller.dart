import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/profile/controllers/profile_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/podium/models/users/follow_unfollow_request.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/navigation/navigation.dart';

class UsersController extends GetxController {
  final globalController = Get.find<GlobalController>();
  // current user is set by listening to global controller's currentUserInfo
  final currentUserInfo = Rxn<UserModel>();
  final OutpostsController groupsController = Get.find<OutpostsController>();
  // final users = Map<String, UserInfoModel>();
  final followingsInProgress = Map<String, String>().obs;
  final gettingUserInfo_uuid = ''.obs;
  @override
  void onInit() {
    super.onInit();
    followingsInProgress.assignAll({});
    globalController.myUserInfo.listen((user) {
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

  Future<UserModel?> getUserById(String id) async {
    final users = await HttpApis.podium.getUsersByIds([id]);
    if (users.isNotEmpty) {
      return users[0];
    }
    return null;
  }

  Future<bool> followUnfollow(String id, bool startFollowing) async {
    followingsInProgress[id] = id;
    followingsInProgress.refresh();
    final user = await HttpApis.podium.getUserData(id);
    if (user != null) {
      try {
        final success = await HttpApis.podium.followUnfollow(
          id,
          startFollowing
              ? FollowUnfollowAction.follow
              : FollowUnfollowAction.unfollow,
        );
        if (!success) {
          return false;
        }
        Get.closeCurrentSnackbar();
        Toast.info(
          title: "${startFollowing ? "" : "un"}followed",
          message: "${startFollowing ? "" : "un"}followed ${user.name}",
        );
        return true;
      } catch (e) {
        Toast.error(
          title: 'Error',
          message: 'Error ${startFollowing ? "" : "un"}following user',
        );
        return false;
      } finally {
        followingsInProgress.remove(id);
        followingsInProgress.refresh();
      }
    }
    return false;
  }

  Future<void> openUserProfile(String userId) async {
    try {
      final isMyUser = userId == myId;
      if (isMyUser) {
        Navigate.to(
          type: NavigationTypes.toNamed,
          route: Routes.MY_PROFILE,
        );
        return;
      }

      gettingUserInfo_uuid.value = userId;
      final user = await HttpApis.podium.getUserData(userId);
      if (user != null) {
        Navigate.to(
          type: NavigationTypes.toNamed,
          route: Routes.PROFILE,
          parameters: {
            UserProfileParamsKeys.userInfo: jsonEncode(user.toJson())
          },
        );
      }
    } catch (e) {
      l.e('Error opening user profile: $e');
    } finally {
      gettingUserInfo_uuid.value = '';
    }
  }
}
