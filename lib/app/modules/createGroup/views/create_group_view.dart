import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:podium/app/modules/createGroup/widgets/groupType_dropDown.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:podium/widgets/textField/textFieldRounded.dart';

import '../controllers/create_group_controller.dart';

class CreateGroupView extends GetView<CreateGroupController> {
  const CreateGroupView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.only(top: 80),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Input(
                  hintText: 'Room Name',
                  onChanged: (value) => controller.groupName.value = value,
                  marginvertical: 0,
                ),
                Input(
                  initialValue: controller.roomSubject.value,
                  hintText: 'Main Subject (optional)',
                  onChanged: (value) => controller.roomSubject.value = value,
                  marginvertical: 0,
                ),
                Obx(() {
                  final selectedValue = controller.roomAccessType.value;
                  return Stack(
                    children: [
                      Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Allowed to Enter',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                            DropDown(
                              items: [
                                DropDownItem(
                                  value: RoomAccessTypes.public,
                                  text: 'Everyone',
                                ),
                                DropDownItem(
                                  value: RoomAccessTypes.onlyLink,
                                  text: 'Users having the Link',
                                ),
                                DropDownItem(
                                  value: RoomAccessTypes.invitees,
                                  text: 'Invited Users',
                                ),
                                DropDownItem(
                                  value: RoomAccessTypes.onlyArenaTicketHolders,
                                  text: 'Arena Ticket Holders',
                                  // enabled: false,
                                ),
                                DropDownItem(
                                  value: RoomAccessTypes
                                      .onlyFriendTechTicketHolders,
                                  text: 'FriendTech Ticket Holders',
                                  enabled: false,
                                ),
                                DropDownItem(
                                  value: RoomAccessTypes.onlyPodiumPassHolders,
                                  text: 'Podium Pass Holders',
                                  enabled: false,
                                ),
                              ],
                              selectedValue: selectedValue,
                              onChanged: (value) {
                                controller.setRoomPrivacyType(value);
                              },
                            ),
                          ],
                        ),
                      ),
                      Obx(() {
                        final selectedList = controller
                            .selectedUsersToBuyTicketFrom_ToAccessRoom;
                        if (controller.shouldBuyTicketToAccess) {
                          return SelectUserstoBuyTicketFrom(
                            onTap: () {
                              controller.openSelectTicketBottomSheet(
                                buyTicketToGetPermisionFor:
                                    TicketPermissionType.access,
                              );
                            },
                            selectedList: selectedList,
                          );
                        }
                        return SizedBox();
                      }),
                    ],
                  );
                }),
                space10,
                Obx(() {
                  final selectedValue = controller.roomSpeakerType.value;
                  return Container(
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Allowed to Speak',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                            DropDown(
                              items: [
                                DropDownItem(
                                  value: RoomSpeakerTypes.everyone,
                                  text: 'Everyone',
                                ),
                                DropDownItem(
                                  value: RoomSpeakerTypes.invitees,
                                  text: 'Only Invited Users',
                                ),
                                DropDownItem(
                                  value: RoomSpeakerTypes.onlyCreator,
                                  text: 'Only Creator',
                                ),
                                DropDownItem(
                                  value:
                                      RoomSpeakerTypes.onlyArenaTicketHolders,
                                  text: 'Arena Ticket Holders',
                                  // enabled: false,
                                ),
                                DropDownItem(
                                  value: RoomAccessTypes
                                      .onlyFriendTechTicketHolders,
                                  text: 'FriendTech Ticket Holders',
                                  enabled: false,
                                ),
                              ],
                              selectedValue: selectedValue,
                              onChanged: (value) {
                                controller.setRoomSpeakingType(value);
                              },
                            ),
                          ],
                        ),
                        Obx(
                          () {
                            final selectedList =
                                controller.selectedUsersToBuyticketFrom_ToSpeak;
                            if (controller.shouldBuyTicketToSpeak) {
                              return SelectUserstoBuyTicketFrom(
                                onTap: () {
                                  controller.openSelectTicketBottomSheet(
                                    buyTicketToGetPermisionFor:
                                        TicketPermissionType.speak,
                                  );
                                },
                                selectedList: selectedList,
                              );
                            }
                            return SizedBox();
                          },
                        ),
                      ],
                    ),
                  );
                }),
                space10,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Adults Speaking',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 18,
                      ),
                    ),
                    Obx(
                      () {
                        final isChecked =
                            controller.newGroupHasAdultContent.value;
                        return GFCheckbox(
                          value: isChecked,
                          activeBgColor: Colors.red,
                          onChanged: (value) {
                            controller.newGroupHasAdultContent.value = value;
                          },
                        );
                      },
                    ),
                  ],
                ),
                space10,
                Obx(() {
                  final loading = controller.isCreatingNewGroup.value;
                  final shouldSelectTicketHolersForAccess =
                      controller.shouldSelectTicketHolersForAccess;
                  final shouldSelectTicketHolersForSpeaking =
                      controller.shouldSelectTicketHolersForSpeaking;
                  final hasThingsToDo = shouldSelectTicketHolersForAccess ||
                      shouldSelectTicketHolersForSpeaking;
                  return Button(
                    loading: loading,
                    blockButton: true,
                    type: ButtonType.gradient,
                    onPressed: hasThingsToDo
                        ? null
                        : () {
                            controller.create();
                          },
                    text: 'Create Room',
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SelectUserstoBuyTicketFrom extends StatelessWidget {
  final Function onTap;
  final List<UserInfoModel> selectedList;
  SelectUserstoBuyTicketFrom({required this.onTap, required this.selectedList});
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 30,
      right: 30,
      child: GestureDetector(
        onTap: () {
          onTap();
        },
        child: SelectorContent(selectedList: selectedList),
      ),
    );
  }
}

class SelectorContent extends StatelessWidget {
  const SelectorContent({
    super.key,
    required this.selectedList,
  });

  final List<UserInfoModel> selectedList;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selectedList.isEmpty ? Colors.red[200] : Colors.green[400],
        borderRadius: BorderRadius.circular(4),
      ),
      width: 140,
      height: 40,
      child: Center(
        child: Text(
          selectedList.isEmpty
              ? 'Select Required Users'
              : 'Selected ${selectedList.length} required ticket${selectedList.length > 1 ? 's' : ''}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
