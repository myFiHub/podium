import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:podium/env.dart';
import 'package:podium/utils/logger.dart';

/// Tracks whether the backend is reachable. Probing pauses while the app is in
/// the background (no network pings every few seconds) and resumes with it.
class ConnectivityService {
  ConnectivityService({required this.onConnected, required this.onResumed});

  /// Runs on every transition to connected.
  final Future<void> Function() onConnected;

  /// Runs whenever the app comes back to the foreground.
  final void Function() onResumed;

  final isConnected = true.obs;

  static final _checkOptions = [
    InternetCheckOption(uri: Uri.parse(Env.jitsiServerUrl)),
  ];

  final _checker = InternetConnection.createInstance(
    checkInterval: const Duration(seconds: 5),
    customCheckOptions: _checkOptions,
    useDefaultOptions: false,
  );

  StreamSubscription<InternetStatus>? _subscription;
  InternetStatus? _lastStatus;
  Worker? _lifecycleWorker;

  Future<bool> hasInternetAccess() async {
    final reachable = await _checker.hasInternetAccess;
    if (!reachable) {
      l.e("one of the main apis can't be reached: "
          "${_checkOptions.map((e) => e.uri)}");
    }
    return reachable;
  }

  void start(Rx<AppLifecycleState> lifecycle) {
    _listen();
    _lifecycleWorker ??= ever<AppLifecycleState>(lifecycle, (state) {
      if (state == AppLifecycleState.resumed) {
        _listen();
        onResumed();
      } else if (state == AppLifecycleState.hidden ||
          state == AppLifecycleState.paused) {
        _subscription?.cancel();
        _subscription = null;
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
    _lifecycleWorker?.dispose();
  }

  void _listen() {
    if (_subscription != null) return;
    _subscription = _checker.onStatusChange.listen((status) async {
      // The checker re-emits the current status on every new subscription.
      if (status == _lastStatus) return;
      _lastStatus = status;
      switch (status) {
        case InternetStatus.connected:
          isConnected.value = true;
          l.i("Internet connected");
          try {
            await onConnected();
          } catch (e) {
            l.e(e);
          }
        case InternetStatus.disconnected:
          l.f("Internet disconnected");
          isConnected.value = false;
      }
    });
  }
}
