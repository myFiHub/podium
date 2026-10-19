import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/widgets/ui/app_ui.dart';

Future<bool> showConfirmPopup(
    {required String title,
    String? message,
    RichText? richMessage,
    required String cancelText,
    required String confirmText,
    bool? isDangerous = false,
    Color? cancelColor,
    Color? confirmColor,
    Color? titleColor,
    Color? messageColor}) async {
  final dangerous = isDangerous == true;
  final iconColor = titleColor ?? (dangerous ? AppColors.danger : null);
  final response = await Get.dialog<bool>(
    barrierDismissible: !dangerous,
    AppDialog(
      title: title,
      icon: iconColor == null ? null : Icons.warning_amber_rounded,
      iconColor: iconColor ?? AppColors.primary,
      content: richMessage != null
          ? Text.rich(
              richMessage.text,
              textAlign: richMessage.textAlign,
              style: AppText.body.copyWith(height: 1.5),
            )
          : Text(
              message ?? '',
              style: messageColor == null
                  ? AppText.muted.copyWith(height: 1.45)
                  : TextStyle(color: messageColor, height: 1.45),
            ),
      stackActions: cancelText.length + confirmText.length > 22,
      actions: [
        AppSecondaryButton(
          label: cancelText,
          color: cancelColor == Colors.white ? null : cancelColor,
          onPressed: () => Get.closeOverlay(result: false),
        ),
        AppPrimaryButton(
          label: confirmText,
          color: confirmColor,
          onPressed: () => Get.closeOverlay(result: true),
        ),
      ],
    ),
  );
  return response ?? false;
}
