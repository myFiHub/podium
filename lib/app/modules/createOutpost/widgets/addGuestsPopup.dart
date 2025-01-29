import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/createOutpost/controllers/create_outpost_controller.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/providers/api/luma/models/addGuest.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:podium/widgets/textField/textFieldRounded.dart';

class AddGuestsPopup extends GetView<CreateOutpostController> {
  const AddGuestsPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        child: Container(
          color: ColorName.cardBackground,
          padding: const EdgeInsets.all(20),
          height: Get.height * 0.5,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Guests',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Get.close();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              space10,
              _Form(),
              space10,
              space10,
              space10,
              const _GuestsList(),
              const _DoneButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoneButton extends StatelessWidget {
  const _DoneButton({super.key});
  @override
  Widget build(BuildContext context) {
    return Button(
      type: ButtonType.outline,
      size: ButtonSize.LARGE,
      blockButton: true,
      text: 'Done',
      onPressed: () {
        Get.close();
      },
    );
  }
}

class _GuestsList extends GetView<CreateOutpostController> {
  const _GuestsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Obx(
        () {
          final guestsList = controller.lumaGuests;
          return ListView.builder(
            itemCount: guestsList.length,
            itemBuilder: (context, index) {
              return _GuestItem(
                  guest: guestsList[index], controller: controller);
            },
          );
        },
      ),
    );
  }
}

class _GuestItem extends StatelessWidget {
  const _GuestItem({super.key, required this.guest, required this.controller});
  final AddGuestModel guest;
  final CreateOutpostController controller;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: ColorName.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ColorName.cardBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Text(
                guest.email,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ColorName.white,
                ),
              ),
              if (guest.name != null && guest.name != '') ...[
                Text(
                  guest.name!,
                  style: const TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
                    color: ColorName.greyText,
                  ),
                ),
              ]
            ],
          ),

          space5,
          // delete icon
          IconButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              controller.removeGuest(guest.email);
            },
            icon: const Icon(
              Icons.delete,
            ),
          ),
        ],
      ),
    );
  }
}

class _Form extends GetView<CreateOutpostController> {
  _Form({super.key});
  final emailController = TextEditingController();
  final nameController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    // form contains an input for name, input for email a dropdown for host type and a button to add the host
    return Form(
      child: Column(
        children: [
          SizedBox(
            height: 60,
            child: Input(
              hintText: 'Email',
              controller: emailController,
            ),
          ),
          SizedBox(
            height: 60,
            child: Input(
              hintText: 'Name (optional)',
              controller: nameController,
            ),
          ),
          space10,
          space10,
          Button(
            blockButton: true,
            type: ButtonType.gradient,
            size: ButtonSize.MEDIUM,
            text: 'Add Guest',
            onPressed: () {
              // add the guest to the list
              final email = emailController.text;
              final name = nameController.text;
              // is email?
              if (email.contains('@')) {
                controller.addGuest(email, name);
              } else {
                Toast.warning(
                  message: 'Please enter a valid email',
                );
                return;
              }
              // clear the inputs
              nameController.clear();
              emailController.clear();
            },
          ),
        ],
      ),
    );
  }
}

openAddGuestsDialog() {
  Get.dialog(
    const AddGuestsPopup(),
  );
}
