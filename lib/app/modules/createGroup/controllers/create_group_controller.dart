import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/utils/navigation/navigation.dart';

class CreateGroupController extends GetxController {
  final groupsController = Get.find<GroupsController>();
  final isCreatingNewGroup = false.obs;
  final roomPrivacyType = RoomAccessTypes.public.obs;
  final roomSpeakerType = RoomSpeakerTypes.everyone.obs;
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
    roomPrivacyType.value = value;
  }

  setRoomSpeakingType(String value) {
    roomSpeakerType.value = value;
  }

  setRoomSubject(String value) {
    roomSubject.value = value;
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
    await groupsController.createGroup(
      name: groupName.value,
      privacyType: roomPrivacyType.value,
      speakerType: roomSpeakerType.value,
      subject: subject,
    );
    isCreatingNewGroup.value = false;
    Navigate.to(
      type: NavigationTypes.offAllAndToNamed,
      route: Routes.HOME,
    );
  }
}

class RoomAccessTypes {
  static const public = 'public';
  static const onlyLink = 'onlyLink';
  static const onlyArenaTicketHolders = 'onlyArenaTicketHolders';
  static const onlyPodiumPassHolders = 'onlyPodiumPassHolders';
}

class RoomSpeakerTypes {
  static const everyone = 'everyone';
  static const invitees = 'invitees';
  static const onlyCreator = 'onlyCreator';
  static const onlyArenaTicketHolders = 'onlyArenaTicketHolders';
  static const onlyPodiumPassHolders = 'onlyPodiumPassHolders';
}

const defaultSubject = "anything";
