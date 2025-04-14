import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:podium/env.dart';
import 'package:podium/utils/logger.dart';

class OneSignalController extends GetxController {
  static String _oneSignalAppId = Env.oneSignalApiKey;
  bool _isInitialized = false;

  @override
  void onInit() {
    super.onInit();
    initialize();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  /// Get the OneSignal device ID
  Future<String?> getOneSignalId() async {
    try {
      if (!_isInitialized) {
        l.e('OneSignal not initialized');
        return null;
      }

      final oneSignalId = await OneSignal.User.getOnesignalId();
      l.d('OneSignal ID: $oneSignalId');
      return oneSignalId;
    } catch (e) {
      l.e('Error getting OneSignal ID: $e');
      return null;
    }
  }

  /// Get the external user ID (your app's user ID)
  Future<String?> getExternalUserId() async {
    try {
      if (!_isInitialized) {
        l.e('OneSignal not initialized');
        return null;
      }

      final externalId = await OneSignal.User.getExternalId();
      l.d('External User ID: $externalId');
      return externalId;
    } catch (e) {
      l.e('Error getting external user ID: $e');
      return null;
    }
  }

  /// Login a user with your app's user ID
  Future<bool> login(String userId) async {
    try {
      if (!_isInitialized) {
        l.e('OneSignal not initialized');
        return false;
      }

      if (userId.isEmpty) {
        l.e('Cannot login with empty user ID');
        return false;
      }

      // First logout any existing user
      await dismiss();

      // Login with new user ID
      await OneSignal.login(userId);
      l.d('User logged in with ID: $userId');

      // Wait for OneSignal to be ready and get the ID
      String? oneSignalId;
      int retryCount = 0;
      const maxRetries = 5;

      while (oneSignalId == null && retryCount < maxRetries) {
        await Future.delayed(const Duration(seconds: 2));
        oneSignalId = await getOneSignalId();
        retryCount++;
        l.d('Attempt $retryCount to get OneSignal ID');
      }

      if (oneSignalId == null) {
        l.e('Failed to get OneSignal ID after $maxRetries attempts');
        return false;
      }

      l.d('Successfully logged in with OneSignal ID: $oneSignalId');
      return true;
    } catch (e) {
      l.e('Error logging in user: $e');
      return false;
    }
  }

  Future<void> initialize() async {
    try {
      if (_isInitialized) {
        l.d('OneSignal already initialized');
        return;
      }

      // Set log level
      OneSignal.Debug.setLogLevel(
        kDebugMode ? OSLogLevel.verbose : OSLogLevel.none,
      );
      OneSignal.Debug.setAlertLevel(
        OSLogLevel.none,
      );

      // Initialize OneSignal
      OneSignal.initialize(_oneSignalAppId);
      l.d('OneSignal initialized with app ID: $_oneSignalAppId');

      // Setup Live Activities
      OneSignal.LiveActivities.setupDefault();

      // Clear all notifications
      OneSignal.Notifications.clearAll();

      // Add observers for push subscription
      OneSignal.User.pushSubscription.addObserver((state) {
        l.d('Push Subscription State: ${state.current.jsonRepresentation()}');
      });

      // Add observer for user state changes
      OneSignal.User.addObserver((state) {
        l.d('User State Changed: ${state.jsonRepresentation()}');
      });

      // Add permission observer
      OneSignal.Notifications.addPermissionObserver((state) {
        l.d('Notification Permission: $state');
      });

      // Add click listener for notifications
      OneSignal.Notifications.addClickListener((event) {
        l.d('Notification Clicked: ${event.notification.jsonRepresentation()}');
      });

      // Add foreground notification listener
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        l.d('Foreground Notification: ${event.notification.jsonRepresentation()}');
        event.notification.display();
      });

      // Add in-app message listeners
      OneSignal.InAppMessages.addClickListener((event) {
        l.d('In-App Message Clicked: ${event.result.jsonRepresentation()}');
      });

      OneSignal.InAppMessages.addWillDisplayListener((event) {
        l.d('In-App Message Will Display: ${event.message.messageId}');
      });

      OneSignal.InAppMessages.addDidDisplayListener((event) {
        l.d('In-App Message Did Display: ${event.message.messageId}');
      });

      OneSignal.InAppMessages.addWillDismissListener((event) {
        l.d('In-App Message Will Dismiss: ${event.message.messageId}');
      });

      OneSignal.InAppMessages.addDidDismissListener((event) {
        l.d('In-App Message Did Dismiss: ${event.message.messageId}');
      });

      _isInitialized = true;
      l.d('OneSignal setup completed');
    } catch (e) {
      l.e('Error initializing OneSignal: $e');
      rethrow;
    }
  }

  Future<void> dismiss() async {
    try {
      // Clear all notifications
      await OneSignal.Notifications.clearAll();

      // Pause in-app messages
      await OneSignal.InAppMessages.paused(true);

      // Logout user to clear any user data
      await OneSignal.logout();

      // Clear any stored tags
      await OneSignal.User.removeTags(['*']);

      l.d('OneSignal dismissed successfully');
    } catch (e) {
      l.e('Error dismissing OneSignal: $e');
      rethrow;
    }
  }
}
