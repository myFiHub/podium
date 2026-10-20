import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/providers/api/arena/models/user.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/utils/truncate.dart';
import 'package:podium/widgets/textField/textFieldRounded.dart';
import 'package:podium/widgets/ui/app_ui.dart';
import 'package:podium/app/modules/createOutpost/controllers/create_outpost_controller.dart';

class SelectUsersToBuyTicketFromBottomSheetContent extends StatefulWidget {
  final String buyTicketToGetPermisionFor;
  const SelectUsersToBuyTicketFromBottomSheetContent({
    super.key,
    required this.buyTicketToGetPermisionFor,
  });

  @override
  State<SelectUsersToBuyTicketFromBottomSheetContent> createState() =>
      _SelectUsersToBuyTicketFromBottomSheetContentState();
}

class _SelectUsersToBuyTicketFromBottomSheetContentState
    extends State<SelectUsersToBuyTicketFromBottomSheetContent> {
  final controller = Get.find<CreateOutpostController>();
  final inputController = TextEditingController();

  String get buyTicketToGetPermisionFor => widget.buyTicketToGetPermisionFor;

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: Get.height * 0.5,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text('Search user', style: AppText.title),
                    ),
                  ),
                  AppIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Close',
                    size: 36,
                    onTap: () {
                      controller.listOfSearchedUsersToBuyTicketFrom.value = [];
                      Get.close();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                return SizedBox(
                  height: 70,
                  child: Input(
                    controller: inputController,
                    suffixIcon: hasLoadingAddress || isInputBusy
                        ? const SizedBox(
                            width: 50,
                            child: GFLoader(),
                          )
                        : searchValue.isEmpty
                            ? IconButton(
                                tooltip: 'Paste address',
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
                                icon: Icon(
                                  Icons.paste,
                                  color: ColorName.secondaryText,
                                ),
                              )
                            : isAddress
                                ? IconButton(
                                    tooltip: 'Add address',
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
                                    icon: Icon(Icons.check,
                                        color: ColorName.success),
                                  )
                                : IconButton(
                                    tooltip: 'Clear search',
                                    onPressed: () {
                                      controller.searchUsers('');
                                      inputController.clear();
                                    },
                                    icon: Icon(Icons.close,
                                        color: ColorName.danger),
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
                    final loadingAddresses = controller.loadingAddresses.value;
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
                      return const Center(
                        child: Text('Error, type is not valid'),
                      );
                    }
                    // move selectedIds to the top of the list then my id to the top of them
                    List<UserModel> listOfUsers = [];

                    final starsArenaUsers = controller
                        .listOfSearchedUsersToBuyTicketFrom.value
                        .where(
                      (element) {
                        return element.isArenaUser == true &&
                            !selectedIds.contains(
                                arenaUserIdPrefix + element.arenaUserInfo!.id);
                      },
                    ).toList();

                    final SelectedUsersExceptMe =
                        selectedUsers.where((element) => element.uuid != myId);
                    listOfUsers.addAll([myUser, ...SelectedUsersExceptMe]);
                    final notSelectedPodiumUsers = podiumUsers.where(
                        (element) => !selectedIds
                            .contains(element.podiumUserInfo!.uuid));
                    listOfUsers.addAll(notSelectedPodiumUsers.map(
                      (e) => e.podiumUserInfo!,
                    ));
                    final listOfAddresses =
                        buyTicketToGetPermisionFor == TicketPermissionType.speak
                            ? controller.addressesToAddForSpeaking
                            : controller.addressesToAddForEntering;
                    List<SelectBoxOption> options = [];
                    for (var user in starsArenaUsers) {
                      options
                          .add(SelectBoxOption(arenaUser: user.arenaUserInfo));
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
                                          "Followers: $numberOfFollowers",
                                          style: const TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (verifiedOnTwitter)
                                          Text(
                                            "verified on twitter",
                                            style: TextStyle(
                                                color: ColorName.primaryBlue,
                                                fontSize: 12),
                                          ),
                                        if (verifiedOnTwitter &&
                                            verifiedOnArena)
                                          space5,
                                        if (verifiedOnArena)
                                          Text(
                                            "verified on Stars Arena",
                                            style: TextStyle(
                                                color: ColorName.danger,
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
                              Divider(color: AppColors.border),
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
                                                ? ColorName.success
                                                : ColorName.white,
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
                                            color: ColorName.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (element.user != null)
                                    Row(
                                      children: [
                                        Text(
                                          "user ID: ${truncate(element.user!.uuid, length: 12)}",
                                          style: TextStyle(
                                            color: ColorName.secondaryText,
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
                                          ? controller.addressesToAddForSpeaking
                                              .contains(element.address)
                                          : controller.addressesToAddForEntering
                                              .contains(element.address),
                                    ),
                                ],
                              ),
                            ),
                            Divider(
                              color: AppColors.border,
                            ),
                          ],
                        );
                      },
                    );
                  },
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
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Center(
                      child: Text(
                        'Select Users, or Enter Address',
                        textAlign: TextAlign.center,
                        style: AppText.muted,
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: AppPrimaryButton(
                    label: 'Done',
                    onPressed: () {
                      Get.close();
                    },
                  ),
                );
              })
            ],
          ),
        ),
      ),
    );
  }
}

class SelectBoxOption {
  UserModel? user;
  String? address;
  StarsArenaUser? arenaUser;
  SelectBoxOption({this.user, this.address, this.arenaUser});
}
