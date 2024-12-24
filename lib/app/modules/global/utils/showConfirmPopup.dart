import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/gen/colors.gen.dart';

Future<bool> showConfirmPopup({
  required String title,
  String? message,
  RichText? richMessage,
  required String cancelText,
  required String confirmText,
}) async {
  final response = await Get.dialog(
    AlertDialog(
      backgroundColor: ColorName.cardBackground,
      title: Text(title),
      content: richMessage ?? Text(message ?? ''),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.pop(Get.context!, false);
            },
            child: Text(cancelText)),
        TextButton(
            onPressed: () {
              Navigator.pop(Get.context!, true);
            },
            child: Text(confirmText))
      ],
    ),
  );
  return response == null ? false : response;
}
