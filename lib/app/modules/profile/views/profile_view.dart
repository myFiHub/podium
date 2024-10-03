import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/utils/getContract.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/modules/groupDetail/widgets/usersList.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              UserInfo(),
              FollowButton(
                userId: controller.userInfo.value!.id,
              ),
              space10,
              _BuyArenaTicketButton(),
              space10,
              _BuyFriendTechTicket(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuyArenaTicketButton extends GetWidget<ProfileController> {
  const _BuyArenaTicketButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.userInfo.value;
      final isGettingPrice = controller.isGettingTicketPrice.value;
      final isBuyingArenaTicket = controller.isBuyingArenaTicket.value;
      final arenaTicketPrice = controller.arenaTicketPrice.value;
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
            Text(
              'Buy Arena ticket ${arenaTicketPrice.toString()} ${particleChainInfoByChainId(avalancheChainId)!.nativeCurrency.symbol}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (numberOfBoughtTicketsByMe > 0)
              RichText(
                text: TextSpan(
                  text: 'owned ',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(
                      text: '$numberOfBoughtTicketsByMe',
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    TextSpan(
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
            src: particleChainInfoByChainId(avalancheChainId)!.icon, size: 20),
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
                : Text(
                    'Buy Friendtech share ${friendTechPrice.toString()} ${particleChainInfoByChainId(baseChainId)!.nativeCurrency.symbol}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
            if (numberOfBoughtTicketsByMe > 0)
              RichText(
                text: TextSpan(
                  text: 'owned ',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(
                      text: '$numberOfBoughtTicketsByMe',
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    TextSpan(
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
          src: particleChainInfoByChainId(baseChainId)!.icon,
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
      String avatar = user.avatar;
      if (avatar == defaultAvatar) {
        avatar = avatarPlaceHolder(user.fullName);
      }
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Hero(
              tag: user.id,
              child: Img(
                src: avatar,
                alt: user.fullName,
                size: 100,
              ),
            ),
            space10,
            space10,
            Text(
              user.fullName,
              style: const TextStyle(
                fontSize: 33,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    });
  }
}
