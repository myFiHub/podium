import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:podium/app/modules/createGroup/widgets/groupType_dropDown.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:podium/widgets/textField/textFieldRounded.dart';

import '../controllers/create_group_controller.dart';

class CreateGroupView extends GetView<CreateGroupController> {
  const CreateGroupView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
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
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Room Access',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                  DropDown(
                    items: [
                      DropDownItem(
                        value: RoomAccessTypes.public,
                        text: 'Public',
                      ),
                      DropDownItem(
                        value: RoomAccessTypes.onlyLink,
                        text: 'Only By Link',
                      ),
                      DropDownItem(
                        value: RoomAccessTypes.invitees,
                        text: 'Only Invited Users',
                      ),
                      DropDownItem(
                        value: RoomAccessTypes.onlyArenaTicketHolders,
                        text: 'Only Arena Ticket Holders',
                        enabled: false,
                      ),
                      DropDownItem(
                        value: RoomAccessTypes.onlyPodiumPassHolders,
                        text: 'Only Podium Pass Holders',
                        enabled: false,
                      ),
                    ],
                    selectedValue: selectedValue,
                    onChanged: (value) {
                      controller.setRoomPrivacyType(value);
                    },
                  ),
                ],
              );
            }),
            space10,
            Obx(() {
              final selectedValue = controller.roomSpeakerType.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Speaker Type',
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
                        value: RoomSpeakerTypes.onlyArenaTicketHolders,
                        text: 'Ticket Holders',
                        enabled: false,
                      ),
                    ],
                    selectedValue: selectedValue,
                    onChanged: (value) {
                      controller.setRoomSpeakingType(value);
                    },
                  ),
                ],
              );
            }),
            space10,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'adults only',
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
            ),
            space10,
            Obx(() {
              final loading = controller.isCreatingNewGroup.value;
              return Button(
                loading: loading,
                blockButton: true,
                type: ButtonType.gradient,
                onPressed: () {
                  controller.create();
                },
                text: 'create',
              );
            }),
          ],
        ),
      ),
    );
  }
}
