import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/widgets/img.dart';
import 'package:podium/app/modules/login/controllers/login_controller.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/providers/api/models/starsArenaUser.dart';
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
            // Button(
            //   onPressed: () async {
            //     final databaseRef = FirebaseDatabase.instance
            //         .ref(FireBaseConstants.podiumDefinedEntryAddresses);
            //     await databaseRef.set([
            //       PodiumDefinedEntryAddress(
            //         address: '',
            //         handle: 'jomari_p',
            //         type: BuyableTicketTypes.onlyArenaTicketHolders,
            //       ).toJson(),
            //       PodiumDefinedEntryAddress(
            //         address: '',
            //         handle: '0xLuis_',
            //         type: BuyableTicketTypes.onlyArenaTicketHolders,
            //       ).toJson(),
            //       PodiumDefinedEntryAddress(
            //         address: '',
            //         handle: 'mohsenparvar',
            //         type: BuyableTicketTypes.onlyArenaTicketHolders,
            //       ).toJson(),
            //     ]);
            //   },
            //   text: 'Join',
            // ),
            space10,
            RichText(
              text: TextSpan(
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
                    text: ', you need to be referred by an existing user ',
                  ),
                  TextSpan(
                    text: 'or hold at least one key or ticket',
                    style: TextStyle(
                        color: Colors.red, fontStyle: FontStyle.italic),
                  ),
                  TextSpan(
                    text: '.',
                  ),
                ],
              ),
            ),
            _InternalWalletAddress(),
            space5,
            _ExternalWalletConnectButton(),
            _ReferralStatus(),
            space10,
            _AccessUsingTicket(),
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
      final externalWalletChainId = controller.externalWalletChainId.value;
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
          style: TextStyle(
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
              Text(
                "Your Internal Wallet Address",
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (balance.isNotEmpty)
                Text(
                  "Balance: $balance AVAX",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 12,
                  ),
                ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: internalWalletAddress))
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
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    space5,
                    Icon(
                      Icons.copy,
                      color: Colors.blueAccent,
                      size: 16,
                    ),
                  ],
                ),
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
            controller.starsArenaUsersToBuyEntryTicketFrom.value;
        return ListView.builder(
          shrinkWrap: true,
          itemCount: ticketHoldersList.length,
          itemBuilder: (context, index) {
            return _ProfileCard(
              key: ValueKey(ticketHoldersList[index].id + 'starsArenaUser'),
              user: ticketHoldersList[index],
            );
          },
        );
      }),
    );
  }
}

class _ProfileCard extends GetView<LoginController> {
  final StarsArenaUser user;
  const _ProfileCard({
    super.key,
    required this.user,
  });
  @override
  Widget build(BuildContext context) {
    final keyPrice = user.lastKeyPrice ?? '0';
    final binIntKeyPrice = BigInt.from(int.parse(keyPrice));
    final valueToShow = bigIntWeiToDouble(binIntKeyPrice).toString();
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: ColorName.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      width: Get.width - 20,
      child: Column(
        children: [
          Text(
            'Arena ticket',
            style: TextStyle(
              color: Colors.blueAccent,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Img(
                src: user.twitterPicture,
                alt: user.twitterName,
                size: 50,
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.twitterName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    truncate(user.id, length: 20),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          // Followers, Following, Posting
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    'Followers',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    user.followerCount.toString(),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    'Address',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    truncate(user.address, length: 20),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          // Write Message Button
          SizedBox(
              width: double.infinity,
              child: Obx(() {
                final loadingId = controller.loadingBuyTicketId.value;
                return Button(
                  loading: loadingId == user.id,
                  type: ButtonType.outline2x,
                  onPressed: () {
                    controller.buyTicket(user: user);
                  },
                  child: RichText(
                      text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Buy Arena Ticket for ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      TextSpan(
                        text: valueToShow,
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 16,
                        ),
                      ),
                      TextSpan(
                        text: " AVAX",
                        style: TextStyle(
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
        return SizedBox.shrink();
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
              Text(
                "Referral Status",
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              if (noReferrer)
                Text(
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
                      "${referrer!.fullName} doesnt have any unused referal code ",
                      style: TextStyle(
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
