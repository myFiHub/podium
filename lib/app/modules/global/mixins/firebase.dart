import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/groupsParser.dart';
import 'package:podium/app/modules/global/utils/referralsParser.dart';
import 'package:podium/app/modules/global/utils/usersParser.dart';
import 'package:podium/constants/constantConfigs.dart';
import 'package:podium/constants/constantKeys.dart';
import 'package:podium/models/cheerBooEvent.dart';
import 'package:podium/models/firebase_Session_model.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/models/firebase_Internal_wallet.dart';
import 'package:podium/models/notification_model.dart';
import 'package:podium/models/podiumDefinedEntryAddress/podiumDefinedEntryAddress.dart';
import 'package:podium/models/referral/referral.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/analytics.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/throttleAndDebounce/throttle.dart';
import 'package:uuid/uuid.dart';

final _sessionThrottle =
    Throttling(duration: const Duration(milliseconds: 900));
final _remainingTimeThrottle =
    Throttling(duration: const Duration(milliseconds: 900));
final _thrGroup = Throttling(duration: const Duration(seconds: 1));

Future<List<UserInfoModel>> getUsersByIds(List<String> userIds) async {
  final usersRef = FirebaseDatabase.instance.ref(FireBaseConstants.usersRef);
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
        final userInfo = singleUserParser(user);
        if (userInfo != null) {
          usersList.add(userInfo);
        }
      }
    }
    return usersList;
  } catch (e) {
    log.f('Error getting users by ids: $e');
    return [];
  }
}

Future<UserInfoModel?> getUserById(String userId) async {
  final databaseRef = FirebaseDatabase.instance.ref();
  final usersRef =
      databaseRef.child(FireBaseConstants.usersRef.replaceFirst('/', ''));
  final snapshot = await usersRef.child(userId).get();
  final user = snapshot.value as dynamic;
  if (user != null) {
    final userInfo = singleUserParser(user);
    return userInfo;
  } else {
    return null;
  }
}

Future<Map<String, Referral>> getAllTheUserReferals(
    {required String userId}) async {
  final databaseRef =
      FirebaseDatabase.instance.ref(FireBaseConstants.referalsRef + userId);
  final result = await databaseRef.get();
  if (result.value != null) {
    final remainingMap = referralsParser(result.value);
    return remainingMap;
  } else {
    return {};
  }
}

Future<List<PodiumDefinedEntryAddress>> getPodiumDefinedEntryAddresses() async {
  final databaseRef = FirebaseDatabase.instance
      .ref(FireBaseConstants.podiumDefinedEntryAddresses);
  final snapshot = await databaseRef.get();
  final addresses = snapshot.value as dynamic;
  if (addresses != null) {
    final List<PodiumDefinedEntryAddress> addressesList = [];
    addresses.forEach((value) {
      final address = PodiumDefinedEntryAddress(
        handle: value['handle'],
        type: value['type'],
        address: value['address'],
      );
      addressesList.add(address);
    });
    return addressesList;
  } else {
    return [];
  }
}

Future<bool> initializeUseReferalCodes({
  required String userId,
  required bool isBeforeLaunchUser,
}) async {
  try {
    final databaseRef =
        FirebaseDatabase.instance.ref(FireBaseConstants.referalsRef + userId);
    // generate 100 random referal codes
    final Map<String, dynamic> codes = {};
    final numberOfTiCkets = isBeforeLaunchUser
        ? ReferalConstants.initialNumberOfReferralsForBeforeLaunchUsers
        : ReferalConstants.initialNumberOfReferrals;
    for (int i = 0; i < numberOfTiCkets; i++) {
      final referalCode = Uuid().v4().substring(0, 6);
      final referral = Referral(usedBy: '');
      codes[referalCode] = referral.toJson();
    }
    await databaseRef.set(codes);
    return true;
  } catch (e) {
    log.e(e);
    return false;
  }
}

Future<String?> setUsedByToReferral({
  required String userId,
  required String referralCode,
  required String usedById,
}) async {
  try {
    final databaseRef = FirebaseDatabase.instance
        .ref(FireBaseConstants.referalsRef + userId + '/$referralCode');
    final snapshot = await databaseRef.get();
    final referral = snapshot.value as dynamic;
    if (referral != null) {
      final referralModel = singleReferralParser(referral);
      if (referralModel.usedBy == null || referralModel.usedBy!.isEmpty) {
        await databaseRef.child(Referral.usedByKey).set(usedById);
        return referralModel.usedBy;
      } else {
        return referralModel.usedBy;
      }
    } else {
      return null;
    }
  } catch (e) {
    log.e(e);
    return null;
  }
}

startListeningToMyReferals(void Function(Map<String, Referral>) onData) {
  final databaseRef =
      FirebaseDatabase.instance.ref(FireBaseConstants.referalsRef + myId);
  return databaseRef.onValue.listen((event) {
    final referals = event.snapshot.value as dynamic;
    if (referals != null) {
      final referralsMap = referralsParser(referals);
      onData(referralsMap);
    } else {
      onData({});
    }
  });
}

addRandomReferalCodeToUser({required String userId}) async {
  try {
    final referalCode = Uuid().v4().substring(0, 6);
    final referral = Referral(usedBy: '');
    final databaseRef = FirebaseDatabase.instance
        .ref(FireBaseConstants.referalsRef + userId + '/${referalCode}');
    await databaseRef.set(referral.toJson());
  } catch (e) {
    log.e(e);
  }
}

PaymentEvent? _parseSinglePayment(dynamic value) {
  try {
    final payment = PaymentEvent(
      initiatorAddress: value[PaymentEvent.initiatorAddressKey],
      targetAddress: value[PaymentEvent.targetAddressKey],
      groupId: value[PaymentEvent.groupIdKey],
      memberIds: ((value[PaymentEvent.memberIdsKey] ?? []) as List<dynamic>)
          .cast<String>(),
      selfCheer: value[PaymentEvent.selfCheerKey],
      initiatorId: value[PaymentEvent.initiatorIdKey],
      targetId: value[PaymentEvent.targetIdKey],
      amount: value[PaymentEvent.amountKey],
      type: value[PaymentEvent.typeKey],
      chainId: value[PaymentEvent.chainIdKey],
    );
    return payment;
  } catch (e) {
    log.e(e);
    return null;
  }
}

Future<List<PaymentEvent>> getReceivedPayments({required String userId}) async {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  Query query = _database
      .child(FireBaseConstants.paymentEvents)
      .orderByChild(PaymentEvent.targetIdKey)
      .equalTo(userId);
  final snapshot = await query.get();
  if (snapshot.value != null) {
    final payments = snapshot.value as dynamic;
    final List<PaymentEvent> paymentsList = [];
    payments.forEach((key, value) {
      final payment = _parseSinglePayment(value);
      if (payment != null) {
        paymentsList.add(payment);
      } else {
        log.e('Error parsing payment,id: $key');
      }
    });
    return paymentsList;
  }
  return [];
}

Future<List<PaymentEvent>> getInitiatedPayments(
    {required String userId}) async {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  Query query = _database
      .child(FireBaseConstants.paymentEvents)
      .orderByChild(PaymentEvent.initiatorIdKey)
      .equalTo(userId);
  final snapshot = await query.get();
  if (snapshot.value != null) {
    final payments = snapshot.value as dynamic;
    final List<PaymentEvent> paymentsList = [];
    payments.forEach((key, value) {
      final payment = _parseSinglePayment(value);
      if (payment != null) {
        paymentsList.add(payment);
      } else {
        log.e('Error parsing payment,id: $key');
      }
    });
    return paymentsList;
  }
  return [];
}

Future updateGroupLastActiveAt(
    {required String groupId, required int lastActiveAt}) async {
  final databaseRef = FirebaseDatabase.instance.ref(
      FireBaseConstants.groupsRef +
          groupId +
          '/${FirebaseGroup.lastActiveAtKey}');
  await databaseRef.set(lastActiveAt);
}

// final _deb = Debouncing(duration: const Duration(seconds: 5));
StreamSubscription<DatabaseEvent> startListeningToGroup(
    String groupId, void Function(DatabaseEvent) onData) {
  final databaseRef =
      FirebaseDatabase.instance.ref(FireBaseConstants.groupsRef + groupId);
  return databaseRef.onValue.listen((data) {
    _thrGroup.throttle(() {
      onData(data);
    });
  });
}

Future<String?> saveNameForUserById(
    {required String userId, required String name}) async {
  try {
    final databaseRef = FirebaseDatabase.instance.ref(
        FireBaseConstants.usersRef + userId + '/${UserInfoModel.fullNameKey}');

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
  final usersRef = FirebaseDatabase.instance.ref(FireBaseConstants.usersRef);
  final snapshot =
      await usersRef.orderByChild(UserInfoModel.emailKey).equalTo(email).get();
  final user = snapshot.value as dynamic;
  if (user != null) {
    final userValues = user.values.toList()[0];
    final userInfo = singleUserParser(userValues);
    return userInfo;
  } else {
    return null;
  }
}

Future<FirebaseSession?> getSessionData({required String groupId}) async {
  final databaseRef = FirebaseDatabase.instance
      .ref(FireBaseConstants.sessionsRef)
      .child(groupId);
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

Future<bool> unfollowUser(String userId) async {
  final databaseRef =
      FirebaseDatabase.instance.ref(FireBaseConstants.followers).child(userId);
  final snapshot = await databaseRef.get();
  final followers = snapshot.value as dynamic;
  if (followers != null) {
    final followersList = List.from(followers);
    if (followersList.contains(myId)) {
      followersList.remove(myId);
      await databaseRef.set(followersList);
      return true;
    } else {
      return true;
    }
  } else {
    return true;
  }
}

Future<bool> addFollowerToUser(
    {required String userId, required String followerId}) async {
  final databaseRef =
      FirebaseDatabase.instance.ref(FireBaseConstants.followers).child(userId);
  final snapshot = await databaseRef.get();
  final followers = snapshot.value as dynamic;
  if (followers != null) {
    final followersList = List.from(followers);
    if (followersList.contains(followerId)) {
      return true;
    }
    followersList.add(followerId);
    await databaseRef.set(followersList);
    return true;
  } else {
    await databaseRef.set([followerId]);
    return true;
  }
}

Future<List<String>> followersOfUser(String userId) async {
  final databaseRef = FirebaseDatabase.instance.ref();
  final followersRef = databaseRef.child(FireBaseConstants.followers);
  final snapshot = await followersRef.get();
  final followers = snapshot.value as dynamic;
  if (followers != null) {
    final userFollowers = followers[userId];
    if (userFollowers != null) {
      return List.from(userFollowers);
    } else {
      return [];
    }
  } else {
    return [];
  }
}

Future<bool> setCreatorJoinedToTrue({required String groupId}) async {
  final databaseRef = FirebaseDatabase.instance
      .ref(FireBaseConstants.groupsRef)
      .child(groupId)
      .child(FirebaseGroup.creatorJoinedKey);
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
    _sessionThrottle.throttle(() {
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

toggleGroupArchive({required String groupId, required bool archive}) async {
  final databaseRef = FirebaseDatabase.instance.ref(
      FireBaseConstants.groupsRef + groupId + '/${FirebaseGroup.archivedKey}');
  await databaseRef.set(archive);
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

StreamSubscription<DatabaseEvent> listenToGroupMembers({
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
  final databaseRef = FirebaseDatabase.instance
      .ref(FireBaseConstants.groupsRef)
      .child(groupId)
      .child(FirebaseGroup.invitedMembersKey)
      .child(userId != null ? userId : '');
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
  final databaseRef = FirebaseDatabase.instance
      .ref(FireBaseConstants.sessionsRef)
      .child(groupId)
      .child(FirebaseSession.membersKey)
      .child(userId);
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
  final databaseRef = FirebaseDatabase.instance
      .ref(FireBaseConstants.sessionsRef)
      .child(groupId)
      .child(FirebaseSession.membersKey)
      .child(userId)
      .child(FirebaseSessionMember.remainingTalkTimeKey);
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
    _remainingTimeThrottle.throttle(() {
      final remainingTime = event.snapshot.value as dynamic;
      if (remainingTime != null) {
        onData(remainingTime);
      } else {
        log.i('session not found');
        return null;
      }
    });
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
  final databaseRef = FirebaseDatabase.instance
      .ref(FireBaseConstants.usersRef)
      .child(userId)
      .child(UserInfoModel.localWalletAddressKey);
  final snapshot = await databaseRef.get();
  final localWalletAddress = snapshot.value as dynamic;
  if (localWalletAddress == null) {
    return '';
  }
  return localWalletAddress as String;
}

Future<String> getUserInternalWalletAddress(String userId) async {
  final databaseRef = FirebaseDatabase.instance
      .ref(FireBaseConstants.usersRef)
      .child(userId)
      .child(UserInfoModel.savedInternalWalletAddressKey);
  final snapshot = await databaseRef.get();
  final internalWalletAddress = snapshot.value as dynamic;
  if (internalWalletAddress == null) {
    return '';
  }
  return internalWalletAddress as String;
}

Future<List<String>> getListOfUserWalletsPresentInSession(
    String groupId) async {
  final databaseRef = FirebaseDatabase.instance
      .ref(FireBaseConstants.sessionsRef)
      .child(groupId)
      .child(FirebaseSession.membersKey);
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
    } else {
      addressList.add(user.savedInternalWalletAddress);
    }
  });
  return addressList;
}

follow(String userId) async {
  final databaseRef = FirebaseDatabase.instance
      .ref(FireBaseConstants.usersRef)
      .child(myId)
      .child(UserInfoModel.followingKey);
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
  final databaseRef = FirebaseDatabase.instance
      .ref(FireBaseConstants.usersRef)
      .child(myId)
      .child(UserInfoModel.followingKey);
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
  final groupRef =
      FirebaseDatabase.instance.ref().child(FireBaseConstants.groupsRef);
  final snapshot = await groupRef.child(groupId).once();
  final group = snapshot.snapshot.value as dynamic;
  if (group != null) {
    final groupInfo = singleGroupParser(group);
    if (groupInfo == null) {
      return null;
    }
    if (groupInfo.archived && groupInfo.creator.id != myId) {
      return null;
    }
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
    analytics.logEvent(
      name: 'notification_read',
      parameters: {
        'notification_id': notificationId,
      },
    );
  } catch (e) {
    log.e(e);
  }
}

deleteNotification({required String notificationId}) async {
  try {
    final databaseRef = FirebaseDatabase.instance
        .ref(FireBaseConstants.notificationsRef + notificationId);
    await databaseRef.remove();
    analytics.logEvent(
      name: 'notification_deleted',
      parameters: {
        'notification_id': notificationId,
      },
    );
  } catch (e) {
    log.e(e);
  }
}

Future<UserInfoModel?> getUserByInternalWalletAddress({
  required String internalWalletAddress,
}) async {
  final databaseRef = FirebaseDatabase.instance
      .ref(FireBaseConstants.usersRef)
      .orderByChild(UserInfoModel.savedInternalWalletAddressKey)
      .equalTo(internalWalletAddress);
  final snapshot = await databaseRef.get();
  final user = snapshot.value as dynamic;
  if (user != null) {
    final userInfo = singleUserParser(user);
    return userInfo;
  } else {
    return null;
  }
}

Future<UserInfoModel?> saveUserLoggedInWithSocialIfNeeded({
  required UserInfoModel user,
}) async {
  try {
    final userRef = FirebaseDatabase.instance
        .ref(FireBaseConstants.usersRef)
        .child(user.id);
    final snapshot = await userRef.get();
    final userSnapshot = snapshot.value as dynamic;
    if (userSnapshot != null) {
      final loginType = user.loginType!;
      analytics.logLogin(loginMethod: loginType);
      final savedLogintype = userSnapshot[UserInfoModel.loginTypeKey];
      if (savedLogintype != loginType) {
        userRef.child(UserInfoModel.loginTypeKey).set(loginType);
      }
      final internalWalletAddress = user.internalWalletAddress;
      final savedInternalWalletAddress =
          userSnapshot[UserInfoModel.savedInternalWalletAddressKey];
      if (savedInternalWalletAddress != internalWalletAddress) {
        userRef
            .child(UserInfoModel.savedInternalWalletAddressKey)
            .set(internalWalletAddress);
      }
      final savedLoginTypeIdentifier =
          userSnapshot[UserInfoModel.loginTypeIdentifierKey];
      if (savedLoginTypeIdentifier != user.loginTypeIdentifier) {
        userRef
            .child(UserInfoModel.loginTypeIdentifierKey)
            .set(user.loginTypeIdentifier);
      }

      final UserInfoModel? retrievedUser =
          singleUserParser(userSnapshot)?.copyWith(
        loginType: loginType,
        savedInternalWalletAddress: internalWalletAddress,
        loginTypeIdentifier: user.loginTypeIdentifier,
      );

      return retrievedUser;
    } else {
      userRef.set(user.toJson());
      analytics.logSignUp(signUpMethod: user.loginType!);
      return user;
    }
  } catch (e) {
    log.f('Error saving user logged in with X to firebase: $e');
    return null;
  }
}

Future<bool> saveNewPayment({required PaymentEvent event}) {
  final databaseRef =
      FirebaseDatabase.instance.ref(FireBaseConstants.paymentEvents);
  final newEventRef = databaseRef.push();
  return newEventRef.set(event.toJson()).then((value) => true).catchError((e) {
    log.e(e);
    return false;
  });
}

Future<DataSnapshot> firbaseGet({
  required DatabaseReference ref,
}) async {
  final res = await ref.once();
  return res.snapshot;
}
