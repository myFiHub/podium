import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/profile/controllers/profile_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/constants/constantKeys.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/navigation/navigation.dart';

class UsersController extends GetxController with FireBaseUtils {
  final globalController = Get.find<GlobalController>();
  // current user is set by listening to global controller's currentUserInfo
  final currentUserInfo = Rxn<UserInfoModel>();
  final GroupsController groupsController = Get.find<GroupsController>();
  final users = Map<String, UserInfoModel>();
  final followingsInProgress = Map<String, String>().obs;

  @override
  void onInit() {
    super.onInit();
    followingsInProgress.assignAll({});
    globalController.currentUserInfo.listen((user) {
      currentUserInfo.value = user;
    });
    globalController.loggedIn.listen((loggedIn) {
      getRealtimeUsers(loggedIn);
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

  UserInfoModel? getUserById(String id) {
    final lowercasedId = id.toLowerCase();
    return users[lowercasedId];
  }

  buyTicket({required UserInfoModel user}) {
    final myUser = currentUserInfo.value;
  }

  followUnfollow(String id, bool startFollowing) async {
    final user = getUserById(id);
    if (user != null) {
      try {
        followingsInProgress[id] = id;
        followingsInProgress.refresh();
        await startFollowing ? follow(id) : unfollow(id);
        final globalController = Get.find<GlobalController>();
        final myUser = globalController.currentUserInfo.value;
        if (startFollowing) {
          myUser!.following.add(id);
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

  getRealtimeUsers(bool loggedIn) {
    final groupsController = Get.find<GroupsController>();
    final databaseReference =
        FirebaseDatabase.instance.ref(FireBaseConstants.usersRef);
    StreamSubscription<DatabaseEvent>? subscription;
    if (loggedIn) {
      subscription = databaseReference.onValue.listen((event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          Map<String, UserInfoModel> usersMap = {};
          // Iterate through the data
          data.forEach((key, value) {
            final name = value[UserInfoModel.fullNameKey];
            final email = value[UserInfoModel.emailKey];
            final String id = value[UserInfoModel.idKey];
            final avatar = value[UserInfoModel.avatarUrlKey];
            final user = UserInfoModel(
              fullName: name,
              email: email,
              id: id,
              avatar: avatar,
              localWalletAddress:
                  value[UserInfoModel.localWalletAddressKey] ?? '',
              following: List.from(value[UserInfoModel.followingKey] ?? []),
              numberOfFollowers: value[UserInfoModel.numberOfFollowersKey] ?? 0,
            );
            final lowercasedId = id.toLowerCase();
            usersMap[lowercasedId] = user;
          });
          users.assignAll(usersMap);
          groupsController.getRealtimeGroups(true);
        } else {
          Get.snackbar('aaaaaaaaaaa', 'something horible happened');
        }
      });
    } else {
      subscription?.cancel();
      groupsController.subscription?.cancel();
    }
  }

  openUserProfile(String userId) {
    final user = getUserById(userId);
    if (user != null) {
      final profileController = Get.put(ProfileController());
      profileController.userInfo.value = user;
      Navigate.to(
        type: NavigationTypes.toNamed,
        route: Routes.PROFILE,
      );
    }
  }
}
