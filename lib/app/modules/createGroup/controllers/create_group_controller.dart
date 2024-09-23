import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/utils/throttleAndDebounce/debounce.dart';
import 'package:podium/widgets/textField/textFieldRounded.dart';

final _deb = Debouncing(duration: const Duration(seconds: 1));

class CreateGroupController extends GetxController with FireBaseUtils {
  final groupsController = Get.find<GroupsController>();
  final isCreatingNewGroup = false.obs;
  final newGroupHasAdultContent = false.obs;
  final roomAccessType = RoomAccessTypes.public.obs;
  final roomSpeakerType = RoomSpeakerTypes.everyone.obs;
  final selectedUsersToBuyTicketFrom_ToAccessRoom = <UserInfoModel>[].obs;
  final selectedUsersToBuyticketFrom_ToSpeak = <UserInfoModel>[].obs;
  final listOfSearchedUsersToBuyTicketFrom = <UserInfoModel>[].obs;
  final roomSubject = defaultSubject.obs;
  final groupName = "".obs;
  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  setRoomPrivacyType(String value) {
    roomAccessType.value = value;
  }

  setRoomSpeakingType(String value) {
    roomSpeakerType.value = value;
  }

  setRoomSubject(String value) {
    roomSubject.value = value;
  }

  get shouldSelectTicketHolersForSpeaking {
    return (roomSpeakerType.value ==
                RoomSpeakerTypes.onlyFriendTechTicketHolders ||
            roomSpeakerType.value == RoomSpeakerTypes.onlyArenaTicketHolders ||
            roomSpeakerType.value == RoomSpeakerTypes.onlyPodiumPassHolders) &&
        selectedUsersToBuyticketFrom_ToSpeak.isEmpty;
  }

  get shouldSelectTicketHolersForAccess {
    return ((roomAccessType.value ==
                RoomAccessTypes.onlyFriendTechTicketHolders) ||
            roomAccessType.value == RoomAccessTypes.onlyArenaTicketHolders ||
            roomAccessType.value == RoomAccessTypes.onlyPodiumPassHolders) &&
        selectedUsersToBuyTicketFrom_ToAccessRoom.isEmpty;
  }

  get shouldBuyTicketToSpeak {
    return roomSpeakerType.value ==
            RoomSpeakerTypes.onlyFriendTechTicketHolders ||
        roomSpeakerType.value == RoomSpeakerTypes.onlyArenaTicketHolders ||
        roomSpeakerType.value == RoomSpeakerTypes.onlyPodiumPassHolders;
  }

  get shouldBuyTicketToAccess {
    return roomAccessType.value ==
            RoomAccessTypes.onlyFriendTechTicketHolders ||
        roomAccessType.value == RoomAccessTypes.onlyArenaTicketHolders ||
        roomAccessType.value == RoomAccessTypes.onlyPodiumPassHolders;
  }

  toggleUserToSelectedList(UserInfoModel user, String ticketPermissiontype) {
    if (ticketPermissiontype == TicketPermissionType.speak) {
      final list =
          selectedUsersToBuyticketFrom_ToSpeak.value.map((e) => e.id).toList();
      if (list.contains(user.id)) {
        selectedUsersToBuyticketFrom_ToSpeak.value.removeWhere((element) {
          return element.id == user.id;
        });
      } else {
        selectedUsersToBuyticketFrom_ToSpeak.value.add(user);
      }
      selectedUsersToBuyticketFrom_ToSpeak.refresh();
    } else if (ticketPermissiontype == TicketPermissionType.access) {
      final list = selectedUsersToBuyTicketFrom_ToAccessRoom.value
          .map((e) => e.id)
          .toList();
      if (list.contains(user.id)) {
        selectedUsersToBuyTicketFrom_ToAccessRoom.value.removeWhere(
          (element) {
            return element.id == user.id;
          },
        );
      } else {
        selectedUsersToBuyTicketFrom_ToAccessRoom.value.add(user);
      }
      selectedUsersToBuyTicketFrom_ToAccessRoom.refresh();
    }
  }

  searchUsers(String value) async {
    _deb.debounce(() async {
      if (value.isEmpty) {
        listOfSearchedUsersToBuyTicketFrom.value = [];
        return;
      }
      final users = await searchForUserByName(value);
      listOfSearchedUsersToBuyTicketFrom.value = users.values.toList();
      ;
    });
  }

  create() async {
    if (groupName.value.isEmpty) {
      Get.snackbar(
        'Error',
        'room name cannot be empty',
        colorText: Colors.red,
      );
      return;
    } else if (groupName.value.length < 5) {
      Get.snackbar(
        'Error',
        'room name must be at least 5 characters',
        colorText: Colors.red,
      );
      return;
    }
    String subject = roomSubject.value;
    if (subject.isEmpty) {
      subject = defaultSubject;
    }
    isCreatingNewGroup.value = true;
    final accessType = roomAccessType.value;
    final speakerType = roomSpeakerType.value;
    await groupsController.createGroup(
      name: groupName.value,
      accessType: accessType,
      speakerType: speakerType,
      subject: subject,
      adultContent: newGroupHasAdultContent.value,
    );
    isCreatingNewGroup.value = false;
    // Navigate.to(
    //   type: NavigationTypes.offAllAndToNamed,
    //   route: Routes.HOME,
    // );
  }

  openSelectTicketBottomSheet({required String buyTicketToGetPermisionFor}) {
    Get.dialog(
      SelectUsersToBuyTicketFromBottomSheetContent(
        buyTicketToGetPermisionFor: buyTicketToGetPermisionFor,
      ),
    );
  }
}

class SelectUsersToBuyTicketFromBottomSheetContent
    extends GetView<CreateGroupController> {
  final String buyTicketToGetPermisionFor;
  const SelectUsersToBuyTicketFromBottomSheetContent({
    super.key,
    required this.buyTicketToGetPermisionFor,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        child: Container(
          color: ColorName.cardBackground,
          padding: EdgeInsets.all(20),
          height: Get.height * 0.5,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Search user',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      controller.listOfSearchedUsersToBuyTicketFrom.value = [];
                      Get.close();
                    },
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
              space10,
              Input(
                hintText: 'Enter the Name',
                onChanged: (value) {
                  controller.searchUsers(value);
                },
                autofocus: true,
              ),
              Expanded(
                child: Container(
                  child: Obx(
                    () {
                      final users =
                          controller.listOfSearchedUsersToBuyTicketFrom.value;
                      final selsectedListOfUsersToBuyTicketFromInOrderToSpeak =
                          controller.selectedUsersToBuyticketFrom_ToSpeak.value;
                      final selsectedListOfUsersToBuyTicketFromInOrderToAccessRoom =
                          controller
                              .selectedUsersToBuyTicketFrom_ToAccessRoom.value;
                      final myUser =
                          Get.find<GlobalController>().currentUserInfo.value!;
                      final myId = myUser.id;
                      List<String> selectedIds = [];
                      List<UserInfoModel> selectedUsers;
                      if (buyTicketToGetPermisionFor ==
                          TicketPermissionType.speak) {
                        selectedUsers =
                            selsectedListOfUsersToBuyTicketFromInOrderToSpeak;
                        selectedIds = selectedUsers.map((e) => e.id).toList();
                      } else if (buyTicketToGetPermisionFor ==
                          TicketPermissionType.access) {
                        selectedUsers =
                            selsectedListOfUsersToBuyTicketFromInOrderToAccessRoom;
                        selectedIds = selectedUsers.map((e) => e.id).toList();
                      } else {
                        return Container(
                          child: Center(
                            child: Text('Error, type is not valid'),
                          ),
                        );
                      }
                      // move selectedIds to the top of the list then my id to the top of them
                      List<UserInfoModel> listToShow = [];
                      listToShow.add(myUser);
                      final SelectedUsersExceptMe =
                          selectedUsers.where((element) => element.id != myId);
                      listToShow.addAll([...SelectedUsersExceptMe]);
                      listToShow.addAll(users.where(
                          (element) => !selectedIds.contains(element.id)));

                      return ListView.builder(
                        itemCount: listToShow.length,
                        itemBuilder: (context, index) {
                          final user = listToShow[index];
                          return Column(
                            children: [
                              ListTile(
                                title: Text(
                                  user.id == myId ? "You" : user.fullName,
                                  style: TextStyle(
                                    color: user.id == myId
                                        ? Colors.green
                                        : Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GFCheckbox(
                                      onChanged: (v) {
                                        controller.toggleUserToSelectedList(
                                          user,
                                          buyTicketToGetPermisionFor,
                                        );
                                      },
                                      value: selectedIds.contains(user.id),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                color: Colors.grey[900],
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class RoomAccessTypes {
  static const public = 'public';
  static const onlyLink = 'onlyLink';
  static const invitees = 'invitees';
  static const onlyFriendTechTicketHolders = 'onlyFriendTechTicketHolders';
  static const onlyArenaTicketHolders = 'onlyArenaTicketHolders';
  static const onlyPodiumPassHolders = 'onlyPodiumPassHolders';
}

class TicketPermissionType {
  static const speak = 'speak';
  static const access = 'access';
}

class TicketTypes {
  static const arena = 'arena';
  static const podium = 'podium';
  static const friendTech = 'friendTech';
}

class RoomSpeakerTypes {
  static const everyone = 'everyone';
  static const invitees = 'invitees';
  static const onlyCreator = 'onlyCreator';
  static const onlyFriendTechTicketHolders = 'onlyFriendTechTicketHolders';
  static const onlyArenaTicketHolders = 'onlyArenaTicketHolders';
  static const onlyPodiumPassHolders = 'onlyPodiumPassHolders';
}

const defaultSubject = "";
