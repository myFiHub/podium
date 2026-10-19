import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/lib/jitsiMeet.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/ongoing_outpost_call_controller.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/navigation/call_route_tracker.dart';
import 'package:podium/utils/storage.dart';
import 'package:podium/widgets/ui/app_ui.dart';

/// Drives the Android bubble that floats over other apps while a call runs
/// with Podium in the background. Does nothing on other platforms.
class CallOverlayService extends GetxService {
  static const _channel = MethodChannel('podium/call_overlay');

  final _storage = GetStorage();
  final _workers = <Worker>[];
  final _callWorkers = <Worker>[];
  bool _shown = false;
  bool _showing = false;

  GlobalController get _global => Get.find<GlobalController>();
  OutpostCallController get _call => Get.find<OutpostCallController>();
  OngoingOutpostCallController? get _ongoing =>
      Get.isRegistered<OngoingOutpostCallController>()
          ? Get.find<OngoingOutpostCallController>()
          : null;

  @override
  void onInit() {
    super.onInit();
    if (!Platform.isAndroid) return;
    _channel.setMethodCallHandler(_onNativeAction);
    _workers
      ..add(ever<AppLifecycleState>(_global.appLifecycleState, _onLifecycle))
      ..add(ever<bool>(_call.isInCall, (inCall) {
        if (!inCall) _hide();
      }))
      ..add(ever<bool>(
        CallRouteTracker.instance.isCallPageVisible,
        (visible) {
          if (!visible) _offerPermissionOnce();
        },
      ));
  }

  @override
  void onClose() {
    for (final w in [..._workers, ..._callWorkers]) {
      w.dispose();
    }
    super.onClose();
  }

  void _onLifecycle(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _hide();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _show();
    }
  }

  Future<void> _show() async {
    final ongoing = _ongoing;
    final outpost = _call.outpost.value;
    if (_shown ||
        _showing ||
        !_call.isInCall.value ||
        ongoing == null ||
        outpost == null) {
      return;
    }
    _showing = true;
    try {
      final shown = await _channel.invokeMethod<bool>('show', {
        'title': outpost.name,
        'muted': ongoing.amIMuted.value,
        'canTalk': _call.canTalk.value,
      });
      if (shown != true) return;
      _shown = true;
      // The call may have ended, or the app come back, while showing.
      if (!_call.isInCall.value ||
          _global.appLifecycleState.value == AppLifecycleState.resumed) {
        _hide();
        return;
      }
      _callWorkers
        ..add(ever<bool>(ongoing.amIMuted, (_) => _update()))
        ..add(ever<bool>(_call.canTalk, (_) => _update()));
    } catch (e) {
      l.e('call overlay show failed: $e');
    } finally {
      _showing = false;
    }
  }

  void _update() {
    final ongoing = _ongoing;
    if (!_shown || ongoing == null) return;
    _channel.invokeMethod('update', {
      'muted': ongoing.amIMuted.value,
      'canTalk': _call.canTalk.value,
    });
  }

  void _hide() {
    for (final w in _callWorkers) {
      w.dispose();
    }
    _callWorkers.clear();
    if (!_shown) return;
    _shown = false;
    _channel.invokeMethod('hide').catchError((e) {
      l.e('call overlay hide failed: $e');
    });
  }

  Future<dynamic> _onNativeAction(MethodCall call) async {
    switch (call.method) {
      case 'toggleMute':
        _ongoing?.toggleMyMic();
        break;
      case 'leave':
        _shown = false;
        _hide();
        _call.leaveCall();
        break;
      case 'open':
        if (_call.isInCall.value) openCallPage();
        break;
    }
  }

  /// Asked the first time a call is minimized, while the user is still in the
  /// app and can see why the system settings page opens.
  Future<void> _offerPermissionOnce() async {
    // Leaving also closes the call page; let that settle before deciding.
    await Future.delayed(const Duration(milliseconds: 700));
    if (!_call.isInCall.value) return;
    if (CallRouteTracker.instance.isCallPageVisible.value) return;
    if (_global.appLifecycleState.value != AppLifecycleState.resumed) return;
    if (_storage.read(StorageKeys.askedCallOverlayPermission) == true) return;
    final granted =
        await _channel.invokeMethod<bool>('hasPermission').catchError((_) {
      return false;
    });
    if (granted == true) return;
    _storage.write(StorageKeys.askedCallOverlayPermission, true);
    final allow = await showAppConfirm(
      title: 'Keep controls on screen?',
      message: 'Allow Podium to display over other apps to mute or leave '
          'the outpost without coming back to Podium.',
      confirmLabel: 'Allow',
      cancelLabel: 'Not now',
    );
    if (allow) {
      unawaited(_channel.invokeMethod('requestPermission'));
    }
  }
}
