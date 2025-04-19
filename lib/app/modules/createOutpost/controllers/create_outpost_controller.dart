import 'dart:io';
import 'dart:ui';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:getwidget/getwidget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/popUpsAndModals/setReminder.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/getWeb3AuthWalletAddress.dart';
import 'package:podium/app/modules/global/utils/showConfirmPopup.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/customLibs/omniDatePicker/omni_datetime_picker.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/arena/models/user.dart';
import 'package:podium/providers/api/luma/models/addGuest.dart';
import 'package:podium/providers/api/luma/models/addHost.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
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
  final UserModel user;
  final String activeAddress;
  TicketSellersListMember({required this.user, required this.activeAddress});
}

class SearchedUser {
  final UserModel? podiumUserInfo;
  final StarsArenaUser? arenaUserInfo;
  final bool? isArenaUser;
  SearchedUser({
    this.podiumUserInfo,
    this.arenaUserInfo,
    this.isArenaUser = false,
  });
}

class CreateOutpostController extends GetxController {
  final outpostsController = Get.find<OutpostsController>();
  final storage = GetStorage();
  final isCreatingNewOutpost = false.obs;
  final newOutpostHasAdultContent = false.obs;
  // luma related
  final addToLuma = false.obs;
  final lumaGuests = RxList<AddGuestModel>([]);
  final lumaHosts = RxList<AddHostModel>([]);

  // luma related end
  final newOutpostIsRecorable = false.obs;
  final outpostAccessType = FreeOutpostAccessTypes.public.obs;
  final outpostSpeakerType = FreeOutpostSpeakerTypes.everyone.obs;
  // tutorial keys
  final intro_selectImageKey = GlobalKey();
  final intro_outpostNameKey = GlobalKey();
  final intro_tagsKey = GlobalKey();
  final intro_outpostSubjectKey = GlobalKey();
  final intro_outpostAccessTypeKey = GlobalKey();
  final intro_outpostSpeakerTypeKey = GlobalKey();
  // end tutorial keys
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
  final outpostSubject = defaultSubject.obs;
  final outpostName = "".obs;

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
  void onReady() async {
    super.onReady();
    final alreadyViewed = storage.read(IntroStorageKeys.viewedCreateOutpost);
    if (alreadyViewed == null) {
      // wait for the context to be ready
      await Future.delayed(const Duration(seconds: 0));
      tutorialCoachMark = TutorialCoachMark(
        targets: _createTargets(),
        paddingFocus: 5,
        opacityShadow: 0.5,
        skipWidget: Button(
          size: ButtonSize.SMALL,
          type: ButtonType.outline,
          color: Colors.red,
          onPressed: () {
            introFinished(true);
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
        await Future.delayed(const Duration(seconds: 1));
        tutorialCoachMark.show(context: contextForIntro!);
      } catch (e) {
        l.e(e);
      }
    }
  }

  addHost(String email, String name) {
    // add if not already in the list
    if (!lumaHosts.any((e) => e.email == email)) {
      lumaHosts.add(AddHostModel(
        email: email,
        name: name,
      ));
    }
    // update if it exists
    else {
      lumaHosts.firstWhere((e) => e.email == email).name = name;
    }
  }

  addGuest(String email, String name) {
    // add if not already in the list
    if (!lumaGuests.any((e) => e.email == email)) {
      lumaGuests.add(AddGuestModel(
        email: email,
        name: name,
      ));
    }
  }

  removeGuest(String email) {
    // remove the guest from the list if it exists
    if (lumaGuests.any((e) => e.email == email)) {
      lumaGuests.removeWhere((e) => e.email == email);
    }
  }

  removeHost(String email) {
    // remove the host from the list if it exists
    if (lumaHosts.any((e) => e.email == email)) {
      lumaHosts.removeWhere((e) => e.email == email);
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
        targetId: intro_outpostSubjectKey,
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
        targetId: intro_outpostAccessTypeKey,
        text: "you can select the access type of your outpost",
      ),
    );

    targets.add(
      _createStep(
        targetId: intro_outpostSpeakerTypeKey,
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
      storage.write(IntroStorageKeys.viewedCreateOutpost, true);
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
      final f = File(pickedFile
          .path); // Use this to store the image in the database or cloud storage

      // check if file is less than 2mb
      final fileSize = f.lengthSync();
      if (fileSize > 2 * 1024 * 1024) {
        Toast.error(message: 'Image size must be less than 2MB');
        selectedFile = null;
        return;
      }
      selectedFile = f;
      fileLocalAddress.value = pickedFile.path;
    } else {
      l.e('No image selected.');
    }
  }

  Future<String?> uploadFile({required outpostId}) async {
    final storageRef =
        FirebaseStorage.instance.ref().child('outposts/$outpostId');

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
    outpostAccessType.value = value;
  }

  setRoomSpeakingType(String value) {
    outpostSpeakerType.value = value;
  }

  setRoomSubject(String value) {
    outpostSubject.value = value;
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
    return (outpostSpeakerType.value ==
                BuyableTicketTypes.onlyFriendTechTicketHolders ||
            outpostSpeakerType.value ==
                BuyableTicketTypes.onlyArenaTicketHolders ||
            outpostSpeakerType.value ==
                BuyableTicketTypes.onlyPodiumPassHolders) &&
        selectedUsersToBuyticketFrom_ToSpeak.isEmpty &&
        addressesToAddForSpeaking.isEmpty;
  }

  get shouldSelectTicketHolersForAccess {
    return ((outpostAccessType.value ==
                BuyableTicketTypes.onlyFriendTechTicketHolders) ||
            outpostAccessType.value ==
                BuyableTicketTypes.onlyArenaTicketHolders ||
            outpostAccessType.value ==
                BuyableTicketTypes.onlyPodiumPassHolders) &&
        selectedUsersToBuyTicketFrom_ToAccessRoom.isEmpty &&
        addressesToAddForEntering.isEmpty;
  }

  get shouldBuyTicketToSpeak {
    return outpostSpeakerType.value ==
            BuyableTicketTypes.onlyFriendTechTicketHolders ||
        outpostSpeakerType.value == BuyableTicketTypes.onlyArenaTicketHolders ||
        outpostSpeakerType.value == BuyableTicketTypes.onlyPodiumPassHolders;
  }

  get shouldBuyTicketToAccess {
    return outpostAccessType.value ==
            BuyableTicketTypes.onlyFriendTechTicketHolders ||
        outpostAccessType.value == BuyableTicketTypes.onlyArenaTicketHolders ||
        outpostAccessType.value == BuyableTicketTypes.onlyPodiumPassHolders;
  }

  toggleAddressForSelectedList({
    required String address,
    required String ticketPermissionType,
  }) async {
    final list = ticketPermissionType == TicketPermissionType.speak
        ? addressesToAddForSpeaking
        : addressesToAddForEntering;
    final ticketType = ticketPermissionType == TicketPermissionType.speak
        ? outpostSpeakerType.value
        : outpostAccessType.value;
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
    final usersMap = list.map((e) => e.user.uuid).toList();
    if (usersMap.contains(arenaUserIdPrefix + user.id)) {
      list.removeWhere((e) => e.user.uuid == arenaUserIdPrefix + user.id);
    } else {
      list.add(TicketSellersListMember(
        user: UserModel(
          uuid: arenaUserIdPrefix + user.id,
          name: user.twitterName,
          email: '',
          image: user.twitterPicture,
          address: user.mainAddress,
        ),
        activeAddress: user.mainAddress,
      ));
    }
  }

  toggleUserToSelectedList({
    required UserModel user,
    required String ticketPermissiontype,
  }) async {
    final list = ticketPermissiontype == TicketPermissionType.speak
        ? selectedUsersToBuyticketFrom_ToSpeak
        : selectedUsersToBuyTicketFrom_ToAccessRoom;
    final ticketType = ticketPermissiontype == TicketPermissionType.speak
        ? outpostSpeakerType.value
        : outpostAccessType.value;
    if (user.defaultWalletAddress.isEmpty) {
      Toast.error(message: 'User has no wallet address');
      return;
    }

    final usersMap = list.map((e) => e.user.uuid).toList();
    if (usersMap.contains(user.uuid)) {
      list.removeWhere((e) => e.user.uuid == user.uuid);
    } else {
      String? activeAddress =
          ticketType != BuyableTicketTypes.onlyFriendTechTicketHolders
              ? user.defaultWalletAddress
              : await checkIfUserCanBeAddedToList(
                  user: user,
                  ticketPermissionType: ticketPermissiontype,
                );
      if (ticketType == BuyableTicketTypes.onlyPodiumPassHolders) {
        activeAddress = user.address;
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
        outpostAccessType.value ==
            BuyableTicketTypes.onlyFriendTechTicketHolders) {
      return true;
    }
    if (ticketPermissionType == TicketPermissionType.speak &&
        outpostSpeakerType.value ==
            BuyableTicketTypes.onlyFriendTechTicketHolders) {
      return true;
    }
    return false;
  }

  Future<String?> checkIfUserCanBeAddedToList({
    required UserModel user,
    required String ticketPermissionType,
  }) async {
    if (!_shouldCheckIfUserIsActive(ticketPermissionType)) {
      return user.defaultWalletAddress;
    }
    loadingUserIds.add(user.uuid);
    try {
      final activeWallets = await internal_friendTech_getActiveUserWallets(
        internalWalletAddress: user.address,
        externalWalletAddress: user.defaultWalletAddress,
        chainId: baseChainId,
      );
      final isActive = activeWallets.hasActiveWallet;
      final preferedWalletAddress = activeWallets.preferedWalletAddress;
      if (isActive) {
        return preferedWalletAddress;
      } else {
        if (user.uuid != myId) {
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
      loadingUserIds.remove(user.uuid);
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
          HttpApis.podium.searchUserByName(name: value),
          ticketType == BuyableTicketTypes.onlyArenaTicketHolders
              ? HttpApis.arenaApi.getUserFromStarsArenaByHandle(value)
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

  get _shouldCreateLumaEvent =>
      addToLuma.value &&
      isScheduled.value &&
      scheduledFor != 0 &&
      lumaHosts.value.isNotEmpty &&
      lumaGuests.value.isNotEmpty;

  create() async {
    if (outpostName.value.isEmpty) {
      Toast.error(message: 'room name cannot be empty');
      return;
    } else if (outpostName.value.length < 5) {
      Toast.error(message: 'room name must be at least 5 characters');
      return;
    }

    String subject = outpostSubject.value;
    if (subject.isEmpty) {
      subject = defaultSubject;
    }
    isCreatingNewOutpost.value = true;
    final accessType = outpostAccessType.value;
    final speakerType = outpostSpeakerType.value;
    final id = const Uuid().v4();
    String imageUrl = "";
    if (selectedFile != null) {
      final res = await uploadFile(outpostId: id);
      if (res == null) {
        final result = await showConfirmPopup(
          title: 'Image Upload Failed',
          message: 'you can set it later in the outpost detail page',
          cancelText: 'Cancel Outpost Creation',
          confirmText: 'Continue',
          isDangerous: true,
          cancelColor: Colors.red,
          confirmColor: Colors.green,
          titleColor: Colors.orange,
        );
        if (result == false) {
          isCreatingNewOutpost.value = false;
          return;
        }
      }
      if (res != null) {
        imageUrl = res;
      }
    }

    try {
      final response = await outpostsController.createOutpost(
          imageUrl: imageUrl,
          name: outpostName.value,
          accessType: accessType,
          speakerType: speakerType,
          subject: subject,
          tags: tags.value,
          adultContent: newOutpostHasAdultContent.value,
          recordable: newOutpostIsRecorable.value,
          requiredTicketsToAccess:
              selectedUsersToBuyTicketFrom_ToAccessRoom.value,
          requiredTicketsToSpeak: selectedUsersToBuyticketFrom_ToSpeak.value,
          requiredAddressesToEnter: addressesToAddForEntering.value,
          requiredAddressesToSpeak: addressesToAddForSpeaking.value,
          scheduledFor: scheduledFor.value,
          shouldCreateLumaEvent: _shouldCreateLumaEvent);
      if (response == null) {
        Toast.error(message: 'Failed to create outpost');
        return;
      }
      outpostName.value = "";
      final scheduleTime = scheduledFor.value;
      if (scheduledFor.value != 0) {
        final setFor = await setReminder(
          uuid: response.uuid,
          scheduledFor: scheduledFor.value,
        );
        if (setFor == -1) {
          // means use calendar
        }
        if (setFor == -2) {
          // means no reminder
        } else if (setFor == null) {
          // means tap on back or outside
          // return;
        }
      }

      // preventing from creating the same name if controller is not deleted
      _resetAllFields();
      outpostsController.joinOutpostAndOpenOutpostDetailPage(
        outpostId: response.uuid,
        openTheRoomAfterJoining: scheduleTime == 0 ||
            scheduleTime < DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      l.e(e);
    } finally {
      isCreatingNewOutpost.value = false;
    }
  }

  _resetAllFields() {
    outpostName.value = "";
    selectedFile = null;
    tags.value = [];
    newOutpostHasAdultContent.value = false;
    newOutpostIsRecorable.value = false;
    selectedUsersToBuyTicketFrom_ToAccessRoom.value = [];
    selectedUsersToBuyticketFrom_ToSpeak.value = [];
    addressesToAddForEntering.value = [];
    addressesToAddForSpeaking.value = [];
    lumaHosts.value = [];
    lumaGuests.value = [];
    scheduledFor.value = 0;
    searchValueForSeletTickets.value = "";
    showLoadingOnSearchInput.value = false;
    loadingUserIds.value = [];
    loadingAddresses.value = [];
    listOfSearchedUsersToBuyTicketFrom.value = [];
    isCreatingNewOutpost.value = false;
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

class ScheduledGroupDateSelector extends GetView<CreateOutpostController> {
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
    extends GetView<CreateOutpostController> {
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
                        ? controller.outpostSpeakerType.value
                        : controller.outpostAccessType.value;
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
                              element.podiumUserInfo!.uuid != myId;
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
                      List<UserModel> selectedUsers;
                      if (buyTicketToGetPermisionFor ==
                          TicketPermissionType.speak) {
                        selectedUsers =
                            selsectedListOfUsersToBuyTicketFromInOrderToSpeak
                                .map((e) => e.user)
                                .toList();
                        selectedIds = selectedUsers.map((e) => e.uuid).toList();
                      } else if (buyTicketToGetPermisionFor ==
                          TicketPermissionType.access) {
                        selectedUsers =
                            selsectedListOfUsersToBuyTicketFromInOrderToAccessRoom
                                .map((e) => e.user)
                                .toList();
                        selectedIds = selectedUsers.map((e) => e.uuid).toList();
                      } else {
                        return Container(
                          child: const Center(
                            child: const Text('Error, type is not valid'),
                          ),
                        );
                      }
                      // move selectedIds to the top of the list then my id to the top of them
                      List<UserModel> listOfUsers = [];

                      final starsArenaUsers = controller
                          .listOfSearchedUsersToBuyTicketFrom.value
                          .where(
                        (element) {
                          return element.isArenaUser == true &&
                              !selectedIds.contains(arenaUserIdPrefix +
                                  element.arenaUserInfo!.id);
                        },
                      ).toList();

                      // listOfUsers.add(myUser);
                      final SelectedUsersExceptMe = selectedUsers
                          .where((element) => element.uuid != myId);
                      listOfUsers.addAll([myUser, ...SelectedUsersExceptMe]);
                      final notSelectedPodiumUsers = podiumUsers.where(
                          (element) => !selectedIds
                              .contains(element.podiumUserInfo!.uuid));
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
                                                src: element.user?.image ==
                                                        defaultAvatar
                                                    ? ''
                                                    : element.user!.image ?? '',
                                                alt: element.user!.name,
                                                size: 20,
                                              ),
                                              space5
                                            ],
                                          ),
                                        if (element.user != null)
                                          Text(
                                            element.user!.uuid == myId
                                                ? "You"
                                                : element.user!.name ?? '',
                                            textAlign: TextAlign.start,
                                            style: TextStyle(
                                              color: element.user!.uuid == myId
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
                                                truncate(element.user!.uuid,
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
                                        loadingIds.contains(element.user!.uuid))
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
                                            .contains(element.user!.uuid),
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
  static const onlyFriendTechTicketHolders = 'friend_tech_key_holders';
  static const onlyArenaTicketHolders = 'arena_ticket_holders';
  static const onlyPodiumPassHolders = 'podium_pass_holders';
}

class FreeOutpostAccessTypes {
  static const public = 'everyone';
  static const onlyLink = 'having_link';
  static const invitees = 'invited_users';
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

class FreeOutpostSpeakerTypes {
  static const everyone = 'everyone';
  static const invitees = 'invitees';
}

class SelectBoxOption {
  UserModel? user;
  String? address;
  StarsArenaUser? arenaUser;
  SelectBoxOption({this.user, this.address, this.arenaUser});
}

const defaultSubject = "";
