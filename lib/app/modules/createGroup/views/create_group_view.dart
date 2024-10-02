import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:podium/app/modules/createGroup/widgets/groupType_dropDown.dart';
import 'package:podium/app/modules/createGroup/widgets/tags_input.dart';
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
                RoomNameInput(),
                SubjectInput(),
                TagsInput(),
                SelectRoomAccessType(),
                space10,
                SelectRoomSpeakerType(),
                space10,
                ScheduleToggle(),
                space10,
                AdultsCheckbox(),
                space10,
                CreateButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ScheduleToggle extends GetView<CreateGroupController> {
  const ScheduleToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isScheduled = controller.isScheduled.value;
      final scheduledFor = controller.scheduledFor.value;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Schedule Room',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 18,
                  ),
                ),
                Switch(
                  value: isScheduled,
                  onChanged: (value) {
                    controller.toggleScheduled();
                  },
                ),
              ],
            ),
          ),
          space10,
          if (isScheduled)
            Builder(builder: (context) {
              final selected = scheduledFor != 0;
              return Button(
                  text: !selected
                      ? 'Select Date and Time'
                      : millisecondsToFormattedDateWithTime(scheduledFor),
                  blockButton: true,
                  type: ButtonType.outline,
                  icon: Icon(
                    Icons.calendar_month_outlined,
                    color: Colors.grey[400],
                  ),
                  onPressed: () {
                    controller.openCalendarBottomSheet();
                  });
            }),
        ],
      );
    });
  }
}

millisecondsToFormattedDateWithTime(int milliseconds) {
// if a number is less than 10, add a 0 before it
  String addZero(int number) {
    return number < 10 ? '0$number' : number.toString();
  }

  final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
  final day = addZero(date.day);
  final month = addZero(date.month);
  final year = date.year;
  final hour = addZero(date.hour);
  final minute = addZero(date.minute);
  return '$day/$month/$year $hour:$minute';
}

class TagsInput extends GetWidget<CreateGroupController> {
  const TagsInput({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DynamicTags(
      onTagsChanged: (values) {
        controller.setTags(values);
      },
    );
  }
}

class SubjectInput extends GetWidget<CreateGroupController> {
  const SubjectInput({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Input(
      initialValue: controller.roomSubject.value,
      hintText: 'Main Subject (optional)',
      onChanged: (value) => controller.roomSubject.value = value,
      marginvertical: 0,
    );
  }
}

class RoomNameInput extends GetWidget<CreateGroupController> {
  const RoomNameInput({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Input(
      hintText: 'Room Name',
      onChanged: (value) => controller.groupName.value = value,
      marginvertical: 0,
    );
  }
}

class CreateButton extends GetWidget<CreateGroupController> {
  const CreateButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.isCreatingNewGroup.value;
      final shouldSelectTicketHolersForAccess =
          controller.shouldSelectTicketHolersForAccess;
      final shouldSelectTicketHolersForSpeaking =
          controller.shouldSelectTicketHolersForSpeaking;
      final isScheduled = controller.isScheduled.value;
      final scheduledFor = controller.scheduledFor.value;
      final hasThingsToDo = shouldSelectTicketHolersForAccess ||
          shouldSelectTicketHolersForSpeaking ||
          (isScheduled && scheduledFor == 0);

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
    });
  }
}

class AdultsCheckbox extends GetView<CreateGroupController> {
  const AdultsCheckbox({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
            final isChecked = controller.newGroupHasAdultContent.value;
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
    );
  }
}

class SelectRoomSpeakerType extends GetWidget<CreateGroupController> {
  const SelectRoomSpeakerType({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
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
                      value: FreeRoomSpeakerTypes.everyone,
                      text: 'Everyone',
                    ),
                    DropDownItem(
                      value: FreeRoomSpeakerTypes.invitees,
                      text: 'Only Invited Users',
                    ),
                    DropDownItem(
                      value: BuyableTicketTypes.onlyArenaTicketHolders,
                      text: 'Arena Ticket Holders',
                    ),
                    DropDownItem(
                      value: BuyableTicketTypes.onlyFriendTechTicketHolders,
                      text: 'FriendTech Ticket Holders',
                    ),
                    DropDownItem(
                      value: BuyableTicketTypes.onlyPodiumPassHolders,
                      text: 'Podium Pass Holders',
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
                    controller.selectedUsersToBuyticketFrom_ToSpeak.value;
                final numberOfAddressesToAdd =
                    controller.addressesToAddForSpeaking;
                if (controller.shouldBuyTicketToSpeak) {
                  return SelectUserstoBuyTicketFrom(
                    onTap: () {
                      controller.openSelectTicketBottomSheet(
                        buyTicketToGetPermisionFor: TicketPermissionType.speak,
                      );
                    },
                    selectedListLength:
                        selectedList.length + numberOfAddressesToAdd.length,
                  );
                }
                return SizedBox();
              },
            ),
          ],
        ),
      );
    });
  }
}

class SelectRoomAccessType extends GetWidget<CreateGroupController> {
  const SelectRoomAccessType({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
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
                      value: FreeRoomAccessTypes.public,
                      text: 'Everyone',
                    ),
                    DropDownItem(
                      value: FreeRoomAccessTypes.onlyLink,
                      text: 'Users having the Link',
                    ),
                    DropDownItem(
                      value: FreeRoomAccessTypes.invitees,
                      text: 'Invited Users',
                    ),
                    DropDownItem(
                      value: BuyableTicketTypes.onlyArenaTicketHolders,
                      text: 'Arena Ticket Holders',
                      // enabled: false,
                    ),
                    DropDownItem(
                      value: BuyableTicketTypes.onlyFriendTechTicketHolders,
                      text: 'FriendTech Ticket Holders',
                    ),
                    DropDownItem(
                      value: BuyableTicketTypes.onlyPodiumPassHolders,
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
            final selectedList =
                controller.selectedUsersToBuyTicketFrom_ToAccessRoom.value;
            final addresses = controller.addressesToAddForEntering;
            if (controller.shouldBuyTicketToAccess) {
              return SelectUserstoBuyTicketFrom(
                onTap: () {
                  controller.openSelectTicketBottomSheet(
                    buyTicketToGetPermisionFor: TicketPermissionType.access,
                  );
                },
                selectedListLength: selectedList.length + addresses.length,
              );
            }
            return SizedBox();
          }),
        ],
      );
    });
  }
}

class SelectUserstoBuyTicketFrom extends StatelessWidget {
  final Function onTap;
  final int selectedListLength;
  SelectUserstoBuyTicketFrom(
      {required this.onTap, required this.selectedListLength});
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 30,
      right: 30,
      child: GestureDetector(
        onTap: () {
          onTap();
        },
        child: SelectorContent(selectedListLength: selectedListLength),
      ),
    );
  }
}

class SelectorContent extends StatelessWidget {
  const SelectorContent({
    super.key,
    required this.selectedListLength,
  });

  final int selectedListLength;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: selectedListLength == 0 ? Colors.red[200] : Colors.green[400],
        borderRadius: BorderRadius.circular(4),
      ),
      // width: 140,
      height: 40,
      child: Center(
        child: Text(
          selectedListLength == 0
              ? 'Select Tickets'
              : '${selectedListLength} required ticket${selectedListLength > 1 ? 's' : ''}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
