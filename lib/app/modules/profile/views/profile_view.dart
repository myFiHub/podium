import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/getContract.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/modules/outpostDetail/widgets/usersList.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/root.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';

import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const UserInfo(),
                Obx(() {
                  final followedByMe =
                      controller.userInfo.value!.followed_by_me ?? false;
                  return FollowButton(
                    fullWidth: true,
                    uuid: controller.userInfo.value!.uuid,
                    followed_by_me: followedByMe,
                    onFollowStatusChanged: () {
                      controller.getUserInfo();
                    },
                  );
                }),
                space10,
                const _BuyOrSellPodiumPass(),
                // space10,
                // const _BuyArenaTicketButton(),
                // space10,
                // const _BuyFriendTechTicket(),
                space10,
                const _Statistics(),
                space10,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BuyOrSellPodiumPass extends GetWidget<ProfileController> {
  const _BuyOrSellPodiumPass();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final user = controller.userInfo.value;
        final isGettingPrice = controller.isGettingTicketPrice.value;
        final isBuyingPodiumPass = controller.isBuyingPodiumPass.value;
        final podiumPassPrice = controller.podiumPassPrice.value;
        final isGettingPodiumPassPrice =
            controller.loadingPodiumPassPrice.value;
        final numberOfBoughtTicketsByMe =
            controller.mySharesOfPodiumPassFromThisUser.value;
        if (user == null) {
          return Container();
        }
        return Button(
          loading: isGettingPrice || isBuyingPodiumPass,
          onPressed: (isGettingPrice || isBuyingPodiumPass)
              ? null
              : () {
                  controller.buyOrSellPodiumPass();
                },
          type: ButtonType.gradient,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text(
                    'Buy Podium Pass ${podiumPassPrice.toString()} ${chainInfoByChainId(movementAptosNetwork.chainId).currency}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (isGettingPodiumPassPrice)
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
                    text: 'You own ',
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
                        text: ' Podium Pass',
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
              src: chainInfoByChainId(movementAptosNetwork.chainId).chainIcon ??
                  Assets.images.movementLogo.path,
              size: 20),
        );
      },
    );
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

class UserInfo extends GetWidget<ProfileController> {
  const UserInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.userInfo.value;
      if (user == null) {
        return Container();
      }
      String avatar = user.image ?? '';
      if (avatar == defaultAvatar) {
        avatar = avatarPlaceHolder(user.name ?? '');
      }
      return Container(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          children: [
            Img(
              src: avatar,
              alt: user.name ?? '',
              size: 100,
            ),
            space10,
            Text(
              user.name ?? '',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            // space10,
            // FollowerBadge(
            //   followerCount: user.followers_count ?? 0,
            // ),
            space10,
          ],
        ),
      );
    });
  }
}
