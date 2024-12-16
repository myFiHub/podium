import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Toast {
  static void success({String? title, String? message, int duration = 3}) {
    Get.snackbar(
      title ?? 'Success',
      message ?? 'Operation successful',
      colorText: Colors.white,
      backgroundColor: Colors.green,
      snackStyle: SnackStyle.floating,
      animationDuration: const Duration(milliseconds: 300),
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(10),
      shouldIconPulse: true,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      forwardAnimationCurve: Curves.elasticInOut,
      boxShadows: [
        BoxShadow(
          color: Colors.green.withOpacity(0.5),
          spreadRadius: 1,
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  static void error(
      {String? title,
      String? message,
      int duration = 3,
      TextButton? mainbutton}) {
    Get.snackbar(
      title ?? 'Error',
      message ?? 'Operation failed',
      colorText: Colors.white,
      backgroundColor: Colors.red,
      snackStyle: SnackStyle.floating,
      animationDuration: const Duration(milliseconds: 300),
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(10),
      mainButton: mainbutton,
      shouldIconPulse: true,
      icon: const Icon(Icons.error, color: Colors.white),
      forwardAnimationCurve: Curves.elasticInOut,
      boxShadows: [
        BoxShadow(
          color: Colors.red.withOpacity(0.5),
          spreadRadius: 1,
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  static void info({String? title, String? message, int duration = 3}) {
    Get.snackbar(
      title ?? 'Info',
      message ?? 'Information',
      colorText: Colors.white,
      backgroundColor: Colors.blue,
      snackStyle: SnackStyle.floating,
      animationDuration: const Duration(milliseconds: 300),
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(10),
      shouldIconPulse: true,
      icon: const Icon(Icons.info, color: Colors.white),
      forwardAnimationCurve: Curves.elasticInOut,
      boxShadows: [
        BoxShadow(
          color: Colors.blue.withOpacity(0.5),
          spreadRadius: 1,
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  static void warning({String? title, String? message, int duration = 3}) {
    Get.snackbar(
      title ?? 'Warning',
      message ?? 'Warning',
      colorText: Colors.white,
      backgroundColor: Colors.orange,
      snackStyle: SnackStyle.floating,
      animationDuration: const Duration(milliseconds: 300),
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(10),
      shouldIconPulse: true,
      icon: const Icon(Icons.warning, color: Colors.white),
      forwardAnimationCurve: Curves.elasticInOut,
      boxShadows: [
        BoxShadow(
          color: Colors.orange.withOpacity(0.5),
          spreadRadius: 1,
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  static void neutral({String? title, String? message, int duration = 3}) {
    Get.snackbar(
      title ?? 'Neutral',
      message ?? 'Neutral',
      colorText: Colors.black,
      backgroundColor: Colors.grey,
      snackStyle: SnackStyle.floating,
      animationDuration: const Duration(milliseconds: 300),
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(10),
      shouldIconPulse: true,
      icon: const Icon(Icons.info, color: Colors.white),
      forwardAnimationCurve: Curves.elasticInOut,
      boxShadows: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.5),
          spreadRadius: 1,
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }
}
