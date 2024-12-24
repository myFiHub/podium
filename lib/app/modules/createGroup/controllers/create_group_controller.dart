import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:getwidget/getwidget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/popUpsAndModals/setReminder.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/getWeb3AuthWalletAddress.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/constants/constantKeys.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/customLibs/omniDatePicker/omni_datetime_picker.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/models/starsArenaUser.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/storage.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/utils/throttleAndDebounce/debounce.dart';
import 'package:podium/utils/truncate.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:podium/widgets/textField/textFieldRounded.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:uuid/uuid.dart';

final _deb = Debouncing(duration: const Duration(seconds: 1));

class TicketSellersListMember {
  final UserInfoModel user;
  final String activeAddress;
  TicketSellersListMember({required this.user, required this.activeAddress});
}

class SearchedUser {
  final UserInfoModel? podiumUserInfo;
  final StarsArenaUser? arenaUserInfo;
  final bool? isArenaUser;
  SearchedUser({
    this.podiumUserInfo,
    this.arenaUserInfo,
    this.isArenaUser = false,
  });
}

class CreateGroupController extends GetxController {
  final groupsController = Get.find<GroupsController>();
  final storage = GetStorage();
  final isCreatingNewGroup = false.obs;
  final newGroupHasAdultContent = false.obs;
  final newGroupIsRecorable = false.obs;
  final groupAccessType = FreeGroupAccessTypes.public.obs;
  final groupSpeakerType = FreeGroupSpeakerTypes.everyone.obs;

  final intro_selectImageKey = GlobalKey();
  final intro_groupNameKey = GlobalKey();
  final intro_tagsKey = GlobalKey();
  final intro_groupSubjectKey = GlobalKey();
  final intro_groupAccessTypeKey = GlobalKey();
  final intro_groupSpeakerTypeKey = GlobalKey();
  BuildContext? contextForIntro;
  late TutorialCoachMark tutorialCoachMark;

  final selectedUsersToBuyTicketFrom_ToAccessRoom =
      <TicketSellersListMember>[].obs;
  final selectedUsersToBuyticketFrom_ToSpeak = <TicketSellersListMember>[].obs;
  final listOfSearchedUsersToBuyTicketFrom = <SearchedUser>[].obs;
  final addressesToAddForEntering = RxList<String>([]);
  final addressesToAddForSpeaking = RxList<String>([]);
  final loadingUserIds = RxList<String>([]);
  final loadingAddresses = RxList<String>([]);
  final showLoadingOnSearchInput = false.obs;
  final isScheduled = false.obs;
  final scheduledFor = 0.obs;
  final searchValueForSeletTickets = "".obs;
  final tags = RxList<String>([]);
  final roomSubject = defaultSubject.obs;
  final groupName = "".obs;

// image
  final fileLocalAddress = ''.obs;
  final ImagePicker _picker = ImagePicker();
  File? selectedFile;
  //end

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
    final alreadyViewed = storage.read(IntroStorageKeys.viewedCreateGroup);
    if (
        //
        // true
        alreadyViewed == null
        //
        ) {
      // wait for the context to be ready
      Future.delayed(const Duration(seconds: 0)).then((v) {
        tutorialCoachMark = TutorialCoachMark(
          targets: _createTargets(),
          paddingFocus: 5,
          opacityShadow: 0.5,
          skipWidget: Button(
            size: ButtonSize.SMALL,
            type: ButtonType.outline,
            color: Colors.red,
            onPressed: () {
              saveIntroAsDone(true);
            },
            child: const Text("Finish"),
          ),
          imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          onFinish: () {
            saveIntroAsDone(true);
          },
          onClickTarget: (target) {
            print('onClickTarget: $target');
          },
          onClickTargetWithTapPosition: (target, tapDetails) {
            print("target: $target");
            print(
                "clicked at position local: ${tapDetails.localPosition} - global: ${tapDetails.globalPosition}");
          },
          onClickOverlay: (target) {
            print('onClickOverlay: $target');
          },
          onSkip: () {
            saveIntroAsDone(true);
            return true;
          },
        );
        try {
          tutorialCoachMark.show(context: contextForIntro!);
        } catch (e) {
          l.e(e);
        }
      });
    }
  }

  List<TargetFocus> _createTargets() {
    List<TargetFocus> targets = [];
    targets.add(
      _createStep(
        targetId: intro_selectImageKey,
        text:
            "you can select an image for your Outpost, it is optional but recommended",
      ),
    );
    targets.add(
      _createStep(
        targetId: intro_groupSubjectKey,
        text:
            "enter the main subject of your outpost, to help people understand what it is about",
      ),
    );
    targets.add(
      _createStep(
        targetId: intro_tagsKey,
        text: "you can add tags to your outpost, to help people find it",
      ),
    );

    targets.add(
      _createStep(
        targetId: intro_groupAccessTypeKey,
        text: "you can select the access type of your outpost",
      ),
    );

    targets.add(
      _createStep(
        targetId: intro_groupSpeakerTypeKey,
        text: "you can select the speaker type of your outpost",
        hasNext: false,
      ),
    );
    return targets;
  }

  @override
  void onClose() {
    super.onClose();
  }

  _createStep({
    required GlobalKey targetId,
    required String text,
    bool hasNext = true,
  }) {
    return TargetFocus(
      identify: targetId.toString(),
      keyTarget: targetId,
      alignSkip: Alignment.bottomRight,
      paddingFocus: 0,
      focusAnimationDuration: const Duration(milliseconds: 300),
      unFocusAnimationDuration: const Duration(milliseconds: 100),
      shape: ShapeLightFocus.RRect,
      color: Colors.black,
      enableOverlayTab: true,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
                if (hasNext)
                  Button(
                    size: ButtonSize.SMALL,
                    type: ButtonType.outline,
                    color: Colors.white,
                    onPressed: () {
                      tutorialCoachMark.next();
                    },
                    child: const Text(
                      "Next",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                else
                  Button(
                    size: ButtonSize.SMALL,
                    type: ButtonType.outline,
                    color: Colors.white,
                    onPressed: () {
                      introFinished(true);
                    },
                    child: const Text(
                      "Finish",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  void saveIntroAsDone(bool? setAsFinished) {
    if (setAsFinished == true) {
      storage.write(IntroStorageKeys.viewedCreateGroup, true);
    }
  }

  void introFinished(bool? setAsFinished) {
    saveIntroAsDone(setAsFinished);
    try {
      tutorialCoachMark.finish();
    } catch (e) {}
  }

  pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      selectedFile = File(pickedFile
          .path); // Use this to store the image in the database or cloud storage
      fileLocalAddress.value = pickedFile.path;
    } else {
      l.e('No image selected.');
    }
  }

  Future<String?> uploadFile({required groupId}) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('${FireBaseConstants.groupsRef}$groupId');

    if (selectedFile == null) {
      return "";
    }
    // check if file is less than 2mb
    final fileSize = selectedFile!.lengthSync();
    if (fileSize > 2 * 1024 * 1024) {
      Toast.error(message: 'Image size must be less than 2MB');
      return null;
    }
    // Upload the image to Firebase Storage
    final uploadTask = storageRef.putFile(selectedFile!);

    // Wait for the upload to complete
    final snapshot = await uploadTask.whenComplete(() {});

    // Get the download URL of the uploaded image
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  toggleScheduled() {
    isScheduled.value = !isScheduled.value;
  }

  setTags(List<String> values) {
    tags.value = values;
  }

  setRoomPrivacyType(String value) {
    groupAccessType.value = value;
  }

  setRoomSpeakingType(String value) {
    groupSpeakerType.value = value;
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
      firstDate: DateTime.now().add(const Duration(minutes: 5)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      minutesInterval: 5,
    );
    if (dateTime != null) {
      scheduledFor.value = dateTime.millisecondsSinceEpoch;
    }
    return scheduledFor.value;
  }

  get shouldSelectTicketHolersForSpeaking {
    return (groupSpeakerType.value ==
                BuyableTicketTypes.onlyFriendTechTicketHolders ||
            groupSpeakerType.value ==
                BuyableTicketTypes.onlyArenaTicketHolders ||
            groupSpeakerType.value ==
                BuyableTicketTypes.onlyPodiumPassHolders) &&
        selectedUsersToBuyticketFrom_ToSpeak.isEmpty &&
        addressesToAddForSpeaking.isEmpty;
  }

  get shouldSelectTicketHolersForAccess {
    return ((groupAccessType.value ==
                BuyableTicketTypes.onlyFriendTechTicketHolders) ||
            groupAccessType.value ==
                BuyableTicketTypes.onlyArenaTicketHolders ||
            groupAccessType.value ==
                BuyableTicketTypes.onlyPodiumPassHolders) &&
        selectedUsersToBuyTicketFrom_ToAccessRoom.isEmpty &&
        addressesToAddForEntering.isEmpty;
  }

  get shouldBuyTicketToSpeak {
    return groupSpeakerType.value ==
            BuyableTicketTypes.onlyFriendTechTicketHolders ||
        groupSpeakerType.value == BuyableTicketTypes.onlyArenaTicketHolders ||
        groupSpeakerType.value == BuyableTicketTypes.onlyPodiumPassHolders;
  }

  get shouldBuyTicketToAccess {
    return groupAccessType.value ==
            BuyableTicketTypes.onlyFriendTechTicketHolders ||
        groupAccessType.value == BuyableTicketTypes.onlyArenaTicketHolders ||
        groupAccessType.value == BuyableTicketTypes.onlyPodiumPassHolders;
  }

  toggleAddressForSelectedList({
    required String address,
    required String ticketPermissionType,
  }) async {
    final list = ticketPermissionType == TicketPermissionType.speak
        ? addressesToAddForSpeaking
        : addressesToAddForEntering;
    final ticketType = ticketPermissionType == TicketPermissionType.speak
        ? groupSpeakerType.value
        : groupAccessType.value;
    if (list.contains(address)) {
      list.remove(address);
    } else {
      if (!loadingAddresses.contains(address)) {
        loadingAddresses.add(address);
      }
      final isActive =
          ticketType != BuyableTicketTypes.onlyFriendTechTicketHolders
              ? true
              : (await internal_friendTech_getActiveUserWallets(
                  internalWalletAddress: address,
                  chainId: baseChainId,
                ))
                  .hasActiveWallet;
      // remove from loading
      loadingAddresses.remove(address);
      if (isActive) {
        list.add(address);
      } else {
        Toast.warning(
          title: "Address isn't yet active on FriendTech",
          message: "",
        );
      }
    }
  }

  toggleArenaUser({
    required StarsArenaUser user,
    required String ticketPermissiontype,
  }) {
    final list = ticketPermissiontype == TicketPermissionType.speak
        ? selectedUsersToBuyticketFrom_ToSpeak
        : selectedUsersToBuyTicketFrom_ToAccessRoom;
    if (user.address.isEmpty) {
      Toast.error(message: 'User has no wallet address');
      return;
    }
    final usersMap = list.map((e) => e.user.id).toList();
    if (usersMap.contains(arenaUserIdPrefix + user.id)) {
      list.removeWhere((e) => e.user.id == arenaUserIdPrefix + user.id);
    } else {
      list.add(TicketSellersListMember(
        user: UserInfoModel(
          id: arenaUserIdPrefix + user.id,
          fullName: user.twitterName,
          email: '',
          avatar: user.twitterPicture,
          evm_externalWalletAddress: user.mainAddress,
          following: [],
          numberOfFollowers: user.followerCount,
          evmInternalWalletAddress: user.mainAddress,
        ),
        activeAddress: user.mainAddress,
      ));
    }
  }

  toggleUserToSelectedList({
    required UserInfoModel user,
    required String ticketPermissiontype,
  }) async {
    final list = ticketPermissiontype == TicketPermissionType.speak
        ? selectedUsersToBuyticketFrom_ToSpeak
        : selectedUsersToBuyTicketFrom_ToAccessRoom;
    final ticketType = ticketPermissiontype == TicketPermissionType.speak
        ? groupSpeakerType.value
        : groupAccessType.value;
    if (user.defaultWalletAddress.isEmpty) {
      Toast.error(message: 'User has no wallet address');
      return;
    }

    final usersMap = list.map((e) => e.user.id).toList();
    if (usersMap.contains(user.id)) {
      list.removeWhere((e) => e.user.id == user.id);
    } else {
      String? activeAddress =
          ticketType != BuyableTicketTypes.onlyFriendTechTicketHolders
              ? user.defaultWalletAddress
              : await checkIfUserCanBeAddedToList(
                  user: user,
                  ticketPermissionType: ticketPermissiontype,
                );
      if (ticketType == BuyableTicketTypes.onlyPodiumPassHolders) {
        activeAddress = user.aptosInternalWalletAddress;
      }
      if (activeAddress != null) {
        list.add(TicketSellersListMember(
          user: user,
          activeAddress: activeAddress,
        ));
      }
    }
  }

  bool _shouldCheckIfUserIsActive(String ticketPermissionType) {
    if (ticketPermissionType == TicketPermissionType.access &&
        groupAccessType.value ==
            BuyableTicketTypes.onlyFriendTechTicketHolders) {
      return true;
    }
    if (ticketPermissionType == TicketPermissionType.speak &&
        groupSpeakerType.value ==
            BuyableTicketTypes.onlyFriendTechTicketHolders) {
      return true;
    }
    return false;
  }

  Future<String?> checkIfUserCanBeAddedToList({
    required UserInfoModel user,
    required String ticketPermissionType,
  }) async {
    if (!_shouldCheckIfUserIsActive(ticketPermissionType)) {
      return user.defaultWalletAddress;
    }
    loadingUserIds.add(user.id);
    try {
      final activeWallets = await internal_friendTech_getActiveUserWallets(
        internalWalletAddress: user.evmInternalWalletAddress,
        externalWalletAddress: user.defaultWalletAddress,
        chainId: baseChainId,
      );
      final isActive = activeWallets.hasActiveWallet;
      final preferedWalletAddress = activeWallets.preferedWalletAddress;
      if (isActive) {
        return preferedWalletAddress;
      } else {
        if (user.id != myId) {
          Toast.warning(
            title: "User isn't yet active on FriendTech",
            message: "",
          );
          return null;
        } else {
          final agreedToBuyTicketForSelf = await showActivatePopup();
          if (agreedToBuyTicketForSelf != true) {
            return null;
          }
          final selectedWallet = await choseAWallet(chainId: baseChainId);
          if (selectedWallet == null) {
            return null;
          }
          if (selectedWallet == WalletNames.internal_EVM) {
            final bought = await internal_activate_friendtechWallet(
              chainId: baseChainId,
            );
            if (bought) {
              Toast.success(message: 'Account activated');
              return await web3AuthWalletAddress(); //await Evm.getAddress();
            } else {
              return null;
            }
          } else {
            final bought = await ext_activate_friendtechWallet(
              chainId: baseChainId,
            );
            if (bought) {
              Toast.success(message: 'Account activated');
              return externalWalletAddress;
            } else {
              return null;
            }
          }
        }
      }
    } catch (e) {
      l.e(e);
      return null;
    } finally {
      loadingUserIds.remove(user.id);
    }
  }

  removeAddressForEntering(String address) {
    addressesToAddForEntering.remove(address);
  }

  removeAddressForSpeaking(String address) {
    addressesToAddForSpeaking.remove(address);
  }

  searchUsers(String value, {String? ticketType}) async {
    searchValueForSeletTickets.value = value;
    if (value.isEmpty) {
      listOfSearchedUsersToBuyTicketFrom.value = [];
      return;
    }
    // loadingAddresses.add(value);
    showLoadingOnSearchInput.value = true;
    l.d(ticketType);
    _deb.debounce(() async {
      try {
        checkIfValueIsDirectAddress(value);
        final (users, arenaUser) = await (
          searchForUserByName(value),
          ticketType == BuyableTicketTypes.onlyArenaTicketHolders
              ? HttpApis.getUserFromStarsArenaByHandle(value)
              : Future.value(null)
        ).wait;
        final podiumUsers = users.values
            .toList()
            .map((e) => SearchedUser(
                  podiumUserInfo: e,
                ))
            .toList();
        listOfSearchedUsersToBuyTicketFrom.value = [
          if (arenaUser != null)
            SearchedUser(
              arenaUserInfo: arenaUser,
              isArenaUser: true,
            ),
          ...podiumUsers
        ];
      } catch (e) {
      } finally {
        showLoadingOnSearchInput.value = false;
      }
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
      Toast.error(message: 'room name cannot be empty');
      return;
    } else if (groupName.value.length < 5) {
      Toast.error(message: 'room name must be at least 5 characters');
      return;
    }

    final alarmId = Random().nextInt(100000000);
    if (scheduledFor.value != 0) {
      final setFor = await setReminder(
        alarmId: alarmId,
        scheduledFor: scheduledFor.value,
        eventName: groupName.value,
        timesList: defaultTimeList(
          endsAt: scheduledFor.value,
        ),
      );
      if (setFor == -1) {
        // means use calendar
      }
      if (setFor == -2) {
        // means no reminder
      } else if (setFor == null) {
        // means tap on back or outside
        return;
      }
    }

    String subject = roomSubject.value;
    if (subject.isEmpty) {
      subject = defaultSubject;
    }
    isCreatingNewGroup.value = true;
    final accessType = groupAccessType.value;
    final speakerType = groupSpeakerType.value;
    final id = const Uuid().v4();
    String imageUrl = "";
    if (selectedFile != null) {
      final res = await uploadFile(groupId: id);
      if (res == null) {
        return;
      }
      imageUrl = res;
    }

    try {
      await groupsController.createGroup(
        id: id,
        imageUrl: imageUrl,
        name: groupName.value,
        accessType: accessType,
        speakerType: speakerType,
        subject: subject,
        tags: tags.value,
        adultContent: newGroupHasAdultContent.value,
        recordable: newGroupIsRecorable.value,
        requiredTicketsToAccess:
            selectedUsersToBuyTicketFrom_ToAccessRoom.value,
        requiredTicketsToSpeak: selectedUsersToBuyticketFrom_ToSpeak.value,
        requiredAddressesToEnter: addressesToAddForEntering.value,
        requiredAddressesToSpeak: addressesToAddForSpeaking.value,
        scheduledFor: scheduledFor.value,
        alarmId: alarmId,
      );
      // preventing from creating the same name if controller is not deleted
      groupName.value = "";
    } catch (e) {}
    isCreatingNewGroup.value = false;
  }

  openSelectTicketBottomSheet({
    required String buyTicketToGetPermisionFor,
  }) {
    searchValueForSeletTickets.value = "";
    Get.dialog(
      SelectUsersToBuyTicketFromBottomSheetContent(
        buyTicketToGetPermisionFor: buyTicketToGetPermisionFor,
      ),
    );
  }
}

Future<bool?> showActivatePopup() async {
  return await Get.dialog<bool>(
    AlertDialog(
      backgroundColor: ColorName.cardBackground,
      title: const Text('Activate Wallet'),
      content: RichText(
        text: TextSpan(
          text:
              'You need to activate your wallet to buy tickets for this event. Do you want to activate it now?',
          style: const TextStyle(color: Colors.white),
          children: [
            if (externalWalletAddress == null)
              const TextSpan(
                text:
                    '\n(your external wallet is disconnected\n we checked against your Podium wallet address)',
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(Get.overlayContext!).pop(false);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(Get.overlayContext!).pop(true);
          },
          child: const Text('Activate'),
        ),
      ],
    ),
  );
}

class ScheduledGroupDateSelector extends GetView<CreateGroupController> {
  const ScheduledGroupDateSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        width: Get.width,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: ColorName.cardBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: const Column(
          children: [
            const Text('Select Date and Time'),
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
          padding: const EdgeInsets.all(20),
          height: Get.height * 0.5,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Search user',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      controller.listOfSearchedUsersToBuyTicketFrom.value = [];
                      Get.close();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              space10,
              Obx(() {
                final searchValue = controller.searchValueForSeletTickets.value;
                final loadingAddresses = controller.loadingAddresses.value;
                final hasLoadingAddress = loadingAddresses.isNotEmpty;
                final isInputBusy = controller.showLoadingOnSearchInput.value;
                final ticketType =
                    buyTicketToGetPermisionFor == TicketPermissionType.speak
                        ? controller.groupSpeakerType.value
                        : controller.groupAccessType.value;
                bool isAddress =
                    controller.checkIfValueIsDirectAddress(searchValue);
                try {} catch (e) {}
                return SizedBox(
                  height: 70,
                  child: Input(
                    controller: inputController,
                    suffixIcon: hasLoadingAddress || isInputBusy
                        ? const SizedBox(
                            width: 50,
                            child: const GFLoader(),
                          )
                        : searchValue.isEmpty
                            ? IconButton(
                                onPressed: () async {
                                  final clipboardData = await Clipboard.getData(
                                      Clipboard.kTextPlain);
                                  String? clipboardText = clipboardData?.text;
                                  if (clipboardText != null) {
                                    if (controller.checkIfValueIsDirectAddress(
                                        clipboardText)) {
                                      if (buyTicketToGetPermisionFor ==
                                          TicketPermissionType.speak) {
                                        controller.toggleAddressForSelectedList(
                                          address: clipboardText,
                                          ticketPermissionType:
                                              TicketPermissionType.speak,
                                        );
                                      } else if (buyTicketToGetPermisionFor ==
                                          TicketPermissionType.access) {
                                        controller.toggleAddressForSelectedList(
                                          address: clipboardText,
                                          ticketPermissionType:
                                              TicketPermissionType.access,
                                        );
                                      }
                                    } else {
                                      inputController.text = clipboardText;
                                      controller.searchUsers(
                                        clipboardText,
                                        ticketType: ticketType,
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(
                                  Icons.paste,
                                  color: Colors.grey,
                                ),
                              )
                            : isAddress
                                ? IconButton(
                                    onPressed: () {
                                      if (buyTicketToGetPermisionFor ==
                                          TicketPermissionType.speak) {
                                        controller.toggleAddressForSelectedList(
                                          address: searchValue,
                                          ticketPermissionType:
                                              TicketPermissionType.speak,
                                        );
                                      } else if (buyTicketToGetPermisionFor ==
                                          TicketPermissionType.access) {
                                        controller.toggleAddressForSelectedList(
                                          address: searchValue,
                                          ticketPermissionType:
                                              TicketPermissionType.access,
                                        );
                                      }
                                      controller.searchUsers(
                                        '',
                                      );
                                      inputController.clear();
                                    },
                                    icon: const Icon(Icons.check,
                                        color: Colors.green),
                                  )
                                : IconButton(
                                    onPressed: () {
                                      controller.searchUsers('');
                                      inputController.clear();
                                    },
                                    icon: const Icon(Icons.close,
                                        color: Colors.red),
                                  ),
                    hintText:
                        'Enter the Name/address${ticketType == BuyableTicketTypes.onlyArenaTicketHolders ? '/handle' : ''}',
                    onChanged: (value) {
                      controller.searchUsers(value, ticketType: ticketType);
                    },
                    autofocus: true,
                  ),
                );
              }),
              Expanded(
                child: Container(
                  child: Obx(
                    () {
                      final podiumUsers = controller
                          .listOfSearchedUsersToBuyTicketFrom.value
                          .where(
                        (element) {
                          return element.isArenaUser != true &&
                              element.podiumUserInfo!.id != myId;
                        },
                      ).toList();

                      final loadingIds = controller.loadingUserIds.value;
                      final loadingAddresses =
                          controller.loadingAddresses.value;
                      final selsectedListOfUsersToBuyTicketFromInOrderToSpeak =
                          controller.selectedUsersToBuyticketFrom_ToSpeak.value;
                      final selsectedListOfUsersToBuyTicketFromInOrderToAccessRoom =
                          controller
                              .selectedUsersToBuyTicketFrom_ToAccessRoom.value;
                      List<String> selectedIds = [];
                      List<UserInfoModel> selectedUsers;
                      if (buyTicketToGetPermisionFor ==
                          TicketPermissionType.speak) {
                        selectedUsers =
                            selsectedListOfUsersToBuyTicketFromInOrderToSpeak
                                .map((e) => e.user)
                                .toList();
                        selectedIds = selectedUsers.map((e) => e.id).toList();
                      } else if (buyTicketToGetPermisionFor ==
                          TicketPermissionType.access) {
                        selectedUsers =
                            selsectedListOfUsersToBuyTicketFromInOrderToAccessRoom
                                .map((e) => e.user)
                                .toList();
                        selectedIds = selectedUsers.map((e) => e.id).toList();
                      } else {
                        return Container(
                          child: const Center(
                            child: const Text('Error, type is not valid'),
                          ),
                        );
                      }
                      // move selectedIds to the top of the list then my id to the top of them
                      List<UserInfoModel> listOfUsers = [];

                      final starsArenaUsers = controller
                          .listOfSearchedUsersToBuyTicketFrom.value
                          .where(
                        (element) {
                          return element.isArenaUser == true &&
                              !selectedIds.contains(arenaUserIdPrefix +
                                  element.arenaUserInfo!.id);
                        },
                      ).toList();

                      listOfUsers.add(myUser);
                      final SelectedUsersExceptMe =
                          selectedUsers.where((element) => element.id != myId);
                      listOfUsers.addAll([...SelectedUsersExceptMe]);
                      final notSelectedPodiumUsers = podiumUsers.where(
                          (element) => !selectedIds
                              .contains(element.podiumUserInfo!.id));
                      listOfUsers.addAll(notSelectedPodiumUsers.map(
                        (e) => e.podiumUserInfo!,
                      ));
                      final listOfAddresses = buyTicketToGetPermisionFor ==
                              TicketPermissionType.speak
                          ? controller.addressesToAddForSpeaking
                          : controller.addressesToAddForEntering;
                      List<SelectBoxOption> options = [];
                      for (var user in starsArenaUsers) {
                        options.add(
                            SelectBoxOption(arenaUser: user.arenaUserInfo));
                      }
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

                          if (element.arenaUser != null) {
                            final StarsArenaUser user = element.arenaUser!;

                            final verifiedOnArena = user.userConfirmed;
                            final verifiedOnTwitter = user.twitterConfirmed;
                            final numberOfFollowers = user.followerCount;
                            final fullName = user.twitterName;
                            final avatar = user.twitterPicture;
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 12, top: 6, bottom: 6),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Img(
                                                src: avatar,
                                                alt: fullName,
                                                size: 20,
                                              ),
                                              space5,
                                              Text(
                                                fullName,
                                              )
                                            ],
                                          ),
                                          Text(
                                            "Followers: ${numberOfFollowers}",
                                            style: const TextStyle(
                                              fontSize: 11,
                                            ),
                                          ),
                                          if (verifiedOnTwitter)
                                            Text(
                                              "verified on twitter",
                                              style: TextStyle(
                                                  color: Colors.blue[400],
                                                  fontSize: 12),
                                            ),
                                          if (verifiedOnTwitter &&
                                              verifiedOnArena)
                                            space5,
                                          if (verifiedOnArena)
                                            Text(
                                              "verified on Stars Arena",
                                              style: TextStyle(
                                                  color: Colors.red[400],
                                                  fontSize: 12),
                                            ),
                                        ],
                                      ),
                                      GFCheckbox(
                                          onChanged: (v) {
                                            controller.toggleArenaUser(
                                              user: element.arenaUser!,
                                              ticketPermissiontype:
                                                  buyTicketToGetPermisionFor,
                                            );
                                          },
                                          value: selectedIds.contains(
                                              arenaUserIdPrefix + user.id))
                                    ],
                                  ),
                                ),
                                Divider(color: Colors.grey[900]),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.only(left: 12),
                                title: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (element.user != null)
                                          Row(
                                            children: [
                                              Img(
                                                src: element.user?.avatar ==
                                                        defaultAvatar
                                                    ? ''
                                                    : element.user!.avatar,
                                                alt: element.user!.fullName,
                                                size: 20,
                                              ),
                                              space5
                                            ],
                                          ),
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
                                            style: const TextStyle(
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
                                            style: const TextStyle(
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
                                    if (element.user != null &&
                                        loadingIds.contains(element.user!.id))
                                      const Padding(
                                        padding: EdgeInsets.only(right: 18.0),
                                        child: GFLoader(),
                                      )
                                    else if (element.user != null)
                                      GFCheckbox(
                                        onChanged: (v) {
                                          if (element.user != null) {
                                            controller.toggleUserToSelectedList(
                                              user: element.user!,
                                              ticketPermissiontype:
                                                  buyTicketToGetPermisionFor,
                                            );
                                            return;
                                          }
                                        },
                                        value: selectedIds
                                            .contains(element.user!.id),
                                      )
                                    else if ((element.address != null &&
                                        loadingAddresses
                                            .contains(element.address)))
                                      const Padding(
                                        padding: EdgeInsets.only(right: 18.0),
                                        child: GFLoader(),
                                      )
                                    else if (element.address != null)
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
                    child: const Center(
                      child: const Text(
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
                  child: const Text('Done'),
                );
              })
            ],
          ),
        ),
      ),
    );
  }
}

class BuyableTicketTypes {
  static const onlyFriendTechTicketHolders = 'onlyFriendTechTicketHolders';
  static const onlyArenaTicketHolders = 'onlyArenaTicketHolders';
  static const onlyPodiumPassHolders = 'onlyPodiumPassHolders';
}

class FreeGroupAccessTypes {
  static const public = 'public';
  static const onlyLink = 'onlyLink';
  static const invitees = 'invitees';
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

class FreeGroupSpeakerTypes {
  static const everyone = 'everyone';
  static const invitees = 'invitees';
}

class SelectBoxOption {
  UserInfoModel? user;
  String? address;
  StarsArenaUser? arenaUser;
  SelectBoxOption({this.user, this.address, this.arenaUser});
}

const defaultSubject = "";
