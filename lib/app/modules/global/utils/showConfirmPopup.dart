import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/gen/colors.gen.dart';

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
  final response = await Get.dialog(
    barrierDismissible: isDangerous == true ? false : true,
    AlertDialog(
      backgroundColor: ColorName.cardBackground,
      title: Text(
        title,
        style: TextStyle(color: titleColor ?? Colors.white),
      ),
      content: richMessage ??
          Text(
            message ?? '',
            style: TextStyle(color: messageColor ?? Colors.white),
          ),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.pop(Get.context!, false);
            },
            child: Text(cancelText,
                style: TextStyle(color: cancelColor ?? Colors.white))),
        TextButton(
            onPressed: () {
              Navigator.pop(Get.context!, true);
            },
            child: Text(confirmText,
                style: TextStyle(color: confirmColor ?? Colors.white)))
      ],
    ),
  );
  return response == null ? false : response;
}
