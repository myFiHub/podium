import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/ui/aurora.dart';

/// A utility class for showing toast notifications using GetX snackbar.
/// Provides various methods for different types of notifications with consistent styling.
class Toast {
  /// Default duration for toast messages in seconds
  static const int _defaultDuration = 3;

  /// Default animation duration for toast messages
  static const Duration _defaultAnimationDuration = Duration(milliseconds: 350);

  /// Default margin for toast messages
  static const EdgeInsets _defaultMargin =
      EdgeInsets.symmetric(horizontal: 12, vertical: 8);

  static Color get _success => ColorName.success;
  static Color get _danger => ColorName.danger;
  static Color get _warning => ColorName.warning;

  /// Capitalizes the first letter, leaving URLs and addresses untouched.
  static String _sentenceCase(String text) {
    if (text.isEmpty) return text;
    final firstWord = text.split(' ').first;
    if (firstWord.contains('://') || firstWord.startsWith('0x')) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Common configuration for all toast messages
  static SnackbarController _showToast({
    required String title,
    required String message,
    required Color accentColor,
    required IconData icon,
    int? duration,
    TextButton? mainButton,
    SnackPosition position = SnackPosition.top,
    bool shake = false,
  }) {
    title = _sentenceCase(title == 'Error' ? 'Something went wrong' : title);
    message = _sentenceCase(message);
    return Get.snackbar(
      title,
      message,
      titleText: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: ColorName.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      messageText: message.isEmpty
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                message,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ColorName.greyText,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
      backgroundColor: ColorName.cardBackground.withAlpha(245),
      borderColor: accentColor.withAlpha(90),
      borderWidth: 1,
      borderRadius: 18,
      snackStyle: SnackStyle.floating,
      animationDuration: _defaultAnimationDuration,
      duration: Duration(seconds: duration ?? _defaultDuration),
      margin: _defaultMargin,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      mainButton: mainButton,
      shouldIconPulse: false,
      icon: Center(
        child: AppPopIn(
          shake: shake,
          delay: _defaultAnimationDuration,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accentColor.withAlpha(36),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
        ),
      ),
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
      snackPosition: position,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withAlpha(90),
          blurRadius: 24,
          offset: const Offset(0, 8),
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
      accentColor: _success,
      icon: Icons.check_circle_rounded,
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
      accentColor: _danger,
      icon: Icons.error_rounded,
      duration: duration,
      mainButton: mainButton,
      position: position,
      shake: true,
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
      accentColor: ColorName.primaryBlue,
      icon: Icons.info_rounded,
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
      accentColor: _warning,
      icon: Icons.warning_rounded,
      duration: duration,
      position: position,
      shake: true,
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
      accentColor: ColorName.greyText,
      icon: Icons.notifications_none_rounded,
      duration: duration,
      position: position,
    );
  }
}
