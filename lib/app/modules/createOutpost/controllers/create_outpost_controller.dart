import 'dart:io';
import 'dart:ui';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:podium/app/modules/createOutpost/widgets/activate_wallet_dialog.dart';
import 'package:podium/app/modules/createOutpost/widgets/ticket_sellers_dialog.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/popUpsAndModals/setReminder.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/getWeb3AuthWalletAddress.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/customLibs/omniDatePicker/omni_datetime_picker.dart';
import 'package:podium/data/repositories/repositories.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/arena/models/user.dart';
import 'package:podium/providers/api/luma/models/addGuest.dart';
import 'package:podium/providers/api/luma/models/addHost.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/utils/storage.dart';
import 'package:podium/utils/throttleAndDebounce/debounce.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:podium/widgets/ui/app_ui.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:uuid/uuid.dart';

import 'package:podium/app/modules/createOutpost/outpost_types.dart';

export 'package:podium/app/modules/createOutpost/outpost_types.dart';

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
  final _userRepository = Get.find<UserRepository>();
  final outpostsController = Get.find<OutpostsController>();
  final storage = GetStorage();
  final isCreatingNewOutpost = false.obs;
  final newOutpostHasAdultContent = false.obs;
  // luma related
  final addToLuma = false.obs;
  final lumaGuests = RxList<AddGuestModel>([]);
  final lumaHosts = RxList<AddHostModel>([]);
  final cohosts = RxList<UserModel>([]);

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
          color: ColorName.danger,
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
          l.d('onClickTarget: $target');
        },
        onClickTargetWithTapPosition: (target, tapDetails) {
          l.d("target: $target");
          l.d("clicked at position local: ${tapDetails.localPosition} - global: ${tapDetails.globalPosition}");
        },
        onClickOverlay: (target) {
          l.d('onClickOverlay: $target');
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

  void addHost(String email, String name) {
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

  void addGuest(String email, String name) {
    // add if not already in the list
    if (!lumaGuests.any((e) => e.email == email)) {
      lumaGuests.add(AddGuestModel(
        email: email,
        name: name,
      ));
    }
  }

  void removeGuest(String email) {
    // remove the guest from the list if it exists
    if (lumaGuests.any((e) => e.email == email)) {
      lumaGuests.removeWhere((e) => e.email == email);
    }
  }

  void removeHost(String email) {
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

  TargetFocus _createStep({
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
                  style: TextStyle(
                    color: ColorName.white,
                  ),
                ),
                if (hasNext)
                  Button(
                    size: ButtonSize.SMALL,
                    type: ButtonType.outline,
                    color: ColorName.white,
                    onPressed: () {
                      tutorialCoachMark.next();
                    },
                    child: Text(
                      "Next",
                      style: TextStyle(color: ColorName.white),
                    ),
                  )
                else
                  Button(
                    size: ButtonSize.SMALL,
                    type: ButtonType.outline,
                    color: ColorName.white,
                    onPressed: () {
                      introFinished(true);
                    },
                    child: Text(
                      "Finish",
                      style: TextStyle(color: ColorName.white),
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
    } catch (e) {
      // The tutorial was never shown.
    }
  }

  Future<void> pickImage() async {
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

  Future<String?> uploadFile({required String outpostId}) async {
    try {
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
    } catch (e) {
      l.e(e);
      return null;
    }
  }

  void toggleScheduled() {
    isScheduled.value = !isScheduled.value;
  }

  void setTags(List<String> values) {
    tags.value = values;
  }

  void setRoomPrivacyType(String value) {
    outpostAccessType.value = value;
  }

  void setRoomSpeakingType(String value) {
    outpostSpeakerType.value = value;
  }

  void setRoomSubject(String value) {
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

  bool get shouldBuyTicketToSpeak =>
      BuyableTicketTypes.all.contains(outpostSpeakerType.value);

  bool get shouldBuyTicketToAccess =>
      BuyableTicketTypes.all.contains(outpostAccessType.value);

  /// A ticket-gated permission with no ticket holders picked yet.
  bool get shouldSelectTicketHolersForSpeaking =>
      shouldBuyTicketToSpeak &&
      selectedUsersToBuyticketFrom_ToSpeak.isEmpty &&
      addressesToAddForSpeaking.isEmpty;

  bool get shouldSelectTicketHolersForAccess =>
      shouldBuyTicketToAccess &&
      selectedUsersToBuyTicketFrom_ToAccessRoom.isEmpty &&
      addressesToAddForEntering.isEmpty;

  Future<void> toggleAddressForSelectedList({
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

  void toggleArenaUser({
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

  Future<void> toggleUserToSelectedList({
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

  void removeAddressForEntering(String address) {
    addressesToAddForEntering.remove(address);
  }

  void removeAddressForSpeaking(String address) {
    addressesToAddForSpeaking.remove(address);
  }

  Future<void> searchUsers(String value, {String? ticketType}) async {
    searchValueForSeletTickets.value = value;
    if (value.isEmpty) {
      listOfSearchedUsersToBuyTicketFrom.value = [];
      return;
    }
    showLoadingOnSearchInput.value = true;
    _deb.debounce(() async {
      try {
        checkIfValueIsDirectAddress(value);
        final (users, arenaUser) = await (
          _userRepository.searchUserByName(name: value),
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

  bool get _shouldCreateLumaEvent =>
      addToLuma.value &&
      isScheduled.value &&
      scheduledFor.value != 0 &&
      lumaHosts.value.isNotEmpty &&
      lumaGuests.value.isNotEmpty;

  Future<void> create() async {
    if (outpostName.value.isEmpty) {
      Toast.error(message: 'Outpost name cannot be empty');
      return;
    } else if (outpostName.value.length < 5) {
      Toast.error(message: 'Outpost name must be at least 5 characters');
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
        final result = await showAppConfirm(
          title: 'Image Upload Failed',
          message: 'You can set it later on the outpost detail page.',
          cancelLabel: 'Cancel Outpost Creation',
          confirmLabel: 'Continue',
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
          shouldCreateLumaEvent: _shouldCreateLumaEvent,
          lumaHosts: lumaHosts.toList(),
          lumaGuests: lumaGuests.toList(),
          cohosts: cohosts.value
              .map((e) => e.uuid)
              .where((e) => e != myId)
              .toList());

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

  void _resetAllFields() {
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
    cohosts.value = [];
  }

  void openSelectTicketBottomSheet({
    required String buyTicketToGetPermisionFor,
  }) {
    searchValueForSeletTickets.value = "";
    Get.dialog(
      AppDialogMotion(
        child: SelectUsersToBuyTicketFromBottomSheetContent(
          buyTicketToGetPermisionFor: buyTicketToGetPermisionFor,
        ),
      ),
    );
  }
}

const defaultSubject = "";
