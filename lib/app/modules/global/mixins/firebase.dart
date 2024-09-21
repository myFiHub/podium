import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/utils/groupsParser.dart';
import 'package:podium/app/modules/global/utils/usersParser.dart';
import 'package:particle_base/model/user_info.dart' as ParticleUserInfo;
import 'package:podium/constants/constantKeys.dart';
import 'package:podium/models/firebase_Session_model.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/models/firebase_particle_user.dart';
import 'package:podium/models/notification_model.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/logger.dart';

mixin FireBaseUtils {
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
            lowercasename: user[UserInfoModel.lowercasenameKey] ??
                user[UserInfoModel.fullNameKey].toLowerCase(),
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

  Future<String?> saveNameForUserById(
      {required String userId, required String name}) async {
    try {
      final databaseRef = FirebaseDatabase.instance.ref(
          FireBaseConstants.usersRef +
              userId +
              '/${UserInfoModel.fullNameKey}');

      final lowerCasedName = name.toLowerCase();
      final lowerCaseNameRef = FirebaseDatabase.instance.ref(
          FireBaseConstants.usersRef +
              userId +
              '/${UserInfoModel.lowercasenameKey}');
      await Future.wait([
        databaseRef.set(name),
        lowerCaseNameRef.set(lowerCasedName),
      ]);

      return name;
    } catch (e) {
      log.f('Error saving name for user by id: $e');
      return null;
    }
  }

  Future<UserInfoModel?> getUserByEmail(String email) async {
    final databaseRef = FirebaseDatabase.instance.ref();
    final usersRef =
        databaseRef.child(FireBaseConstants.usersRef.replaceFirst('/', ''));
    final snapshot = await usersRef
        .orderByChild(UserInfoModel.emailKey)
        .equalTo(email)
        .get();
    final user = snapshot.value as dynamic;
    if (user != null) {
      final userValues = user.values.toList()[0];
      final userInfo = UserInfoModel(
        fullName: userValues[UserInfoModel.fullNameKey],
        email: userValues[UserInfoModel.emailKey],
        id: userValues[UserInfoModel.idKey],
        avatar: userValues[UserInfoModel.avatarUrlKey],
        localWalletAddress:
            userValues[UserInfoModel.localWalletAddressKey] ?? '',
        following: List.from(userValues[UserInfoModel.followingKey] ?? []),
        numberOfFollowers: userValues[UserInfoModel.numberOfFollowersKey] ?? 0,
      );
      return userInfo;
    } else {
      return null;
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

  Future setIsTalkingInSession({
    required String sessionId,
    required String userId,
    required bool isTalking,
    int? startedToTalkAt,
  }) async {
    final databaseRef = FirebaseDatabase.instance.ref(FireBaseConstants
            .sessionsRef +
        sessionId +
        '/${FirebaseSession.membersKey}/$userId/${FirebaseSessionMember.isTalkingKey}');
    final startedToTalkAtRef = FirebaseDatabase.instance.ref(FireBaseConstants
            .sessionsRef +
        sessionId +
        '/${FirebaseSession.membersKey}/$userId/${FirebaseSessionMember.startedToTalkAtKey}');
    if (startedToTalkAt != null && isTalking) {
      await startedToTalkAtRef.set(startedToTalkAt);
    }
    await databaseRef.set(isTalking);
  }

  Future<bool> setCreatorJoinedToTrue({required String groupId}) async {
    final databaseRef = FirebaseDatabase.instance.ref(
        FireBaseConstants.groupsRef +
            groupId +
            '/${FirebaseGroup.creatorJoinedKey}');
    try {
      final isCreatorJoined = await databaseRef.get();
      if (isCreatorJoined.value == true) {
        return true;
      }
      await databaseRef.set(true);
      return true;
    } catch (e) {
      log.e(e);
      return false;
    }
  }

  StreamSubscription<DatabaseEvent>? startListeningToSessionMembers({
    required String sessionId,
    required void Function(Map<String, FirebaseSessionMember>) onData,
  }) {
    final databaseRef = FirebaseDatabase.instance.ref(
        FireBaseConstants.sessionsRef +
            sessionId +
            '/${FirebaseSession.membersKey}');
    return databaseRef.onValue.listen((event) {
      final members = event.snapshot.value as dynamic;
      if (members != null) {
        final Map<String, FirebaseSessionMember> membersMap = {};
        members.keys.toList().forEach((element) {
          final member = FirebaseSessionMember.fromJson(members[element]);
          membersMap[element] = member;
        });
        onData(membersMap);
      } else {
        log.i('session not found');
        return null;
      }
    });
  }

  Future<bool> inviteUserToJoinGroup({
    required String groupId,
    required String userId,
    required bool invitedToSpeak,
  }) async {
    final databaseRef = FirebaseDatabase.instance.ref(
        FireBaseConstants.groupsRef +
            groupId +
            '/${FirebaseGroup.invitedMembersKey}/$userId');
    try {
      await databaseRef.set({
        InvitedMember.idKey: userId,
        InvitedMember.invitedToSpeakKey: invitedToSpeak,
      });
      return true;
    } catch (e) {
      log.e(e);
      return false;
    }
  }

  setGroupToArchived({required String groupId, bool archived = true}) async {
    final databaseRef = FirebaseDatabase.instance.ref(
        FireBaseConstants.groupsRef +
            groupId +
            '/${FirebaseGroup.archivedKey}');
    await databaseRef.set(archived);
  }

  listenToSessionMembers({
    required String groupId,
    required void Function(DatabaseEvent) onData,
  }) {
    final databaseRef = FirebaseDatabase.instance.ref(
        FireBaseConstants.sessionsRef +
            groupId +
            '/${FirebaseSession.membersKey}');
    return databaseRef.onValue.listen(onData);
  }

  listenToGroupMembers({
    required String groupId,
    required void Function(DatabaseEvent) onData,
  }) {
    final databaseRef = FirebaseDatabase.instance.ref(
        FireBaseConstants.groupsRef + groupId + '/${FirebaseGroup.membersKey}');
    return databaseRef.onValue.listen(onData);
  }

  StreamSubscription<DatabaseEvent> listenToInvitedGroupMembers(
      {required FirebaseGroup group,
      required void Function(DatabaseEvent) onData}) {
    final databaseRef = FirebaseDatabase.instance.ref(
        FireBaseConstants.groupsRef +
            group.id +
            '/${FirebaseGroup.invitedMembersKey}');
    return databaseRef.onValue.listen(onData);
  }

  Future<Map<String, InvitedMember>> getInvitedMembers({
    required String groupId,
    String? userId,
  }) async {
    final databaseRef = FirebaseDatabase.instance.ref(FireBaseConstants
            .groupsRef +
        groupId +
        '/${FirebaseGroup.invitedMembersKey}${userId != null ? '/' + userId : ''}');
    final snapshot = await databaseRef.get();
    final invitedMembers = snapshot.value as dynamic;
    if (invitedMembers != null) {
      if (userId != null) {
        final invitedMember = InvitedMember(
          id: userId,
          invitedToSpeak: invitedMembers[InvitedMember.invitedToSpeakKey],
        );
        return {userId: invitedMember};
      }

      final Map<String, InvitedMember> invitedMembersMap = {};
      invitedMembers.keys.toList().forEach((element) {
        final invitedMember = InvitedMember(
          id: element,
          invitedToSpeak: invitedMembers[element]
              [InvitedMember.invitedToSpeakKey],
        );
        invitedMembersMap[element] = invitedMember;
      });
      return invitedMembersMap;
    } else {
      log.i('no invited members found');
      return {};
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

  StreamSubscription<DatabaseEvent>? startListeningToMyRemainingTalkingTime({
    required String groupId,
    required String userId,
    required onData(int? remainingTime),
  }) {
    final databaseRef = FirebaseDatabase.instance.ref(FireBaseConstants
            .sessionsRef +
        groupId +
        '/${FirebaseSession.membersKey}/$userId/${FirebaseSessionMember.remainingTalkTimeKey}');
    return databaseRef.onValue.listen((event) {
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

  Future<FirebaseGroup?> getGroupInfoById(String groupId) async {
    if (groupId.isEmpty) return null;
    final databaseRef = FirebaseDatabase.instance.ref();
    final groupRef = databaseRef.child(FireBaseConstants.groupsRef + groupId);
    final snapshot = await groupRef.get();
    final group = snapshot.value as dynamic;
    if (group != null) {
      final groupInfo = singleGroupParser(group);
      return groupInfo;
    } else {
      return null;
    }
  }

  Future<Map<String, FirebaseGroup>> searchForGroupByName(
      String groupName) async {
    if (groupName.isEmpty) return {};
    try {
      final lowercased = groupName.toLowerCase();
      final DatabaseReference _database = FirebaseDatabase.instance.ref();
      Query query = _database
          .child(FireBaseConstants.groupsRef)
          .orderByChild(FirebaseGroup.lowercasenameKey)
          .startAt(lowercased)
          .endAt('$lowercased\uf8ff');
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

      Query lowercasenameQuery = _database
          .child(FireBaseConstants.usersRef)
          .orderByChild(UserInfoModel.lowercasenameKey)
          .startAt(name)
          .endAt('$name\uf8ff');
      DataSnapshot loweCaseResSnapshot = await lowercasenameQuery.get();
      if (loweCaseResSnapshot.value != null) {
        return usersParser(loweCaseResSnapshot.value)
            as Map<String, UserInfoModel>;
      }
      Query fullNameQuery = _database
          .child(FireBaseConstants.usersRef)
          .orderByChild(UserInfoModel.fullNameKey)
          .startAt(name)
          .endAt('$name\uf8ff');
      DataSnapshot snapshot = await fullNameQuery.get();
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
    try {
      final databaseRef = FirebaseDatabase.instance
          .ref(FireBaseConstants.notificationsRef + notification.id);
      await databaseRef.set(
        notification.toJson(),
      );
    } catch (e) {
      log.e(e);
    }
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
              actionId: value[FirebaseNotificationModel.actionIdKey],
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
        final userToSave = FirebaseParticleAuthUserInfo(
          uuid: particleUser.uuid,
          wallets: particleUser.wallets
              .map((e) {
                return ParticleAuthWallet(
                  address: e.publicAddress,
                  chain: e.chainName,
                );
              })
              .toList()
              .where((w) => w.address.isNotEmpty && w.chain == 'evm_chain')
              .toList(),
        );
        await databaseRef.set(userToSave.toJson());
      }
    } catch (e) {
      log.f('Error saving particle user info to firebase: $e');
    }
  }

  Future<bool> saveParticleWalletInfoForUser(
      {required String userId,
      required FirebaseParticleAuthUserInfo info}) async {
    try {
      final databaseRef = FirebaseDatabase.instance.ref(
        FireBaseConstants.usersRef +
            userId +
            '/${UserInfoModel.savedParticleUserInfoKey}',
      );
      await databaseRef.set(info.toJson());
      return true;
    } catch (e) {
      log.f('Error saving particle user info to firebase: $e');
      return false;
    }
  }

  Future<UserInfoModel?> saveUserLoggedInWithSocialIfNeeded(
      {required UserInfoModel user}) async {
    try {
      final databaseRef = FirebaseDatabase.instance
          .ref(
            FireBaseConstants.usersRef,
          )
          .child(
            user.id,
          );
      final snapshot = await databaseRef.get();
      final userSnapshot = snapshot.value as dynamic;
      if (userSnapshot != null) {
        final retrievedUser = UserInfoModel(
          fullName: userSnapshot[UserInfoModel.fullNameKey],
          email: userSnapshot[UserInfoModel.emailKey],
          id: userSnapshot[UserInfoModel.idKey],
          avatar: userSnapshot[UserInfoModel.avatarUrlKey],
          localWalletAddress:
              userSnapshot[UserInfoModel.localWalletAddressKey] ?? '',
          following: List.from(userSnapshot[UserInfoModel.followingKey] ?? []),
          numberOfFollowers:
              userSnapshot[UserInfoModel.numberOfFollowersKey] ?? 0,
          lowercasename: userSnapshot[UserInfoModel.lowercasenameKey] ??
              userSnapshot[UserInfoModel.fullNameKey].toLowerCase(),
        );

        final savedParticleUserInfo =
            userSnapshot[UserInfoModel.savedParticleUserInfoKey];
        if (savedParticleUserInfo != null) {
          final parsed = json.decode(savedParticleUserInfo as String);
          final wallets =
              List.from(parsed[FirebaseParticleAuthUserInfo.walletsKey]);
          final List<ParticleAuthWallet> walletsList = [];
          wallets.forEach(
            (element) {
              walletsList.add(
                ParticleAuthWallet.fromMap(element),
              );
            },
          );
          final particleInfo = FirebaseParticleAuthUserInfo(
            uuid: parsed[FirebaseParticleAuthUserInfo.uuidKey],
            wallets: walletsList
                .where(
                  (w) => w.address.isNotEmpty && w.chain == 'evm_chain',
                )
                .toList(),
          );
          retrievedUser.savedParticleUserInfo = particleInfo;
        }
        return retrievedUser;
      } else {
        databaseRef.set(user.toJson());
        return user;
      }
    } catch (e) {
      log.f('Error saving user logged in with X to firebase: $e');
      return null;
    }
  }

  Future<List<ParticleAuthWallet>> getParticleAuthWalletsForUser(
      String userId) async {
    try {
      final databaseRef = FirebaseDatabase.instance.ref(
        FireBaseConstants.usersRef +
            userId +
            '/${UserInfoModel.savedParticleUserInfoKey}',
      );
      final snapshot = await databaseRef.get();
      final particleUserInfo = snapshot.value as dynamic;
      if (particleUserInfo != null) {
        final parsed = json.decode(particleUserInfo as String);
        final wallets =
            List.from(parsed[FirebaseParticleAuthUserInfo.walletsKey]);
        final List<ParticleAuthWallet> walletsList = [];
        wallets.forEach((element) {
          if (element['address'] != '' && element['chain'] == 'evm_chain') {
            walletsList.add(ParticleAuthWallet.fromMap(element));
          }
        });
        return walletsList;
      } else {
        return [];
      }
    } catch (e) {
      log.f('Error getting particle user info from firebase: $e');
      return [];
    }
  }
}
