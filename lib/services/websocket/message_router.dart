import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/lib/jitsiMeet.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/notifications/controllers/notifications_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/ongoing_outpost_call_controller.dart';
import 'package:podium/app/modules/outpostDetail/controllers/outpost_detail_controller.dart';
import 'package:podium/services/websocket/client.dart';
import 'package:podium/services/websocket/incomingMessage.dart';
import 'package:podium/utils/logger.dart';

/// Handles WebSocket message routing to appropriate controllers
class WebSocketMessageRouter {
  static void routeMessage(IncomingMessage message) {
    l.d('Routing message: ${message.name}');

    switch (message.name) {
      case IncomingMessageType.userJoined:
        _handleUserJoined(message);
        break;
      case IncomingMessageType.userLeft:
        _handleUserLeft(message);
        break;
      case IncomingMessageType.remainingTimeUpdated:
        _handleRemainingTimeUpdated(message);
        break;
      case IncomingMessageType.userStartedSpeaking:
        _handleUserSpeaking(message, true);
        break;
      case IncomingMessageType.userStoppedSpeaking:
        _handleUserSpeaking(message, false);
        break;
      case IncomingMessageType.userLiked:
      case IncomingMessageType.userDisliked:
      case IncomingMessageType.userBooed:
      case IncomingMessageType.userCheered:
        _handleUserReaction(message);
        break;
      case IncomingMessageType.timeIsUp:
        _handleTimeIsUp(message);
        break;
      case IncomingMessageType.invite:
      case IncomingMessageType.follow:
        _handleNotification(message);
        break;
      case IncomingMessageType.waitlistUpdated:
        _handleWaitlistUpdated(message);
        break;
      case IncomingMessageType.creatorJoined:
        _handleCreatorJoined(message);
        break;
      case IncomingMessageType.userStartedRecording:
        _handleUserRecording(message, true);
        break;
      case IncomingMessageType.userStoppedRecording:
        _handleUserRecording(message, false);
        break;
    }
  }

  static void _handleUserJoined(IncomingMessage message) {
    if (message.data.address == myUser.address) {
      final joinId = 'join-${myUser.address}';
      l.d("User joined joinId: $joinId");
      WebSocketService.instance.completeJoinRequest(joinId);
    }

    _withController<OutpostCallController>((controller) {
      joinOrLeftDebounce.debounce(() => controller.fetchLiveData());
    });
  }

  static void _handleUserLeft(IncomingMessage message) {
    _withController<OutpostCallController>((controller) {
      if (message.data.address != myUser.address) {
        controller.fetchLiveData();
      }
    });
  }

  static void _handleRemainingTimeUpdated(IncomingMessage message) {
    _withController<OngoingOutpostCallController>((controller) {
      controller.updateUserRemainingTime(
        address: message.data.address!,
        newTimeInSeconds: message.data.remaining_time!,
      );
    });
  }

  static void _handleUserSpeaking(IncomingMessage message, bool isTalking) {
    _withController<OngoingOutpostCallController>((controller) {
      controller.updateUserIsTalking(
        address: message.data.address!,
        isTalking: isTalking,
      );
    });
  }

  static void _handleUserReaction(IncomingMessage message) {
    if (!Get.isRegistered<OngoingOutpostCallController>() ||
        !Get.isRegistered<OutpostCallController>()) {
      l.w("Required controllers not registered, cannot process user reaction");
      return;
    }

    final ongoingController = Get.find<OngoingOutpostCallController>();
    final outpostController = Get.find<OutpostCallController>();

    outpostController.updateReactionsMapByWsEvent(message);
    ongoingController.handleIncomingReaction(message);
  }

  static void _handleTimeIsUp(IncomingMessage message) {
    _withController<OngoingOutpostCallController>((controller) {
      controller.handleTimeIsUp(message);
    });
  }

  static void _handleNotification(IncomingMessage message) {
    _withController<NotificationsController>((controller) {
      controller.getNotifications();
    });
  }

  static void _handleWaitlistUpdated(IncomingMessage message) {
    if (Get.isRegistered<OutpostDetailController>()) {
      final controller = Get.find<OutpostDetailController>();
      controller.onMembersUpdated(message);
    }
  }

  static void _handleCreatorJoined(IncomingMessage message) {
    if (Get.isRegistered<OutpostDetailController>()) {
      final controller = Get.find<OutpostDetailController>();
      controller.onCreatorJoined(message);
    }
  }

  static void _handleUserRecording(IncomingMessage message, bool isRecording) {
    _withController<OngoingOutpostCallController>((controller) {
      if (isRecording) {
        controller.onUserStartedRecording(message);
      } else {
        controller.onUserStoppedRecording(message);
      }
    });
  }

  static void _withController<T>(void Function(T controller) action) {
    if (!Get.isRegistered<T>()) {
      l.w("${T.toString()} not registered, cannot process message");
      return;
    }
    action(Get.find<T>());
  }
}
