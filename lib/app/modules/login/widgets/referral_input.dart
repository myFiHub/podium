import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/lib/uuidUtils.dart';
import 'package:podium/app/modules/login/controllers/login_controller.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/widgets/ui/app_ui.dart';

class ReferralInput extends GetView<LoginController> {
  final void Function(String)? afterSubmit;
  ReferralInput({super.key, this.afterSubmit});

  // Reactive variable to track validation errors
  final validationError = ''.obs;

  void _showReferralDialog() {
    // Reset validation error when dialog opens
    validationError.value = '';

    Get.dialog(
      Dialog(
        backgroundColor: ColorName.cardBackground,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: const BorderSide(color: AppColors.border),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(28),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(
                        Icons.group_add_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Enter the Referrer ID', style: AppText.title),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Paste the ID shared by the person who invited you.',
                  style: AppText.muted,
                ),
                const SizedBox(height: 18),
                Obx(() {
                  final referrerNotFound = controller.referrerNotFound.value;
                  return TextField(
                    controller: controller.textController,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Referrer ID',
                      prefixIcon: const Icon(
                        Icons.badge_outlined,
                        size: 20,
                        color: ColorName.greyText,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.content_paste_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        onPressed: () {
                          controller.handlePaste();
                          Get.close();
                          afterSubmit?.call(controller.textController.text);
                        },
                        tooltip: 'Paste',
                      ),
                      errorText: referrerNotFound
                          ? 'User not found'
                          : validationError.value.isNotEmpty
                              ? validationError.value
                              : null,
                      errorMaxLines: 2,
                      errorStyle: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12,
                      ),
                    ),
                    onChanged: (value) {
                      // Clear referrer not found error when user types
                      if (controller.referrerNotFound.value) {
                        controller.referrerNotFound.value = false;
                      }

                      // Update validation error in real-time
                      final error = validateUuid(value);
                      validationError.value = error ?? '';
                    },
                  );
                }),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.close(),
                        style: TextButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: ColorName.greyText,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          // Validate UUID before proceeding
                          final error =
                              validateUuid(controller.textController.text);
                          if (error != null) {
                            // Update validation error to show it
                            validationError.value = error;
                            return;
                          }

                          Get.close();
                          controller.handleConfirm();
                          afterSubmit?.call(controller.textController.text);
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: const Text('Confirm'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Center(
          child: TextButton.icon(
            icon: const Icon(Icons.group_add_outlined, size: 18),
            label: const Text('Have a Referrer ID?'),
            style: TextButton.styleFrom(
              foregroundColor: ColorName.primaryBlue,
              backgroundColor: ColorName.primaryBlue.withAlpha(22),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              shape: const StadiumBorder(),
            ),
            onPressed: _showReferralDialog,
          ),
        ),
      );
    });
  }
}
