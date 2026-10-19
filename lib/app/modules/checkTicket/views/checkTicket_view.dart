import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/checkTicket/controllers/checkTicket_controller.dart';
import 'package:podium/app/modules/createOutpost/controllers/create_outpost_controller.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/modules/global/widgets/loading_widget.dart';
import 'package:podium/app/modules/global/widgets/outpostsList.dart';
import 'package:podium/utils/truncate.dart';
import 'package:podium/widgets/ui/app_ui.dart';

class CheckTicketView extends GetWidget<CheckticketController> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Header(),
              // space10,
              // TicketBuyObserver(),
              const SizedBox(height: 14),
              Expanded(
                child: Obx(
                  () {
                    final isLoading = controller.loadingUsers.value;
                    final allUsersToBuyTicketFrom =
                        controller.allUsersToBuyTicketFrom.value;
                    final allUsersList =
                        allUsersToBuyTicketFrom.values.toList();
                    return isLoading
                        ? const Center(child: LoadingWidget())
                        : Scrollbar(
                            child: ListView.separated(
                              itemCount: allUsersList.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final ticketSeller = allUsersList[index];
                                return SingleTicketHolder(
                                    ticketSeller: ticketSeller,
                                    controller: controller);
                              },
                            ),
                          );
                  },
                ),
              ),
              const SizedBox(height: 14),
              const EnterButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class EnterButton extends GetView<CheckticketController> {
  const EnterButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final canEnter = controller.allUsersToBuyTicketFrom.value.values.any(
              (element) =>
                  element.boughtTicketToAccess &&
                  element.accessTicketType != null) ||
          controller.canEnterWithoutTicket;

      final canSpeak = controller.allUsersToBuyTicketFrom.value.values.any(
              (element) =>
                  element.boughtTicketToSpeak &&
                  element.speakTicketType != null) ||
          canISpeakWithoutTicket(outpost: controller.outpost.value!);

      final remainingTicketsToTalk = controller
          .allUsersToBuyTicketFrom.value.values
          .where((element) =>
              !element.boughtTicketToSpeak && element.speakTicketType != null)
          .toList()
          .length;
      final canSpeakThough = !canSpeak && remainingTicketsToTalk > 0;

      String text = "Enter";
      if (canSpeakThough) {
        text = 'Enter muted';
      }
      if (canSpeak) {
        text = 'Enter (you can speak)';
      }

      if (canEnter) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!canSpeak && canSpeakThough) ...[
              _Notice(
                icon: Icons.mic_off_rounded,
                color: AppColors.accent,
                text:
                    'you will be able to speak if you buy 1 the ticket to Speak',
              ),
              const SizedBox(height: 10),
            ],
            AppPrimaryButton(
              icon: canSpeak ? Icons.mic_rounded : Icons.login_rounded,
              onPressed: () {
                Navigator.pop(
                  context,
                  OutpostAccesses(canEnter: true, canSpeak: canSpeak),
                );
              },
              label: text,
            ),
          ],
        );
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Notice(
            icon: Icons.confirmation_number_outlined,
            color: AppColors.danger,
            text:
                'you will be able to Enter if you buy 1 ticket required for Entering the room',
          ),
          const SizedBox(height: 10),
          const AppPrimaryButton(
            label: 'Enter',
            icon: Icons.lock_outline_rounded,
            onPressed: null,
          ),
        ],
      );
    });
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _Notice({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: color, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class TicketBuyObserver extends GetView<CheckticketController> {
  const TicketBuyObserver({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final outpost = controller.outpost.value!;
      bool showRawSpeakerType = !controller.isSpeakBuyableByTicket;

      final allUsersToBuyTicketFrom =
          controller.allUsersToBuyTicketFrom.value.values.toList();

      final listOfRemainingTicketsToEnter = allUsersToBuyTicketFrom
          .where((element) =>
              !element.boughtTicketToAccess && element.accessTicketType != null)
          .toList();
      final remainingTicketsToEnter = listOfRemainingTicketsToEnter.length;

      final listOfRemainingTicketsToSpeak = allUsersToBuyTicketFrom
          .where((element) =>
              !element.boughtTicketToSpeak && element.speakTicketType != null)
          .toList();
      final remainingTicketsToSpeak = listOfRemainingTicketsToSpeak.length;

      final canSpeak =
          remainingTicketsToSpeak == 0 && controller.isSpeakBuyableByTicket;

      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          AppPill(
            label: 'Enter: $remainingTicketsToEnter left',
            color: AppColors.success,
            icon: Icons.login_rounded,
          ),
          if (!canSpeak && !showRawSpeakerType)
            AppPill(
              label: 'Speak: $remainingTicketsToSpeak left',
              color: AppColors.primary,
              icon: Icons.mic_rounded,
            ),
          if (showRawSpeakerType)
            AppPill(
              label: 'Speakers: ${parseSpeakerType(outpost.speak_type)}',
              color: canSpeak ? AppColors.success : AppColors.primary,
              icon: Icons.mic_rounded,
            ),
        ],
      );
    });
  }
}

class SingleTicketHolder extends StatelessWidget {
  const SingleTicketHolder({
    super.key,
    required this.ticketSeller,
    required this.controller,
  });

  final TicketSeller ticketSeller;
  final CheckticketController controller;

  @override
  Widget build(BuildContext context) {
    final userInfo = ticketSeller.userInfo;
    String address = ticketSeller.address;
    if (ticketSeller.accessTicketType ==
            BuyableTicketTypes.onlyPodiumPassHolders ||
        ticketSeller.speakTicketType ==
            BuyableTicketTypes.onlyPodiumPassHolders) {
      address = ticketSeller.userInfo.aptos_address!;
    }
    final accessPriceFullString = ticketSeller.accessPriceFullString;
    final speakPriceFullString = ticketSeller.speakPriceFullString;
    final showAccessPrice =
        accessPriceFullString != null && !ticketSeller.boughtTicketToAccess;
    final showSpeakPrice =
        speakPriceFullString != null && !ticketSeller.boughtTicketToSpeak;
    return AppCard(
      key: ValueKey(ticketSeller.userInfo.uuid),
      radius: AppRadius.md,
      color: AppColors.fill,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Img(
            src: userInfo.image ?? '',
            size: 40,
            alt: userInfo.name,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userInfo.name ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.cardTitle,
                ),
                const SizedBox(height: 2),
                Text(
                  truncate(
                    address,
                    length: 16,
                  ),
                  maxLines: 1,
                  style: AppText.caption,
                ),
                if (showAccessPrice || showSpeakPrice) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (showAccessPrice)
                        AppPill(
                          label: accessPriceFullString + ' (access)',
                          color: AppColors.accent,
                          icon: Icons.login_rounded,
                        ),
                      if (showSpeakPrice)
                        AppPill(
                          label: speakPriceFullString + ' (speak)',
                          color: AppColors.accent,
                          icon: Icons.mic_rounded,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Actions(
            ticketSeller: ticketSeller,
            controller: controller,
          )
        ],
      ),
    );
  }
}

class Header extends StatelessWidget {
  const Header({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 4, top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tickets required', style: AppText.title),
                const SizedBox(height: 4),
                Text(
                  'Buy tickets to enter and speak',
                  style: AppText.caption,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    AppPill(
                      label: 'Enter',
                      color: AppColors.success,
                      icon: Icons.login_rounded,
                    ),
                    AppPill(
                      label: 'Speak',
                      color: AppColors.primary,
                      icon: Icons.mic_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        AppIconButton(
          icon: Icons.close_rounded,
          tooltip: 'Close',
          size: 36,
          onTap: () {
            Get.close();
          },
        ),
      ],
    );
  }
}

class Actions extends StatelessWidget {
  const Actions({
    super.key,
    required this.ticketSeller,
    required this.controller,
  });

  final TicketSeller ticketSeller;
  final CheckticketController controller;

  @override
  Widget build(BuildContext context) {
    final boughtTicketToAccess = ticketSeller.boughtTicketToAccess;
    final boughtTicketToSpeak =
        ticketSeller.boughtTicketToSpeak || !controller.isSpeakBuyableByTicket;
    final checking = ticketSeller.checking;
    final buying = ticketSeller.buying;
    final shouldBuyTicketToAccess = !boughtTicketToAccess;
    final shouldBuyTicketToSpeak = !boughtTicketToSpeak;
    final alreadyBoughtRequiredTickets =
        ticketSeller.alreadyBoughtRequiredTickets;
    String actionButtonText = '';
    if (shouldBuyTicketToSpeak) {
      actionButtonText = 'Buy ticket to Speak';
    } else if (shouldBuyTicketToAccess) {
      actionButtonText = 'Buy ticket to Enter';
    }
    if (shouldBuyTicketToSpeak && shouldBuyTicketToAccess) {
      actionButtonText = 'Buy ticket to Enter and Speak';
    }
    final speakTicketType = ticketSeller.speakTicketType;
    final accessTicketType = ticketSeller.accessTicketType;

    if (checking || buying) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Center(child: LoadingWidget(size: 20)),
      );
    }
    if (alreadyBoughtRequiredTickets) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.success.withAlpha(30),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_rounded,
          color: AppColors.success,
          size: 20,
        ),
      );
    }
    return Tooltip(
      message: actionButtonText,
      child: FilledButton(
        onPressed: () {
          controller.buyTicket(
            ticketSeller: ticketSeller,
          );
        },
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: AppColors.onColor(AppColors.success),
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Buy'),
            if (shouldBuyTicketToAccess && accessTicketType != null) ...[
              const SizedBox(width: 4),
              const Icon(Icons.login_rounded, size: 16),
            ],
            if (shouldBuyTicketToSpeak && speakTicketType != null) ...[
              const SizedBox(width: 4),
              const Icon(Icons.mic_rounded, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}
