import 'package:get/get.dart';
import 'package:podium/app/modules/createGroup/controllers/create_group_controller.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/utils/extractAddressFromUserModel.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/logger.dart';

class HasAccessTicket {
  bool canEnter;
  bool canSpeak;
  HasAccessTicket({
    required this.canEnter,
    required this.canSpeak,
  });
}

class TicketSeller {
  final UserInfoModel userInfo;
  bool boughtTicketToSpeak;
  bool boughtTicketToAccess;
  bool buying;
  bool checking;
  final String address;
  TicketSeller({
    required this.userInfo,
    required this.boughtTicketToSpeak,
    required this.boughtTicketToAccess,
    required this.checking,
    required this.address,
    required this.buying,
  });
}

class CheckticketController extends GetxController
    with FireBaseUtils, BlockChainInteractions {
  final globalController = Get.find<GlobalController>();
  final GroupsController groupsController = Get.find<GroupsController>();
  final Map<String, UserInfoModel> usersToBuyTicketFromInOrderToHaveAccess = {};
  final Map<String, UserInfoModel> usersToBuyTicketFromInOrderToSpeak = {};
  final allUsersToBuyTicketFrom = Rx<Map<String, TicketSeller>>({});

  final loadingUsers = false.obs;
  final group = Rxn<FirebaseGroup>();

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
    checkTickets();
  }

  @override
  void onClose() {
    super.onClose();
    log.f('CheckticketController closed');
  }

  checkTickets() async {
    if (group.value == null) return;
    loadingUsers.value = true;
    final requiredTicketsToAccess = group.value!.ticketsRequiredToAccess;
    final requiredTicketsToSpeak = group.value!.ticketsRequiredToSpeak;

    final accessIds = requiredTicketsToAccess.map((e) => e.userId).toList();
    final speakIds = requiredTicketsToSpeak.map((e) => e.userId).toList();
    final [usersForAccess, usersForSpeak] = await Future.wait([
      getUsersByIds(accessIds),
      getUsersByIds(speakIds),
    ]);
    usersForAccess.forEach((element) {
      usersToBuyTicketFromInOrderToHaveAccess[element.id] = element;
    });
    usersForSpeak.forEach((element) {
      usersToBuyTicketFromInOrderToSpeak[element.id] = element;
    });
    loadingUsers.value = false;
    final mergedUsers = {
      ...usersToBuyTicketFromInOrderToHaveAccess,
      ...usersToBuyTicketFromInOrderToSpeak,
    };
    mergedUsers.forEach((key, value) {
      allUsersToBuyTicketFrom.value[key] = TicketSeller(
        userInfo: value,
        boughtTicketToAccess: false,
        boughtTicketToSpeak: false,
        checking: true,
        buying: false,
        address: extractAddressFromUserModel(user: value) ?? '',
      );
    });
    allUsersToBuyTicketFrom.refresh();

    final results = await Future.wait(
      allUsersToBuyTicketFrom.value.entries.map(
        (e) => checkIfIveBoughtTheTicketFromUser(
          e.value.address,
          e.value.userInfo.id,
        ),
      ),
    );
    final allKeys = allUsersToBuyTicketFrom.value.keys.toList();
    for (var i = 0; i < results.length; i++) {
      final access = results[i];
      final key = allKeys[i];
      allUsersToBuyTicketFrom.value[key] = TicketSeller(
        userInfo: allUsersToBuyTicketFrom.value[key]!.userInfo,
        boughtTicketToAccess: access.canEnter,
        boughtTicketToSpeak: access.canSpeak,
        checking: false,
        buying: false,
        address: allUsersToBuyTicketFrom.value[key]!.address,
      );
    }
    allUsersToBuyTicketFrom.refresh();
  }

  buyTicket({required UserInfoModel userToBuyFrom}) async {
    try {
      allUsersToBuyTicketFrom.value[userToBuyFrom.id]!.buying = true;
      allUsersToBuyTicketFrom.refresh();
      final result = await particle_buySharesWithReferrer(
        sharesSubject: extractAddressFromUserModel(user: userToBuyFrom) ?? '',
      );
      log.d(result);
    } catch (e) {
    } finally {
      allUsersToBuyTicketFrom.value[userToBuyFrom.id]!.buying = false;
      allUsersToBuyTicketFrom.refresh();
    }
  }

  Future<HasAccessTicket> checkIfIveBoughtTheTicketFromUser(
    String userAddress,
    String userId,
  ) async {
    final myUser = globalController.currentUserInfo.value!;
    if (userId == myUser.id)
      return HasAccessTicket(canEnter: true, canSpeak: true);
    HasAccessTicket access = HasAccessTicket(canEnter: false, canSpeak: false);
    final List<Future> arrayToCall = [];
    if (group.value!.accessType == RoomAccessTypes.onlyArenaTicketHolders) {
      arrayToCall.add(particle_getMyShares(
        sharesSubject: userAddress,
      ));
    }
    if (group.value!.speakerType == RoomSpeakerTypes.onlyArenaTicketHolders) {
      arrayToCall.add(particle_getMyShares(
        sharesSubject: userAddress,
      ));
    }
    // /////////////////// TODO:FIXME: fix for other tickets
    final results = await Future.wait(arrayToCall);
    final accessTicket = results[0] as BigInt?;
    if (accessTicket != null && accessTicket > BigInt.zero) {
      access.canEnter = true;
    }
    if (results.length > 1) {
      final speakTicket = results[1] as BigInt?;
      if (speakTicket != null && speakTicket > BigInt.zero) {
        access.canSpeak = true;
      }
    }

    return access;
  }
}
