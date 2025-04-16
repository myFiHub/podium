import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:podium/env.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';

class OneSignalService extends GetxService {
  static String _oneSignalAppId = Env.oneSignalApiKey;
  bool _isInitialized = false;
  bool get initialized => _isInitialized;
  bool _isLoggedIn = false;
  bool get loggedIn => _isLoggedIn;

  @override
  void onInit() {
    super.onInit();
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
      return await OneSignal.User.getOnesignalId();
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
      return await OneSignal.User.getExternalId();
    } catch (e) {
      l.e('Error getting external user ID: $e');
      return null;
    }
  }

  /// Login a user with your app's user ID
  Future<bool> login(String userId) async {
    try {
      if (userId.isEmpty) {
        l.e('Cannot login with empty user ID');
        return false;
      }

      // Initialize OneSignal if not already initialized
      if (!_isInitialized) {
        await initialize();
      }

      // Login the user
      await OneSignal.login(userId);
      _isLoggedIn = true;
      l.d('onesignal: Logged in with user ID: $userId');

      // Ensure subscription is active after login
      await OneSignal.User.pushSubscription.optIn();
      l.d('onesignal: Ensured push subscription is active');
      final token = OneSignal.User.pushSubscription.token;
      final id = OneSignal.User.pushSubscription.id;
      l.d('onesignal: Push subscription token: $token');
      l.d('onesignal: Push id: $id');

      return true;
    } catch (e) {
      l.e('Error logging in user: $e');
      return false;
    }
  }

  Future<void> initialize() async {
    l.d('onesignal: Initializing OneSignal');
    try {
      if (_isInitialized) {
        l.d('onesignal: Already initialized');
        return;
      }

      // Set log level first
      OneSignal.Debug.setLogLevel(
        kDebugMode ? OSLogLevel.verbose : OSLogLevel.none,
      );
      OneSignal.Debug.setAlertLevel(OSLogLevel.none);

      // Initialize OneSignal
      OneSignal.initialize(_oneSignalAppId);
      l.d('onesignal: OneSignal initialized');

      // Request notification permission
      final hasPermission =
          await OneSignal.Notifications.requestPermission(true);
      if (!hasPermission) {
        l.e('onesignal: Notification permission denied');
        Toast.error(
          title: 'Notifications Disabled',
          message:
              'You will miss important updates. You can enable notifications in your device settings.',
        );
        return;
      }
      l.d('onesignal: Notification permission granted');

      // Setup Live Activities
      OneSignal.LiveActivities.setupDefault();
      l.d('onesignal: Live Activities setup');

      // Clear all notifications
      OneSignal.Notifications.clearAll();

      // Add observers for push subscription
      OneSignal.User.pushSubscription.addObserver((state) async {
        l.d('onesignal: Push Subscription State: ${state.current.jsonRepresentation()}');

        // Log detailed subscription information
        final subscriptionState = state.current;
        l.d('onesignal: Detailed Subscription Info:');
        l.d('onesignal: - State: ${subscriptionState.toString()}');
        l.d('onesignal: - JSON: ${subscriptionState.jsonRepresentation()}');

        // Handle offline state
        if (state.current.toString().contains('offline')) {
          l.d('onesignal: Device is offline, will retry later');
          return;
        }

        // Handle permission issues
        if (state.current.toString().contains('NO_PERMISSION')) {
          l.e('onesignal: No permission for notifications');
          // Check current permission state
          final currentPermission = await OneSignal.Notifications.permission;
          l.d('onesignal: Current permission state: $currentPermission');

          if (currentPermission == OSNotificationPermission.authorized) {
            l.d('onesignal: Permission is authorized, retrying subscription');
            // If we have permission but still get NO_PERMISSION, try to force a refresh
            await OneSignal.User.pushSubscription.optIn();
          } else {
            l.e('onesignal: Permission is not authorized, requesting again');
            final newPermission =
                await OneSignal.Notifications.requestPermission(true);
            if (!newPermission) {
              l.e('onesignal: Permission still denied after retry');
              return;
            }
            l.d('onesignal: Permission granted after retry');
          }
        }

        // Handle Firebase FCM initialization error
        if (state.current.toString().contains('FIREBASE_FCM_INIT_ERROR')) {
          l.e('onesignal: Firebase FCM initialization error');
          return;
        }
      });

      // Add observer for user state changes
      OneSignal.User.addObserver((state) {
        l.d('onesignal: User State Changed: ${state.jsonRepresentation()}');
      });

      // Add permission observer
      OneSignal.Notifications.addPermissionObserver((state) {
        l.d('onesignal: Notification Permission: $state');
        if (state == OSNotificationPermission.notDetermined) {
          l.d('onesignal: Permission not determined, requesting again');
          OneSignal.Notifications.requestPermission(true);
        }
      });

      // Add click listener for notifications
      OneSignal.Notifications.addClickListener((event) {
        l.d('onesignal: Notification Clicked: ${event.notification.jsonRepresentation()}');
      });

      // Add foreground notification listener
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        event.notification.display();
      });

      _isInitialized = true;
      l.d('onesignal: Setup completed successfully');
    } catch (e) {
      l.e('onesignal: Error initializing OneSignal: $e');
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

      _isInitialized = false;
      l.d('onesignal: Dismissed successfully');
    } catch (e) {
      l.e('onesignal: Error dismissing OneSignal: $e');
      rethrow;
    }
  }
}
