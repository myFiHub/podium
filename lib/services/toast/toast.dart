import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A utility class for showing toast notifications using GetX snackbar.
/// Provides various methods for different types of notifications with consistent styling.
class Toast {
  /// Default duration for toast messages in seconds
  static const int _defaultDuration = 3;

  /// Default animation duration for toast messages
  static const Duration _defaultAnimationDuration = Duration(milliseconds: 300);

  /// Default margin for toast messages
  static const EdgeInsets _defaultMargin = EdgeInsets.all(10);

  /// Common configuration for all toast messages
  static SnackbarController _showToast({
    required String title,
    required String message,
    required Color backgroundColor,
    required Color textColor,
    required IconData icon,
    int? duration,
    TextButton? mainButton,
    SnackPosition position = SnackPosition.top,
  }) {
    return Get.snackbar(
      title,
      message,
      colorText: textColor,
      backgroundColor: backgroundColor,
      snackStyle: SnackStyle.floating,
      animationDuration: _defaultAnimationDuration,
      duration: Duration(seconds: duration ?? _defaultDuration),
      margin: _defaultMargin,
      mainButton: mainButton,
      shouldIconPulse: true,
      icon: Icon(icon, color: textColor),
      forwardAnimationCurve: Curves.elasticInOut,
      snackPosition: position,
      boxShadows: [
        BoxShadow(
          color: backgroundColor.withAlpha(128),
          spreadRadius: 1,
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  /// Shows a success toast message
  ///
  /// [title] - Optional title for the toast. Defaults to 'Success'
  /// [message] - Optional message for the toast. Defaults to 'Operation successful'
  /// [duration] - Duration in seconds before the toast disappears
  /// [position] - Position of the toast on the screen
  static SnackbarController success({
    String? title,
    String? message,
    int? duration,
    SnackPosition position = SnackPosition.top,
  }) {
    return _showToast(
      title: title ?? 'Success',
      message: message ?? 'Operation successful',
      backgroundColor: Colors.green,
      textColor: Colors.white,
      icon: Icons.check_circle,
      duration: duration,
      position: position,
    );
  }

  /// Shows an error toast message
  ///
  /// [title] - Optional title for the toast. Defaults to 'Error'
  /// [message] - Optional message for the toast. Defaults to 'Operation failed'
  /// [duration] - Duration in seconds before the toast disappears
  /// [mainButton] - Optional button to be shown in the toast
  /// [position] - Position of the toast on the screen
  static SnackbarController error({
    String? title,
    String? message,
    int? duration,
    TextButton? mainButton,
    SnackPosition position = SnackPosition.top,
  }) {
    return _showToast(
      title: title ?? 'Error',
      message: message ?? 'Operation failed',
      backgroundColor: Colors.red,
      textColor: Colors.white,
      icon: Icons.error,
      duration: duration,
      mainButton: mainButton,
      position: position,
    );
  }

  /// Shows an info toast message
  ///
  /// [title] - Optional title for the toast. Defaults to 'Info'
  /// [message] - Optional message for the toast. Defaults to 'Information'
  /// [duration] - Duration in seconds before the toast disappears
  /// [position] - Position of the toast on the screen
  static SnackbarController info({
    String? title,
    String? message,
    int? duration,
    SnackPosition position = SnackPosition.top,
  }) {
    return _showToast(
      title: title ?? 'Info',
      message: message ?? 'Information',
      backgroundColor: Colors.blue,
      textColor: Colors.white,
      icon: Icons.info,
      duration: duration,
      position: position,
    );
  }

  /// Shows a warning toast message
  ///
  /// [title] - Optional title for the toast. Defaults to 'Warning'
  /// [message] - Optional message for the toast. Defaults to 'Warning'
  /// [duration] - Duration in seconds before the toast disappears
  /// [position] - Position of the toast on the screen
  static SnackbarController warning({
    String? title,
    String? message,
    int? duration,
    SnackPosition position = SnackPosition.top,
  }) {
    return _showToast(
      title: title ?? 'Warning',
      message: message ?? 'Warning',
      backgroundColor: Colors.orange,
      textColor: Colors.white,
      icon: Icons.warning,
      duration: duration,
      position: position,
    );
  }

  /// Shows a neutral toast message
  ///
  /// [title] - Optional title for the toast. Defaults to 'Neutral'
  /// [message] - Optional message for the toast. Defaults to 'Neutral'
  /// [duration] - Duration in seconds before the toast disappears
  /// [position] - Position of the toast on the screen
  static SnackbarController neutral({
    String? title,
    String? message,
    int? duration,
    SnackPosition position = SnackPosition.top,
  }) {
    return _showToast(
      title: title ?? 'Neutral',
      message: message ?? 'Neutral',
      backgroundColor: Colors.grey,
      textColor: Colors.black,
      icon: Icons.info,
      duration: duration,
      position: position,
    );
  }
}
