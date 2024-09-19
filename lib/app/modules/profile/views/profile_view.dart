import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/modules/groupDetail/widgets/usersList.dart';
import 'package:podium/env.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:reown_appkit/reown_appkit.dart';

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
              FollowButton(userId: controller.userInfo.value!.id),
              space10,
              BuyTicket(
                user: controller.userInfo.value!,
              )
            ],
          ),
        ),
      ),
    );
  }
}

class BuyTicket extends GetView<ProfileController> {
  final UserInfoModel user;
  const BuyTicket({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = controller.isGettingTicketPrice.value;
      final priceError = controller.getPriceError.value;
      final connectedWallet = controller.connectedWallet.value;
      final price = controller.ticketPriceFor1Share.value;
      final isBuyingTicket = controller.isBuyingTicket.value;

      Widget insideButton;

      if (connectedWallet == '') {
        insideButton = const Text("connect wallet to buy ticket");
      } else {
        if (priceError != '') {
          insideButton = Text(priceError);
        } else {
          insideButton = Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Buy Ticket "),
              Text(price.toString()),
              space5,
              Text(ReownAppKitModalNetworks.getNetworkById(
                      Env.chainNamespace, Env.chainId)!
                  .currency)
            ],
          );
        }
      }
      if (price == 0.0) {
        insideButton = const Text('Buying ticket is disabled for now :(');
      }
      return Button(
        type: ButtonType.gradient,
        loading: isLoading || isBuyingTicket,
        blockButton: true,
        child: insideButton,
        onPressed: () {
          if (price == 0.0) {
            return;
          }
          if (isLoading) {
            return;
          }
          if (priceError != '') {
            controller.getBuyPriceForOneShare();
            return;
          }
          if (connectedWallet == '') {
            controller.globalController.connectToWallet();
            return;
          }
          controller.buyTicket();
        },
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
