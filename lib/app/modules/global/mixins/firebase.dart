import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';

import 'package:podium/constants/constantKeys.dart';
import 'package:podium/models/firebase_Session_model.dart';
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
}
