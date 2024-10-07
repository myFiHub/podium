import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/chechTicket/controllers/checkTicket_controller.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/widgets/groupsList.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/utils/truncate.dart';
import 'package:podium/widgets/button/button.dart';

class CheckTicketView extends GetWidget<CheckticketController> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        child: Container(
          color: ColorName.cardBackground,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Header(),
              // space10,
              // TicketBuyObserver(),
              space10,
              Expanded(
                child: Obx(
                  () {
                    final isLoading = controller.loadingUsers.value;
                    final allUsersToBuyTicketFrom =
                        controller.allUsersToBuyTicketFrom.value;
                    final allUsersList =
                        allUsersToBuyTicketFrom.values.toList();
                    return isLoading
                        ? const CircularProgressIndicator()
                        : Container(
                            height: Get.height - 190,
                            child: Scrollbar(
                              child: ListView.builder(
                                itemCount: allUsersList.length,
                                itemBuilder: (context, index) {
                                  final ticketSeller = allUsersList[index];
                                  return SingleTicketHolder(
                                      ticketSeller: ticketSeller,
                                      controller: controller);
                                },
                              ),
                            ),
                          );
                  },
                ),
              ),
              EnterButton(),
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
              element.boughtTicketToSpeak && element.speakTicketType != null);

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
          children: [
            Button(
              type: ButtonType.gradient,
              blockButton: true,
              onPressed: () {
                Navigator.pop(
                  context,
                  GroupAccesses(canEnter: true, canSpeak: canSpeak),
                );
              },
              text: text,
            ),
            space5,
            if (!canSpeak && canSpeakThough)
              Text(
                'you will be able to speak if you buy 1 the ticket to Speak',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              )
          ],
        );
      }
      return Button(
        onPressed: null,
        blockButton: true,
        child: Text(
            'you will be able to Enter if you buy 1 ticket required for Entering the room',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 14,
            )),
        color: Colors.grey,
      );
    });
  }
}

class TicketBuyObserver extends GetView<CheckticketController> {
  const TicketBuyObserver({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final group = controller.group.value!;
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

      return Column(
        children: [
          Row(
            children: [
              RichText(
                  text: TextSpan(children: [
                const TextSpan(
                    text: 'Remaining Tickets to ',
                    style: TextStyle(fontSize: 16, color: ColorName.greyText)),
                const TextSpan(
                    text: 'Enter: ',
                    style: const TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold)),
                TextSpan(
                    text: '$remainingTicketsToEnter  ',
                    style: const TextStyle(
                        color: ColorName.greyText,
                        fontWeight: FontWeight.bold)),
                if (!canSpeak && !showRawSpeakerType)
                  TextSpan(
                      text: 'Speak: ',
                      style: TextStyle(
                          color: canSpeak ? Colors.green : Colors.blue,
                          fontWeight: FontWeight.bold)),
                if (!canSpeak && !showRawSpeakerType)
                  TextSpan(
                      text: '$remainingTicketsToSpeak',
                      style: const TextStyle(
                          color: ColorName.greyText,
                          fontWeight: FontWeight.bold)),
              ])),
            ],
          ),
          if (showRawSpeakerType)
            RichText(
                text: TextSpan(children: [
              const TextSpan(
                  text: 'Speakers: ',
                  style:
                      const TextStyle(fontSize: 16, color: ColorName.greyText)),
              TextSpan(
                  text: parseSpeakerType(group.speakerType),
                  style: TextStyle(
                      color: canSpeak ? Colors.green : Colors.blue,
                      fontWeight: FontWeight.bold)),
            ])),
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
    final address = ticketSeller.address;
    return Container(
      key: ValueKey(ticketSeller.userInfo.id),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: ColorName.pageBackground,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: Get.width - 170,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userInfo.fullName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                space10,
                Text(
                    truncate(
                      address,
                      length: 16,
                    ),
                    style: const TextStyle(
                        fontSize: 16, color: ColorName.greyText)),
              ],
            ),
          ),
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
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(
        children: [
          const Text('Buy Tickets to:',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          space10,
          const Text('Enter',
              style:
                  const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          space10,
          Icon(Icons.login, color: Colors.red),
          space10,
          const Text('and Speak',
              style:
                  const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          space10,
          const Icon(Icons.mic, color: Colors.red)
        ],
      ),
      IconButton(
          onPressed: () {
            Get.close();
          },
          icon: const Icon(Icons.close))
    ]);
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

    return Container(
      child: checking || buying
          ? SizedBox(
              child: const CircularProgressIndicator(), width: 20, height: 20)
          : alreadyBoughtRequiredTickets
              ? const Icon(Icons.check, color: Colors.green)
              : Tooltip(
                  message: actionButtonText,
                  child: GestureDetector(
                    onTap: () {
                      controller.buyTicket(
                        ticketSeller: ticketSeller,
                      );
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                          color: Colors.green,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(5))),
                      padding: const EdgeInsets.all(5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (shouldBuyTicketToAccess &&
                              accessTicketType != null)
                            const Icon(
                              Icons.login,
                            ),
                          if (shouldBuyTicketToSpeak && speakTicketType != null)
                            const Icon(
                              Icons.mic,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
