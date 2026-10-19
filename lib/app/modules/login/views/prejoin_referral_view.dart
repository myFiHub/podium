import 'package:animated_icon/animated_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/widgets/img.dart';
import 'package:podium/app/modules/login/controllers/login_controller.dart';
import 'package:podium/app/modules/login/widgets/referral_input.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/root.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/truncate.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:podium/widgets/ui/app_ui.dart';

class PrejoinReferralView extends GetView<LoginController> {
  const PrejoinReferralView.PreJoin({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppPageHeader(
                title: 'Get access',
                subtitle: 'One last step before you join',
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _AccessIntro(),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _InternalWalletAddress(),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _ReferralStatus(),
              ),
              ReferralInput(
                afterSubmit: (referrerId) {
                  controller.isLoggingIn.value = true;
                  Get.back();
                },
              ),
              const _AccessUsingTicket(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessIntro extends StatelessWidget {
  const _AccessIntro();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(28),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              Icons.lock_open_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: ColorName.greyText,
                  fontSize: 14,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'In order to use '),
                  TextSpan(
                    text: 'Podium',
                    style: TextStyle(
                      color: ColorName.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(text: ', you need to be '),
                  TextSpan(
                    text: 'referred',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(text: ' by an existing user '),
                  TextSpan(
                    text: 'or hold at least one key or pass',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _ExternalWalletConnectButton extends GetView<GlobalController> {
  const _ExternalWalletConnectButton();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final externalWalletAddress = controller.connectedWalletAddress.value;
      final connected = externalWalletAddress.isNotEmpty;
      return Button(
        size: ButtonSize.SMALL,
        blockButton: true,
        type: connected ? ButtonType.outline2x : ButtonType.gradient,
        onPressed: () {
          if (externalWalletAddress.isNotEmpty) {
            return;
          }
          controller.connectToWallet();
        },
        child: Text(
          connected ? 'External Wallet Connected' : 'Connect External Wallet',
          style: TextStyle(
            color: ColorName.white,
            fontSize: 16,
          ),
        ),
      );
    });
  }
}

class _InternalWalletAddress extends GetView<LoginController> {
  const _InternalWalletAddress();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final internalWalletAddress = controller.internalWalletAddress.value;
      final balance = controller.internalWalletBalance.value;
      return AppCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'YOUR INTERNAL WALLET',
                    style: AppText.label,
                  ),
                ),
                if (balance.isNotEmpty)
                  AppPill(
                    label: '$balance MOVE',
                    color: AppColors.success,
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                const SizedBox(width: 4),
                Tooltip(
                  message: 'Refresh Balance',
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: AnimateIcon(
                      key: UniqueKey(),
                      onTap: () {
                        controller.getBalance();
                      },
                      color: AppColors.primary,
                      iconType: IconType.animatedOnTap,
                      height: 20,
                      width: 20,
                      animateIcon: AnimateIcons.refresh,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Material(
                color: AppColors.fill,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            truncate(internalWalletAddress, length: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ColorName.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.copy_rounded,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _AccessUsingTicket extends GetView<LoginController> {
  const _AccessUsingTicket();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Obx(() {
        final ticketHoldersList =
            controller.podiumUsersToBuyEntryTicketFrom.value;
        if (ticketHoldersList.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionHeader(
              title: 'Or buy a Podium Pass',
              count: ticketHoldersList.length,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: ticketHoldersList.length,
                itemBuilder: (context, index) {
                  return _ProfileCard(
                    key: ValueKey('${ticketHoldersList[index].uuid}podiumUser'),
                    user: ticketHoldersList[index],
                  );
                },
              ),
            ),
          ],
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
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Img(
                src: user.image ?? '',
                alt: user.name,
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name ?? 'Podium team member',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.cardTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      truncate(user.uuid, length: 20),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppPill(
                label: 'Podium Pass',
                color: AppColors.primary,
                icon: Icons.confirmation_number_outlined,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.fill,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: [
                Text('ADDRESS', style: AppText.label),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    truncate(user.aptos_address!, length: 20),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ColorName.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Obx(() {
            final loadingId = controller.loadingBuyTicketId.value;
            final balance = controller.internalWalletBalance.value;
            return AppPrimaryButton(
              label: 'Buy Podium Pass',
              icon: Icons.confirmation_number_outlined,
              loading: loadingId == user.uuid,
              onPressed: () async {
                if (balance.isEmpty) {
                  await controller.getBalance();
                  return;
                } else if (balance == '0.0') {
                  Toast.error(
                    title: "Insufficient Balance",
                    message: 'You do not have enough balance to buy a ticket',
                    mainButton: TextButton(
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
            );
          }),
        ],
      ),
    );
  }
}

class _ReferralStatus extends GetView<LoginController> {
  const _ReferralStatus();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final referrer = controller.referrer.value;
      if (referrer == null) {
        return const SizedBox.shrink();
      }
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.danger.withAlpha(20),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.danger.withAlpha(70)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: AppColors.danger,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Referral status', style: AppText.cardTitle),
                  const SizedBox(height: 4),
                  Text(
                    "${referrer.name} doesn't have any unused referral codes",
                    style: TextStyle(
                      color: ColorName.greyText,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
