import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/getContract.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/modules/outpostDetail/widgets/usersList.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/root.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/utils/truncate.dart';
import 'package:podium/widgets/button/button.dart';

import '../controllers/profile_controller.dart';

/// Shows a dialog with options for managing podium passes
void showPodiumPassOptionsDialog(
  int numberOfPasses,
  ProfileController controller,
) {
  Get.dialog(
    AlertDialog(
      backgroundColor: ColorName.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        'Podium Pass Options',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You already have $numberOfPasses podium pass${numberOfPasses > 1 ? 'es' : ''}.',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          const Text(
            'What would you like to do?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Button(
            onPressed: () {
              Get.close();
              controller.buyPodiumPass();
            },
            type: ButtonType.gradient,
            child: const Text(
              'Buy Another Pass',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            blockButton: true,
          ),
        ),
        const SizedBox(height: 12), // Add spacing between buttons
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Button(
            onPressed: () {
              Get.close();
              controller.sellPodiumPass();
            },
            type: ButtonType.outline,
            borderSide: const BorderSide(color: Colors.red),
            textColor: Colors.red,
            child: const Text(
              'Sell 1 Pass',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            blockButton: true,
          ),
        ),
        const SizedBox(height: 12), // Add spacing between buttons
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Button(
            onPressed: () => Get.close(),
            type: ButtonType.transparent,
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 16),
            ),
            blockButton: true,
          ),
        ),
        const SizedBox(height: 8),
      ],
    ),
  );
}

class ProfileView extends GetView<ProfileController> {
  const ProfileView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
            width: double.infinity,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _ProfileHeader(),
                space10,
                _Statistics(),
                space10,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends GetWidget<ProfileController> {
  const _ProfileHeader();

  static const _profileHeroTagPrefix = 'profile_avatar_';

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.userInfo.value;
      if (user == null) {
        return const SizedBox(
          height: 150,
          width: double.infinity,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      String avatar = user.image ?? '';
      if (avatar == defaultAvatar) {
        avatar = avatarPlaceHolder(user.name ?? '');
      }

      // Get wallet address from user object
      final walletAddress = user.aptos_address!;
      final shortWalletAddress = truncate(walletAddress, length: 18);

      final followedByMe = user.followed_by_me ?? false;

      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Image
                Hero(
                  tag: '${_profileHeroTagPrefix}${user.uuid}',
                  child: Img(
                    src: avatar,
                    alt: user.name ?? '',
                    size: 60,
                  ),
                ),
                const SizedBox(width: 16),
                // Profile info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        user.name ?? '',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Wallet address with copy button
                      Row(
                        children: [
                          Text(
                            shortWalletAddress,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.copy,
                                size: 16, color: Colors.grey),
                            onPressed: () {
                              // Copy wallet address
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                // Buy Ticket Button
                Expanded(
                  flex: 2,
                  child: _TicketButton(),
                ),
                const SizedBox(width: 8),
                // Follow Button
                Expanded(
                  flex: 1,
                  child: FollowButton(
                    uuid: user.uuid,
                    followed_by_me: followedByMe,
                    fullWidth: true,
                    onFollowStatusChanged: () {
                      controller.getUserInfo();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _TicketButton extends GetWidget<ProfileController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isGettingPrice = controller.isGettingTicketPrice.value;
      final isBuyingPodiumPass = controller.isBuyingPodiumPass.value;
      final isSellingPodiumPass = controller.isSellingPodiumPass.value;
      final podiumPassPrice = controller.podiumPassPrice.value;
      final isGettingPodiumPassPrice = controller.loadingPodiumPassPrice.value;
      final numberOfBoughtTicketsByMe =
          controller.mySharesOfPodiumPassFromThisUser.value;

      return Button(
        loading: isGettingPrice || isBuyingPodiumPass || isSellingPodiumPass,
        onPressed: (isGettingPrice || isBuyingPodiumPass || isSellingPodiumPass)
            ? null
            : () {
                if (numberOfBoughtTicketsByMe > 0) {
                  // Show confirmation dialog when user already has a pass
                  showPodiumPassOptionsDialog(
                      numberOfBoughtTicketsByMe, controller);
                } else {
                  // Original functionality for users without a pass
                  controller.buyPodiumPass();
                }
              },
        type: ButtonType.gradient,
        blockButton: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Img(
                src: chainInfoByChainId(movementAptosNetwork.chainId)
                        .chainIcon ??
                    Assets.images.movementLogo.path,
                size: 20),
            const SizedBox(width: 8),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                children: [
                  TextSpan(
                    text: numberOfBoughtTicketsByMe > 0
                        ? "Manage Podium Pass"
                        : "Buy Ticket",
                  ),
                  if (numberOfBoughtTicketsByMe == 0)
                    TextSpan(
                      text: " ${podiumPassPrice.toString()} MOV",
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            if (isGettingPodiumPassPrice)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _Statistics extends GetWidget<ProfileController> {
  const _Statistics();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final payments = controller.payments.value;
      final loading = controller.isGettingPayments.value;
      if (loading) {
        return const SizedBox();
      }
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'Cheers received',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      payments.numberOfCheersReceived.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      'Boos received',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      payments.numberOfBoosReceived.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            space10,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'Cheers sent',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      payments.numberOfCheersSent.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      'Boos sent',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      payments.numberOfBoosSent.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _BuyArenaTicketButton extends GetWidget<ProfileController> {
  const _BuyArenaTicketButton();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.userInfo.value;
      final isGettingPrice = controller.isGettingTicketPrice.value;
      final isBuyingArenaTicket = controller.isBuyingArenaTicket.value;
      final arenaTicketPrice = controller.arenaTicketPrice.value;
      final isGettingArenaPrice = controller.loadingArenaPrice.value;
      final numberOfBoughtTicketsByMe =
          controller.mySharesOfArenaFromThisUser.value;
      if (user == null) {
        return Container();
      }
      return Button(
        loading: isGettingPrice || isBuyingArenaTicket,
        onPressed: (isGettingPrice || isBuyingArenaTicket)
            ? null
            : () {
                controller.buyArenaTicket();
              },
        type: ButtonType.gradient,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Text(
                  'Buy Arena ticket ${arenaTicketPrice.toString()} ${chainInfoByChainId(avalancheChainId).currency}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isGettingArenaPrice)
                  const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                else
                  const SizedBox(width: 10, height: 10),
              ],
            ),
            if (numberOfBoughtTicketsByMe > 0)
              RichText(
                text: TextSpan(
                  text: 'owned ',
                  style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(
                      text: '$numberOfBoughtTicketsByMe',
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    const TextSpan(
                      text: ' Arena tickets',
                      style: TextStyle(
                        color: Colors.yellow,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        blockButton: true,
        icon: Img(
            src: chainInfoByChainId(avalancheChainId).chainIcon ??
                Assets.images.movementLogo.path,
            size: 20),
      );
    });
  }
}

class _BuyFriendTechTicket extends GetWidget<ProfileController> {
  const _BuyFriendTechTicket({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.userInfo.value;
      final isFriendTechActive = controller.isFriendTechActive.value;
      final isGettingPrice = controller.isGettingTicketPrice.value;
      final friendTechPrice = controller.friendTechPrice.value;
      final isGettingFriendTechPrice = controller.loadingFriendTechPrice.value;
      final isBuyingFriendTechTicket =
          controller.isBuyingFriendTechTicket.value;
      final numberOfBoughtTicketsByMe =
          controller.mySharesOfFriendTechFromThisUser.value;
      if (user == null) {
        return Container();
      }
      return Button(
        loading: isGettingPrice || isBuyingFriendTechTicket,
        onPressed:
            (!isFriendTechActive || isGettingPrice || isBuyingFriendTechTicket)
                ? null
                : () {
                    controller.buyFriendTechTicket();
                  },
        type: ButtonType.gradient,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            !isFriendTechActive
                ? const Text(
                    'Friendtech address is not active',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.red,
                    ),
                  )
                : Row(
                    children: [
                      Text(
                        'Buy Friendtech share ${friendTechPrice.toString()} ${chainInfoByChainId(baseChainId).currency}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (isGettingFriendTechPrice)
                        const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      else
                        const SizedBox(width: 10, height: 10),
                    ],
                  ),
            if (numberOfBoughtTicketsByMe > 0)
              RichText(
                text: TextSpan(
                  text: 'owned ',
                  style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(
                      text: '$numberOfBoughtTicketsByMe',
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    const TextSpan(
                      text: ' Friendtech share',
                      style: TextStyle(
                        color: Colors.yellow,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        blockButton: true,
        icon: Img(
          src: chainInfoByChainId(baseChainId).chainIcon ??
              Assets.images.movementLogo.path,
          size: 20,
        ),
      );
    });
  }
}
