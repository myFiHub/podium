import 'package:animated_icon/animated_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/widgets/img.dart';
import 'package:podium/app/modules/login/controllers/login_controller.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/utils/truncate.dart';
import 'package:podium/widgets/button/button.dart';

class PrejoinReferralView extends GetView<LoginController> {
  const PrejoinReferralView.PreJoin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            space10,
            RichText(
              text: const TextSpan(
                style:
                    TextStyle(color: Colors.white, fontSize: 18, height: 1.5),
                children: [
                  TextSpan(
                    text: 'In order to use ',
                  ),
                  TextSpan(
                    text: 'Podium',
                    style: TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: ', you need to be ',
                  ),
                  TextSpan(
                    text: 'Referred ',
                    style: TextStyle(
                        color: Colors.green, fontStyle: FontStyle.italic),
                  ),
                  TextSpan(
                    text: ' by an existing user ',
                  ),
                  TextSpan(
                    text: 'or hold at least one key or pass',
                    style: TextStyle(
                        color: Colors.red, fontStyle: FontStyle.italic),
                  ),
                  TextSpan(
                    text: '.',
                  ),
                ],
              ),
            ),
            const _InternalWalletAddress(),
            space5,
            // const _ExternalWalletConnectButton(),
            const _ReferralStatus(),
            space10,
            const _AccessUsingTicket(),
          ],
        ),
      ),
    );
  }
}

class _ExternalWalletConnectButton extends GetView<GlobalController> {
  const _ExternalWalletConnectButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final externalWalletAddress = controller.connectedWalletAddress.value;
      final connected = externalWalletAddress.isNotEmpty;
      return Button(
        size: ButtonSize.SMALL,
        blockButton: true,
        type: connected ? ButtonType.outline2x : ButtonType.gradient,
        // loading: loadingExternalWalletActivation,
        onPressed: () {
          if (externalWalletAddress.isNotEmpty) {
            return;
          }
          controller.connectToWallet();
        },
        child: Text(
          connected ? 'External Wallet Connected' : 'Connect External Wallet',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      );
    });
  }
}

class _InternalWalletAddress extends GetView<LoginController> {
  const _InternalWalletAddress({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final internalWalletAddress = controller.internalWalletAddress.value;
      final balance = controller.internalWalletBalance.value;
      return Container(
        width: Get.width - 20,
        decoration: BoxDecoration(
          color: ColorName.cardBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Your Internal Wallet Address",
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (balance.isNotEmpty)
                Text(
                  "Balance: $balance MOVE",
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 12,
                  ),
                ),
              space5,
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                              ClipboardData(text: internalWalletAddress))
                          .then(
                        (_) => Toast.info(
                          title: "Copied",
                          message: 'Address copied to clipboard',
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Text(
                          truncate(internalWalletAddress, length: 16),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        space5,
                        const Icon(
                          Icons.copy,
                          color: Colors.blueAccent,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                  space10,
                  Tooltip(
                    message: 'Refresh Balance',
                    child: AnimateIcon(
                      key: UniqueKey(),
                      onTap: () {
                        controller.getBalance();
                      },
                      color: Colors.blueAccent,
                      iconType: IconType.animatedOnTap,
                      height: 20,
                      width: 20,
                      animateIcon: AnimateIcons.refresh,
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _AccessUsingTicket extends GetView<LoginController> {
  const _AccessUsingTicket({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Obx(() {
        final ticketHoldersList =
            controller.podiumUsersToBuyEntryTicketFrom.value;
        return ListView.builder(
          shrinkWrap: true,
          itemCount: ticketHoldersList.length,
          itemBuilder: (context, index) {
            return _ProfileCard(
              key: ValueKey(ticketHoldersList[index].uuid + 'podiumUser'),
              user: ticketHoldersList[index],
            );
          },
        );
      }),
    );
  }
}

class _ProfileCard extends GetView<LoginController> {
  final UserModel user;
  const _ProfileCard({
    super.key,
    required this.user,
  });
  @override
  Widget build(BuildContext context) {
    final balance = controller.internalWalletBalance.value;

    // final keyPrice = user.lastKeyPrice ?? '0';
    // final binIntKeyPrice = BigInt.from(int.parse(keyPrice));
    // final valueToShow = bigIntWeiToDouble(binIntKeyPrice).toString();
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: ColorName.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      width: Get.width - 20,
      child: Column(
        children: [
          const Text(
            'Podium Pass',
            style: TextStyle(
              color: Colors.blueAccent,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Img(
                src: user.image ?? '',
                alt: user.name,
                size: 50,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name ?? 'Podium team member',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    truncate(user.uuid, length: 20),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Followers, Following, Posting
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text(
                    'Address',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    truncate(user.aptos_address!, length: 20),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Write Message Button
          SizedBox(
              width: double.infinity,
              child: Obx(() {
                final loadingId = controller.loadingBuyTicketId.value;
                final balance = controller.internalWalletBalance.value;
                return Button(
                  loading: loadingId == user.uuid,
                  type: ButtonType.outline2x,
                  onPressed: () async {
                    if (balance.isEmpty) {
                      await controller.getBalance();
                      return;
                    } else if (balance == '0.0') {
                      Toast.error(
                        title: "Insufficient Balance",
                        message:
                            'You do not have enough balance to buy a ticket',
                        mainbutton: TextButton(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(
                                text: user.aptos_address!,
                              ),
                            );
                            Get.closeAllSnackbars();
                            Toast.info(
                              title: "Copied",
                              message: 'Address copied to clipboard',
                            );
                          },
                          child: const Text('Copy Address'),
                        ),
                      );
                      return;
                    } else {
                      controller.buyTicket(user: user);
                    }
                  },
                  child: RichText(
                      text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Buy Podium Pass  ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  )),
                );
              })),
        ],
      ),
    );
  }
}

class _ReferralStatus extends GetView<LoginController> {
  const _ReferralStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final referrer = controller.referrer.value;
      final noReferrer = referrer == null;
      if (noReferrer) {
        return const SizedBox.shrink();
      }
      return Container(
        width: Get.width - 20,
        decoration: BoxDecoration(
          color: ColorName.cardBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Referral Status",
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              if (noReferrer)
                const Text(
                  "No Referrer",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 20,
                  ),
                ),
              if (!noReferrer)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${referrer.name} doesnt have any unused referal code ",
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    });
  }
}
