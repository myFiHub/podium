import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/popUpsAndModals/setReminder.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/customLibs/omniDatePicker/omni_datetime_picker.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/utils/throttleAndDebounce/debounce.dart';
import 'package:podium/utils/truncate.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:podium/widgets/textField/textFieldRounded.dart';
import 'package:reown_appkit/reown_appkit.dart';

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
  final addressesToAddForEntering = RxList<String>([]);
  final addressesToAddForSpeaking = RxList<String>([]);
  final isScheduled = false.obs;
  final scheduledFor = 0.obs;
  final searchValueForSeletTickets = "".obs;
  final tags = RxList<String>([]);
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

  toggleScheduled() {
    isScheduled.value = !isScheduled.value;
  }

  setTags(List<String> values) {
    tags.value = values;
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

  Future<int> openCalendarBottomSheet() async {
    DateTime? dateTime = await showOmniDateTimePicker(
      context: Get.context!,
      is24HourMode: true,
      theme: ThemeData.dark(),
      type: OmniDateTimePickerType.dateAndTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      minutesInterval: 5,
    );
    if (dateTime != null) {
      scheduledFor.value = dateTime.millisecondsSinceEpoch;
    }
    return scheduledFor.value;
  }

  get shouldSelectTicketHolersForSpeaking {
    return (roomSpeakerType.value ==
                RoomSpeakerTypes.onlyFriendTechTicketHolders ||
            roomSpeakerType.value == RoomSpeakerTypes.onlyArenaTicketHolders ||
            roomSpeakerType.value == RoomSpeakerTypes.onlyPodiumPassHolders) &&
        selectedUsersToBuyticketFrom_ToSpeak.isEmpty &&
        addressesToAddForSpeaking.isEmpty;
  }

  get shouldSelectTicketHolersForAccess {
    return ((roomAccessType.value ==
                RoomAccessTypes.onlyFriendTechTicketHolders) ||
            roomAccessType.value == RoomAccessTypes.onlyArenaTicketHolders ||
            roomAccessType.value == RoomAccessTypes.onlyPodiumPassHolders) &&
        selectedUsersToBuyTicketFrom_ToAccessRoom.isEmpty &&
        addressesToAddForEntering.isEmpty;
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

  addAddressForEntering(String address) {
    // add if it is not already added
    if (!addressesToAddForEntering.contains(address)) {
      addressesToAddForEntering.add(address);
    }
  }

  removeAddressForEntering(String address) {
    addressesToAddForEntering.remove(address);
  }

  addAddressForSpeaking(String address) {
    // add if it is not already added
    if (!addressesToAddForSpeaking.contains(address)) {
      addressesToAddForSpeaking.add(address);
    }
  }

  removeAddressForSpeaking(String address) {
    addressesToAddForSpeaking.remove(address);
  }

  searchUsers(String value) async {
    searchValueForSeletTickets.value = value;
    if (value.isEmpty) {
      listOfSearchedUsersToBuyTicketFrom.value = [];
      return;
    }
    _deb.debounce(() async {
      final isAddress = checkIfValueIsDirectAddress(value);
      log.d('Is address: $isAddress');
      final users = await searchForUserByName(value);
      listOfSearchedUsersToBuyTicketFrom.value = users.values.toList();
      ;
    });
  }

  bool checkIfValueIsDirectAddress(String value) {
    if (value.length == 42) {
      try {
        EthereumAddress.fromHex(value);
        return true;
      } catch (e) {
        return false;
      }
    }
    return false;
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

    final alarmId = Random().nextInt(100000000);
    final setFor = await setReminder(
      alarmId: alarmId,
      scheduledFor: scheduledFor.value,
      eventName: groupName.value,
      timesList: defaultTimeList(
        endsAt: scheduledFor.value,
      ),
    );
    if (setFor == null) {
      return;
    } else {
      Get.snackbar(
        'Reminder set',
        setFor == 0
            ? 'You will be reminded when Event starts'
            : 'You will be reminded $setFor minutes before the event',
        colorText: Colors.green,
      );
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
      tags: tags.value,
      adultContent: newGroupHasAdultContent.value,
      requiredTicketsToAccess: selectedUsersToBuyTicketFrom_ToAccessRoom.value,
      requiredTicketsToSpeak: selectedUsersToBuyticketFrom_ToSpeak.value,
      requiredAddressesToEnter: addressesToAddForEntering.value,
      requiredAddressesToSpeak: addressesToAddForSpeaking.value,
      scheduledFor: scheduledFor.value,
      alarmId: alarmId,
    );
    isCreatingNewGroup.value = false;
  }

  openSelectTicketBottomSheet({required String buyTicketToGetPermisionFor}) {
    searchValueForSeletTickets.value = "";
    Get.dialog(
      SelectUsersToBuyTicketFromBottomSheetContent(
        buyTicketToGetPermisionFor: buyTicketToGetPermisionFor,
      ),
    );
  }
}

class ScheduledGroupDateSelector extends GetView<CreateGroupController> {
  const ScheduledGroupDateSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        width: Get.width,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ColorName.cardBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Text('Select Date and Time'),
          ],
        ),
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
    final inputController = TextEditingController();
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
              Obx(() {
                final searchValue = controller.searchValueForSeletTickets.value;
                bool isAddress =
                    controller.checkIfValueIsDirectAddress(searchValue);
                try {} catch (e) {}
                return SizedBox(
                  height: 70,
                  child: Input(
                    controller: inputController,
                    suffixIcon: searchValue.isEmpty
                        ? IconButton(
                            onPressed: () async {
                              final clipboardData =
                                  await Clipboard.getData(Clipboard.kTextPlain);
                              String? clipboardText = clipboardData?.text;
                              if (clipboardText != null) {
                                if (controller.checkIfValueIsDirectAddress(
                                    clipboardText)) {
                                  if (buyTicketToGetPermisionFor ==
                                      TicketPermissionType.speak) {
                                    controller
                                        .addAddressForSpeaking(clipboardText);
                                  } else if (buyTicketToGetPermisionFor ==
                                      TicketPermissionType.access) {
                                    controller
                                        .addAddressForEntering(clipboardText);
                                  }
                                } else {
                                  inputController.text = clipboardText;
                                  controller.searchUsers(clipboardText);
                                }
                              }
                            },
                            icon: Icon(
                              Icons.paste,
                              color: Colors.grey,
                            ),
                          )
                        : isAddress
                            ? IconButton(
                                onPressed: () {
                                  if (buyTicketToGetPermisionFor ==
                                      TicketPermissionType.speak) {
                                    controller
                                        .addAddressForSpeaking(searchValue);
                                  } else if (buyTicketToGetPermisionFor ==
                                      TicketPermissionType.access) {
                                    controller
                                        .addAddressForEntering(searchValue);
                                  }
                                  controller.searchUsers('');
                                  inputController.clear();
                                },
                                icon: Icon(Icons.check, color: Colors.green),
                              )
                            : IconButton(
                                onPressed: () {
                                  controller.searchUsers('');
                                  inputController.clear();
                                },
                                icon: Icon(Icons.close, color: Colors.red),
                              ),
                    hintText: 'Enter the Name/address',
                    onChanged: (value) {
                      controller.searchUsers(value);
                    },
                    autofocus: true,
                  ),
                );
              }),
              Expanded(
                child: Container(
                  child: Obx(
                    () {
                      final users = controller
                          .listOfSearchedUsersToBuyTicketFrom.value
                          .where(
                        (element) {
                          return element.id != myId;
                        },
                      );
                      final selsectedListOfUsersToBuyTicketFromInOrderToSpeak =
                          controller.selectedUsersToBuyticketFrom_ToSpeak.value;
                      final selsectedListOfUsersToBuyTicketFromInOrderToAccessRoom =
                          controller
                              .selectedUsersToBuyTicketFrom_ToAccessRoom.value
                              .where(
                        (element) {
                          return element.id != myId;
                        },
                      ).toList();
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
                      List<UserInfoModel> listOfUsers = [];
                      listOfUsers.add(myUser);
                      final SelectedUsersExceptMe =
                          selectedUsers.where((element) => element.id != myId);
                      listOfUsers.addAll([...SelectedUsersExceptMe]);
                      listOfUsers.addAll(users.where(
                          (element) => !selectedIds.contains(element.id)));
                      final listOfAddresses = buyTicketToGetPermisionFor ==
                              TicketPermissionType.speak
                          ? controller.addressesToAddForSpeaking
                          : controller.addressesToAddForEntering;
                      List<SelectBoxOption> options = [];
                      for (var address in listOfAddresses) {
                        options.add(SelectBoxOption(address: address));
                      }
                      for (var user in listOfUsers) {
                        options.add(SelectBoxOption(user: user));
                      }

                      return ListView.builder(
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final element = options[index];
                          return Column(
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.only(left: 12),
                                title: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (element.user != null)
                                          Text(
                                            element.user!.id == myId
                                                ? "You"
                                                : element.user!.fullName,
                                            textAlign: TextAlign.start,
                                            style: TextStyle(
                                              color: element.user!.id == myId
                                                  ? Colors.green
                                                  : Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        if (element.address != null)
                                          Text(
                                            truncate(
                                              element.address!,
                                              length: 20,
                                            ),
                                            textAlign: TextAlign.start,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (element.user != null)
                                      Row(
                                        children: [
                                          Text(
                                            "user ID: " +
                                                truncate(element.user!.id,
                                                    length: 12),
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (element.user != null)
                                      GFCheckbox(
                                        onChanged: (v) {
                                          if (element.user != null) {
                                            controller.toggleUserToSelectedList(
                                              element.user!,
                                              buyTicketToGetPermisionFor,
                                            );
                                            return;
                                          }
                                        },
                                        value: selectedIds
                                            .contains(element.user!.id),
                                      ),
                                    if (element.address != null)
                                      GFCheckbox(
                                        onChanged: (v) {
                                          if (element.address != null) {
                                            if (!v) {
                                              if (buyTicketToGetPermisionFor ==
                                                  TicketPermissionType.speak) {
                                                controller
                                                    .removeAddressForSpeaking(
                                                        element.address!);
                                              }
                                              if (buyTicketToGetPermisionFor ==
                                                  TicketPermissionType.access) {
                                                controller
                                                    .removeAddressForEntering(
                                                        element.address!);
                                              }
                                            }
                                          }
                                        },
                                        value: buyTicketToGetPermisionFor ==
                                                TicketPermissionType.speak
                                            ? controller
                                                .addressesToAddForSpeaking
                                                .contains(element.address)
                                            : controller
                                                .addressesToAddForEntering
                                                .contains(element.address),
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
              ),
              Obx(() {
                final type = buyTicketToGetPermisionFor;
                bool ready = false;
                if (type == TicketPermissionType.speak) {
                  ready = !controller.shouldSelectTicketHolersForSpeaking;
                }
                if (type == TicketPermissionType.access) {
                  ready = !controller.shouldSelectTicketHolersForAccess;
                }
                if (!ready) {
                  return Container(
                    child: Center(
                      child: Text(
                        'Select Users, or Enter Address',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return Button(
                  blockButton: true,
                  type: ButtonType.gradient,
                  onPressed: () {
                    Get.close();
                  },
                  child: Text('Done'),
                );
              })
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
  // static const onlyCreator = 'onlyCreator';
  static const onlyFriendTechTicketHolders = 'onlyFriendTechTicketHolders';
  static const onlyArenaTicketHolders = 'onlyArenaTicketHolders';
  static const onlyPodiumPassHolders = 'onlyPodiumPassHolders';
}

class SelectBoxOption {
  UserInfoModel? user;
  String? address;
  SelectBoxOption({this.user, this.address});
}

const defaultSubject = "";
