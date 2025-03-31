import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:podium/app/modules/createOutpost/widgets/addGuestsPopup.dart';
import 'package:podium/app/modules/createOutpost/widgets/addHostsPopup.dart';
import 'package:podium/app/modules/createOutpost/widgets/groupType_dropDown.dart';
import 'package:podium/app/modules/createOutpost/widgets/tags_input.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/providers/api/luma/models/addGuest.dart';
import 'package:podium/providers/api/luma/models/addHost.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:podium/widgets/textField/textFieldRounded.dart';
import 'package:shimmer/shimmer.dart';

import '../controllers/create_outpost_controller.dart';

class CreateGroupView extends GetView<CreateOutpostController> {
  const CreateGroupView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (res, r) {
        controller.introFinished(false);
      },
      child: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            // padding: const EdgeInsets.only(top: 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  space16,
                  const _TitleBar(),
                  //space10,
                  _SelectPicture(
                    key: controller.intro_selectImageKey,
                  ),
                  _RoomNameInput(
                    key: controller.intro_outpostNameKey,
                  ),
                  space5,
                  _SubjectInput(
                    key: controller.intro_outpostSubjectKey,
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  _TagsInput(
                    key: controller.intro_tagsKey,
                  ),
                  _SelectGroupAccessType(
                    key: controller.intro_outpostAccessTypeKey,
                  ),
                  space5,
                  _SelectGroupSpeakerType(
                    key: controller.intro_outpostSpeakerTypeKey,
                  ),
                  space5,
                  const _ScheduleToggle(),
                  space5,
                  const _AddLumaEventCheckboxAndButtons(),
                  space5,
                  const _AdultsCheckbox(),
                  space5,
                  const _RecordableCheckbox(),
                  space16,
                  const _CreateButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectPicture extends GetWidget<CreateOutpostController> {
  const _SelectPicture({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: GestureDetector(
        onTap: () {
          controller.pickImage();
        },
        child: Column(
          children: [
            Obx(
              () {
                final selectedFile = controller.fileLocalAddress.value;
                return Row(
                  children: [
                    selectedFile == ''
                        ? Assets.images.browse.image(
                            width: 64,
                            height: 64,
                          )
                        : GFAvatar(
                            backgroundImage: FileImage(File(selectedFile)),
                            shape: GFAvatarShape.circle,
                            radius: 50.0,
                          ),
                    space5,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select image from gallery',
                          style: TextStyle(
                            color: Colors.grey[200],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Select image from gallery',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    space10,
                  ],
                );
              },
            )
          ],
        ),
      ),
    );
  }
}

class _ScheduleToggle extends GetView<CreateOutpostController> {
  const _ScheduleToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isScheduled = controller.isScheduled.value;
      final scheduledFor = controller.scheduledFor.value;
      return Container(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isScheduled ? Colors.grey[700]! : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Scheduled Outpost',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Organize and notify in advance.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: isScheduled,
                    onChanged: (value) {
                      controller.toggleScheduled();
                    },
                    activeColor: Colors.lightGreen,
                    activeTrackColor: Colors.grey[200],
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
                    textStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    blockButton: true,
                    type: ButtonType.outline,
                    icon: const Icon(
                      Icons.calendar_month_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () {
                      controller.openCalendarBottomSheet();
                    });
              }),
          ],
        ),
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

class _TagsInput extends GetWidget<CreateOutpostController> {
  const _TagsInput({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: DynamicTags(
        onTagsChanged: (values) {
          controller.setTags(values);
        },
      ),
    );
  }
}

class _SubjectInput extends GetWidget<CreateOutpostController> {
  const _SubjectInput({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 55,
      child: Input(
        initialValue: controller.outpostSubject.value,
        hintText: 'Main Subject (optional)',
        onChanged: (value) => controller.outpostSubject.value = value,
        marginvertical: 0,
        paddinghorizontal: 0,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white),
      ),
    );
  }
}

class _TitleBar extends GetWidget<CreateOutpostController> {
  const _TitleBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    controller.contextForIntro = context;
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        "New Outpost",
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RoomNameInput extends GetWidget<CreateOutpostController> {
  const _RoomNameInput({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 55,
      child: Input(
        hintText: 'Outpost Name',
        onChanged: (value) => controller.outpostName.value = value,
        marginvertical: 0,
        paddinghorizontal: 0,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white),
      ),
    );
  }
}

class _CreateButton extends GetWidget<CreateOutpostController> {
  const _CreateButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.isCreatingNewOutpost.value;
      final shouldSelectTicketHolersForAccess =
          controller.shouldSelectTicketHolersForAccess;
      final shouldSelectTicketHolersForSpeaking =
          controller.shouldSelectTicketHolersForSpeaking;
      final isScheduled = controller.isScheduled.value;
      final scheduledFor = controller.scheduledFor.value;
      final hasThingsToDo = shouldSelectTicketHolersForAccess ||
          shouldSelectTicketHolersForSpeaking ||
          (isScheduled && scheduledFor == 0) ||
          (controller.addToLuma.value &&
              (controller.lumaGuests.isEmpty || controller.lumaHosts.isEmpty));

      return Button(
        loading: loading,
        blockButton: true,
        type: ButtonType.gradient,
        onPressed: hasThingsToDo
            ? null
            : () {
                controller.create();
              },
        text: 'Create New Outpost',
      );
    });
  }
}

class _AddLumaEventCheckboxAndButtons extends GetView<CreateOutpostController> {
  const _AddLumaEventCheckboxAndButtons({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final addToLumaEnabled = controller.addToLuma.value;
        final isScheduled = controller.isScheduled.value;
        final scheduledFor = controller.scheduledFor.value;
        final hosts = controller.lumaHosts.value;
        final guests = controller.lumaGuests.value;
        if (!isScheduled || scheduledFor == 0) {
          return const SizedBox.shrink();
        }
        return Container(
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: addToLumaEnabled ? Colors.grey[700]! : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.white,
                        highlightColor: ColorName.primaryBlue,
                        child: const Text(
                          "Add Outpost event to Luma",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  GFCheckbox(
                    value: addToLumaEnabled,
                    activeBgColor: ColorName.primaryBlue,
                    size: 24,
                    onChanged: (value) {
                      controller.addToLuma.value = value;
                    },
                  )
                ],
              ),
              if (addToLumaEnabled)
                Row(
                  children: [
                    SizedBox(
                      width: (Get.width / 2) - 26,
                      child: _AddLumaEventHostsButton(
                        hosts: hosts,
                      ),
                    ),
                    space10,
                    SizedBox(
                      width: (Get.width / 2) - 26,
                      child: _AddLumaEventGuestsButton(
                        guests: guests,
                      ),
                    ),
                  ],
                )
            ],
          ),
        );
      },
    );
  }
}

class _AddLumaEventHostsButton extends GetView<CreateOutpostController> {
  final List<AddHostModel> hosts;
  const _AddLumaEventHostsButton({
    super.key,
    required this.hosts,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      type: hosts.length == 0 ? ButtonType.gradient : ButtonType.outline,
      onPressed: () {
        openAddHostsDialog();
      },
      text: hosts.length == 0 ? 'Add Hosts' : '${hosts.length} hosts',
    );
  }
}

class _AddLumaEventGuestsButton extends GetView<CreateOutpostController> {
  final List<AddGuestModel> guests;
  const _AddLumaEventGuestsButton({
    super.key,
    required this.guests,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      type: guests.length == 0 ? ButtonType.gradient : ButtonType.outline,
      onPressed: () {
        openAddGuestsDialog();
      },
      text: guests.length == 0 ? 'Add Guests' : '${guests.length} guests',
    );
  }
}

class _AdultsCheckbox extends GetView<CreateOutpostController> {
  const _AdultsCheckbox({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Adults speaking',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            Text(
              'Room content for 18+',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
            ),
          ],
        ),
        Obx(
          () {
            final isChecked = controller.newOutpostHasAdultContent.value;
            return GFCheckbox(
              value: isChecked,
              activeBgColor: Colors.red,
              size: 24,
              onChanged: (value) {
                controller.newOutpostHasAdultContent.value = value;
              },
            );
          },
        ),
      ],
    );
  }
}

class _RecordableCheckbox extends GetView<CreateOutpostController> {
  const _RecordableCheckbox();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recordable',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            Text(
              'Outpost sessions can be recorded by you',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
            ),
          ],
        ),
        Obx(
          () {
            final isChecked = controller.newOutpostIsRecorable.value;
            return GFCheckbox(
              value: isChecked,
              activeBgColor: Colors.red,
              size: 24,
              onChanged: (value) {
                controller.newOutpostIsRecorable.value = value;
              },
            );
          },
        ),
      ],
    );
  }
}

class _SelectGroupSpeakerType extends GetWidget<CreateOutpostController> {
  const _SelectGroupSpeakerType({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedValue = controller.outpostSpeakerType.value;
      return Container(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Allowed to Speak',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
                space5,
                DropDown(
                  items: [
                    DropDownItem(
                      value: FreeOutpostSpeakerTypes.everyone,
                      text: 'Everyone',
                    ),
                    DropDownItem(
                      value: FreeOutpostSpeakerTypes.invitees,
                      text: 'Only Invited Users',
                    ),
                    DropDownItem(
                      value: BuyableTicketTypes.onlyPodiumPassHolders,
                      text: 'Podium Pass Holders',
                    ),
                    // DropDownItem(
                    //   value: BuyableTicketTypes.onlyArenaTicketHolders,
                    //   text: 'Arena Ticket Holders',
                    // ),
                    // DropDownItem(
                    //   value: BuyableTicketTypes.onlyFriendTechTicketHolders,
                    //   text: 'FriendTech Key Holders',
                    // ),
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
                return const SizedBox();
              },
            ),
          ],
        ),
      );
    });
  }
}

class _SelectGroupAccessType extends GetWidget<CreateOutpostController> {
  const _SelectGroupAccessType({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedValue = controller.outpostAccessType.value;
      return Stack(
        children: [
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Allowed to Enter',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
                space5,
                DropDown(
                  items: [
                    DropDownItem(
                      value: FreeOutpostAccessTypes.public,
                      text: 'Everyone',
                    ),
                    DropDownItem(
                      value: FreeOutpostAccessTypes.onlyLink,
                      text: 'Users having the Link',
                    ),
                    DropDownItem(
                      value: FreeOutpostAccessTypes.invitees,
                      text: 'Invited Users',
                    ),
                    DropDownItem(
                      value: BuyableTicketTypes.onlyPodiumPassHolders,
                      text: 'Podium Pass Holders',
                    ),
                    // DropDownItem(
                    //   value: BuyableTicketTypes.onlyArenaTicketHolders,
                    //   text: 'Arena Ticket Holders',
                    //   // enabled: false,
                    // ),
                    // DropDownItem(
                    //   value: BuyableTicketTypes.onlyFriendTechTicketHolders,
                    //   text: 'FriendTech Key Holders',
                    // ),
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
            return const SizedBox();
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
      top: 35,
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
      height: 25,
      child: Center(
        child: Text(
          selectedListLength == 0
              ? 'Select tickets'
              : '${selectedListLength} required ticket${selectedListLength > 1 ? 's' : ''}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
