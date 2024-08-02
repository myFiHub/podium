import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/utils/groupsParser.dart';
import 'package:podium/app/modules/global/utils/usersParser.dart';
import "package:particle_auth/model/user_info.dart" as ParticleUserInfo;
import 'package:podium/constants/constantKeys.dart';
import 'package:podium/models/firebase_Session_model.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/models/notification_model.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/logger.dart';

mixin FireBaseUtils {
  StreamSubscription<DatabaseEvent>? mySessionSubscription = null;

  Future<List<UserInfoModel>> getUsersByIds(List<String> userIds) async {
    final databaseRef = FirebaseDatabase.instance.ref();
    final usersRef =
        databaseRef.child(FireBaseConstants.usersRef.replaceFirst('/', ''));
    List<Future<DataSnapshot>> users = [];
    for (String userId in userIds) {
      users.add(usersRef.child(userId).get());
    }
    try {
      final snapshots = await Future.wait(users);
      List<UserInfoModel> usersList = [];
      for (DataSnapshot snapshot in snapshots) {
        final user = snapshot.value as dynamic;
        if (user != null) {
          final userInfo = UserInfoModel(
            fullName: user[UserInfoModel.fullNameKey],
            email: user[UserInfoModel.emailKey],
            id: user[UserInfoModel.idKey],
            avatar: user[UserInfoModel.avatarUrlKey],
            localWalletAddress: user[UserInfoModel.localWalletAddressKey] ?? '',
            following: List.from(user[UserInfoModel.followingKey] ?? []),
            numberOfFollowers: user[UserInfoModel.numberOfFollowersKey] ?? 0,
          );
          usersList.add(userInfo);
        }
      }
      return usersList;
    } catch (e) {
      log.f('Error getting users by ids: $e');
      return [];
    }
  }

  Future<FirebaseSession?> getSessionData({required String groupId}) async {
    final databaseRef =
        FirebaseDatabase.instance.ref(FireBaseConstants.sessionsRef + groupId);
    final snapshot = await databaseRef.get();
    final session = snapshot.value as dynamic;
    if (session != null) {
      final jsonedMembersMap =
          session[FirebaseSession.membersKey] as Map<dynamic, dynamic>;
      final members = jsonedMembersMap.keys.toList();
      final Map<String, FirebaseSessionMember> membersToAdd = {};
      for (String member in members) {
        membersToAdd[member] =
            FirebaseSessionMember.fromJson(jsonedMembersMap[member]);
      }
      final firebaseSession = FirebaseSession(
        id: session[FirebaseSession.idKey],
        createdBy: session[FirebaseSession.createdByKey],
        name: session[FirebaseSession.nameKey],
        members: membersToAdd,
      );
      return firebaseSession;
    } else {
      log.i('session not found');
      return null;
    }
  }

  Future<FirebaseSessionMember?> getUserSessionData(
      {required String groupId, required String userId}) async {
    final databaseRef = FirebaseDatabase.instance.ref(
        FireBaseConstants.sessionsRef +
            groupId +
            '/${FirebaseSession.membersKey}/$userId');
    final snapshot = await databaseRef.get();
    final session = snapshot.value as dynamic;
    if (session != null) {
      final firebaseSessionMember = FirebaseSessionMember.fromJson(session);
      return firebaseSessionMember;
    } else {
      log.i('session not found');
      return null;
    }
  }

  Future<int?> getUserRemainingTalkTime({
    required String groupId,
    required String userId,
  }) async {
    final databaseRef = FirebaseDatabase.instance.ref(FireBaseConstants
            .sessionsRef +
        groupId +
        '/${FirebaseSession.membersKey}/$userId/${FirebaseSessionMember.remainingTalkTimeKey}');
    final snapshot = await databaseRef.get();
    final remainingTime = snapshot.value as int?;
    if (remainingTime != null) {
      return remainingTime;
    } else {
      log.i('session not found');
      return null;
    }
  }

  startListeningToMyRemainingTalkingTime({
    required String groupId,
    required String userId,
    required onData(int? remainingTime),
  }) {
    final databaseRef = FirebaseDatabase.instance.ref(FireBaseConstants
            .sessionsRef +
        groupId +
        '/${FirebaseSession.membersKey}/$userId/${FirebaseSessionMember.remainingTalkTimeKey}');
    mySessionSubscription = databaseRef.onValue.listen((event) {
      final remainingTime = event.snapshot.value as dynamic;
      if (remainingTime != null) {
        onData(remainingTime);
      } else {
        log.i('session not found');
        return null;
      }
    });
  }

  Future<void> updateRemainingTimeOnFirebase({
    required int newValue,
    required String groupId,
    required String userId,
  }) async {
    final databaseRef = FirebaseDatabase.instance.ref(FireBaseConstants
            .sessionsRef +
        groupId +
        '/${FirebaseSession.membersKey}/$userId/${FirebaseSessionMember.remainingTalkTimeKey}');
    log.d("updating remaining time to $newValue in firebase");
    await databaseRef.set(newValue);
  }

  stopListeningToMySession() {
    mySessionSubscription?.cancel();
  }

  Future setIsUserPresentInSession({
    required String groupId,
    required String userId,
    required bool isPresent,
  }) async {
    final databaseRef = FirebaseDatabase.instance.ref(FireBaseConstants
            .sessionsRef +
        groupId +
        '/${FirebaseSession.membersKey}/$userId/${FirebaseSessionMember.presentKey}');
    await databaseRef.set(isPresent);
  }

  Future<String> getUserLocalWalletAddress(String userId) async {
    final databaseRef = FirebaseDatabase.instance.ref(
        FireBaseConstants.usersRef +
            userId +
            '/${UserInfoModel.localWalletAddressKey}');
    final snapshot = await databaseRef.get();
    final localWalletAddress = snapshot.value as dynamic;
    if (localWalletAddress == null) {
      return '';
    }
    return localWalletAddress as String;
  }

  Future<List<String>> getListOfUserWalletsPresentInSession(
      String groupId) async {
    final databaseRef = FirebaseDatabase.instance.ref(
        FireBaseConstants.sessionsRef +
            groupId +
            '/${FirebaseSession.membersKey}');
    final snapshot = await databaseRef.get();
    final members = snapshot.value as dynamic;
    final List<String> membersIdList = [];
    if (members == null) {
      return [];
    }
    members.keys.toList().forEach((element) {
      membersIdList.add(element);
    });
    final membersList = await getUsersByIds(membersIdList);
    final List<String> addressList = [];
    membersList.forEach((user) {
      if (user.localWalletAddress.isNotEmpty) {
        addressList.add(user.localWalletAddress);
      }
    });
    return addressList;
  }

  follow(String userId) async {
    final globalController = Get.find<GlobalController>();
    final myUser = globalController.currentUserInfo.value!;
    final databaseRef = FirebaseDatabase.instance.ref(
        FireBaseConstants.usersRef +
            myUser.id +
            '/${UserInfoModel.followingKey}');
    final followingArraySnapshot = await databaseRef.get();
    final followingArray = followingArraySnapshot.value as dynamic;
    if (followingArray != null) {
      final following = List.from(followingArray);
      if (following.contains(userId)) {
        return;
      } else {
        following.add(userId);
        await databaseRef.set(following);
      }
    } else {
      final currentList = [];
      currentList.add(userId);
      await databaseRef.set(currentList);
    }
  }

  unfollow(String userId) async {
    final globalController = Get.find<GlobalController>();
    final myUser = globalController.currentUserInfo.value!;
    final databaseRef = FirebaseDatabase.instance.ref(
        FireBaseConstants.usersRef +
            myUser.id +
            '/${UserInfoModel.followingKey}');
    final snapshot = await databaseRef.get();
    final following = snapshot.value as dynamic;
    if (following != null) {
      final currentList = List.from(following);
      currentList.remove(userId);
      await databaseRef.set(currentList);
    } else {
      await databaseRef.set([]);
    }
  }

  Future<Map<String, FirebaseGroup>> searchForGroupByName(
      String groupName) async {
    if (groupName.isEmpty) return {};
    try {
      final DatabaseReference _database = FirebaseDatabase.instance.ref();
      Query query = _database
          .child(FireBaseConstants.groupsRef)
          .orderByChild(FirebaseGroup.nameKey)
          .startAt(groupName)
          .endAt('$groupName\uf8ff');
      DataSnapshot snapshot = await query.get();
      if (snapshot.value != null) {
        try {
          return groupsParser(snapshot.value);
        } catch (e) {
          log.e(e);
          return {};
        }
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, UserInfoModel>> searchForUserByName(String name) async {
    try {
      final DatabaseReference _database = FirebaseDatabase.instance.ref();
      Query query = _database
          .child(FireBaseConstants.usersRef)
          .orderByChild(UserInfoModel.fullNameKey)
          .startAt(name)
          .endAt('$name\uf8ff');
      DataSnapshot snapshot = await query.get();
      if (snapshot.value != null) {
        return usersParser(snapshot.value) as Map<String, UserInfoModel>;
      }
      return {};
    } catch (e) {
      log.e(e);
      return {};
    }
  }

  sendNotification({required FirebaseNotificationModel notification}) async {
    final databaseRef = FirebaseDatabase.instance
        .ref(FireBaseConstants.notificationsRef + notification.id);
    await databaseRef.set(
      notification.toJson(),
    );
  }

  Future<List<FirebaseNotificationModel>> getMyNotifications() async {
    try {
      final globalController = Get.find<GlobalController>();
      final myUser = globalController.currentUserInfo.value!;
      final DatabaseReference _database = FirebaseDatabase.instance.ref();
      final Query query = _database
          .child(FireBaseConstants.notificationsRef)
          .orderByChild(FirebaseNotificationModel.targetUserIdKey)
          .equalTo(myUser.id);
      final List<FirebaseNotificationModel> notificationsList = [];
      final snapshot = await query.get();
      final notifications = snapshot.value as dynamic;
      if (notifications != null) {
        final list = List.from(notifications.values);
        list.forEach((value) {
          final notification = FirebaseNotificationModel(
            id: value[FirebaseNotificationModel.idKey],
            title: value[FirebaseNotificationModel.titleKey],
            body: value[FirebaseNotificationModel.bodyKey],
            type: value[FirebaseNotificationModel.typeKey],
            targetUserId: value[FirebaseNotificationModel.targetUserIdKey],
            isRead: value[FirebaseNotificationModel.isReadKey],
            image: value[FirebaseNotificationModel.imageKey],
            timestamp: value[FirebaseNotificationModel.timestampKey],
          );
          notificationsList.add(notification);
        });
        final sortedNotifs = notificationsList
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return sortedNotifs;
      } else {
        return [];
      }
    } catch (e) {
      log.e(e);
      return [];
    }
  }

  StreamSubscription<DatabaseEvent>? startListeningToMyNotifications(
      void Function(List<FirebaseNotificationModel>) onData) {
    try {
      final globalController = Get.find<GlobalController>();
      final myUser = globalController.currentUserInfo.value!;
      final Query query = FirebaseDatabase.instance
          .ref(FireBaseConstants.notificationsRef)
          .orderByChild(FirebaseNotificationModel.targetUserIdKey)
          .equalTo(myUser.id);
      final subscription = query.onValue.listen((event) {
        final notifications = event.snapshot.value as dynamic;
        if (notifications != null) {
          final List<FirebaseNotificationModel> notificationsList = [];
          final list = List.from(notifications.values);
          list.forEach((value) {
            final notification = FirebaseNotificationModel(
              id: value[FirebaseNotificationModel.idKey],
              title: value[FirebaseNotificationModel.titleKey],
              body: value[FirebaseNotificationModel.bodyKey],
              type: value[FirebaseNotificationModel.typeKey],
              targetUserId: value[FirebaseNotificationModel.targetUserIdKey],
              isRead: value[FirebaseNotificationModel.isReadKey],
              image: value[FirebaseNotificationModel.imageKey],
              timestamp: value[FirebaseNotificationModel.timestampKey],
            );
            notificationsList.add(notification);
          });

          onData(notificationsList);
        } else {
          onData([]);
        }
      });
      return subscription;
    } catch (e) {
      log.e(e);
      return null;
    }
  }

  markNotificationAsRead({required String notificationId}) async {
    try {
      final databaseRef = FirebaseDatabase.instance
          .ref(FireBaseConstants.notificationsRef + notificationId);
      await databaseRef.child(FirebaseNotificationModel.isReadKey).set(true);
    } catch (e) {
      log.e(e);
    }
  }

  deleteNotification({required String notificationId}) async {
    try {
      final databaseRef = FirebaseDatabase.instance
          .ref(FireBaseConstants.notificationsRef + notificationId);
      await databaseRef.remove();
    } catch (e) {
      log.e(e);
    }
  }

  ///////////////////////
  /// Particle auth /////
  ///////////////////////
  saveParticleUserInfoToFirebaseIfNeeded({
    required ParticleUserInfo.UserInfo particleUser,
    required String myUserId,
  }) async {
    try {
      final databaseRef = FirebaseDatabase.instance.ref(
        FireBaseConstants.usersRef +
            myUserId +
            '/${UserInfoModel.savedParticleUserInfoKey}',
      );

      final snapshot = await databaseRef.get();
      final particleUserInfo = snapshot.value as dynamic;
      if (particleUserInfo != null) {
        return;
      } else {
        await databaseRef.set(particleUser.toJson());
      }
    } catch (e) {
      log.f('Error saving particle user info to firebase: $e');
    }
  }
}
