import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/login/controllers/login_controller.dart';
import 'package:podium/gen/colors.gen.dart';

class ReferralInput extends GetView<LoginController> {
  final void Function(String)? afterSubmit;
  const ReferralInput({super.key, this.afterSubmit});

  void _showReferralDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: ColorName.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the Referrer ID',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Obx(() {
                final referrerNotFound = controller.referrerNotFound.value;
                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.textController,
                        decoration: InputDecoration(
                          hintText: 'Enter the Referrer ID',
                          border: const OutlineInputBorder(),
                          errorText: referrerNotFound ? 'User not found' : null,
                          errorStyle: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.paste),
                      onPressed: () {
                        controller.handlePaste();
                        Get.close();
                        afterSubmit?.call(controller.textController.text);
                      },
                      tooltip: 'Paste',
                    ),
                  ],
                );
              }),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.close(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Get.close();
                      controller.handleConfirm();
                      afterSubmit?.call(controller.textController.text);
                    },
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoggingIn = controller.isLoggingIn.value ||
          controller.globalController.isAutoLoggingIn.value;
      if (isLoggingIn) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 32.0),
        child: OutlinedButton.icon(
          icon: const Icon(Icons.group_add_outlined, size: 18),
          label: const Text('Have a Referrer ID?'),
          style: OutlinedButton.styleFrom(
            foregroundColor: ColorName.primaryBlue,
            side: const BorderSide(color: ColorName.primaryBlue),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            textStyle: const TextStyle(fontWeight: FontWeight.w500),
          ),
          onPressed: _showReferralDialog,
        ),
      );
    });
  }
}
