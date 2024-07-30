import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get_storage/get_storage.dart';
import 'package:podium/app/modules/global/bindings/global_bindings.dart';
import 'package:podium/app/modules/global/lib/jitsiMeet.dart';
import 'package:podium/root.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/theme.dart';
import 'package:web3modal_flutter/web3modal_flutter.dart';
import 'app/routes/app_pages.dart';

void main() async {
  await GetStorage.init();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _isDarkMode = true;
  Web3ModalThemeData? _themeData;

  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    log.i(SchedulerBinding.instance.lifecycleState);

    _listener = AppLifecycleListener(
      onShow: () => _pushState('show'),
      onResume: () => _pushState('resume'),
      onHide: () => _pushState('hide'),
      onInactive: () => _pushState('inactive'),
      onPause: () => _pushState('pause'),
      onDetach: () => _handleDetached(),
      onRestart: () => _pushState('restart'),
      onStateChange: _handleStateChange,
      onExitRequested: _handleExitRequest,
    );
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        final platformDispatcher = View.of(context).platformDispatcher;
        final platformBrightness = platformDispatcher.platformBrightness;
        _isDarkMode = platformBrightness == Brightness.dark;
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _listener.dispose();
    super.dispose();
  }

  void _handleDetached() async {
    // jitsiMeet.hangUp();
    jitsiMethodChannel.invokeMethod<String>('hangUp');
    log.f('Detached');
  }

  void _pushState(String state) {
    log.i('States: $state');
  }

  void _handleStateChange(AppLifecycleState state) {
    log.i('State changed: $state');
  }

  Future<AppExitResponse> _handleExitRequest() async {
    /// Exit can proceed.
    return AppExitResponse.exit;

    /// Cancel the exit.
    // return AppExitResponse.cancel;
  }

  @override
  void didChangePlatformBrightness() {
    if (mounted) {
      setState(() {
        final platformDispatcher = View.of(context).platformDispatcher;
        final platformBrightness = platformDispatcher.platformBrightness;
        _isDarkMode = platformBrightness == Brightness.dark;
      });
    }
    super.didChangePlatformBrightness();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Web3ModalTheme(
      isDarkMode: _isDarkMode,
      themeData: _themeData,
      child: GetMaterialApp(
        theme: darkThemeData,
        builder: (_, child) {
          return SafeArea(
            child: Root(
              child: child!,
            ),
          );
        },
        initialBinding: GlobalBindings(),
        debugShowCheckedModeBanner: false,
        initialRoute: AppPages.INITIAL,
        getPages: AppPages.routes,
      ),
    );
  }

  void _toggleTheme() => setState(() {
        _themeData = (_themeData == null) ? _customTheme : null;
      });

  void _toggleBrightness() => setState(() {
        _isDarkMode = !_isDarkMode;
      });

  Web3ModalThemeData get _customTheme => Web3ModalThemeData(
        lightColors: Web3ModalColors.lightMode.copyWith(
          accent100: const Color.fromARGB(255, 30, 59, 236),
          background100: const Color.fromARGB(255, 161, 183, 231),
          // Main Modal's background color
          background125: const Color.fromARGB(255, 206, 221, 255),
          background175: const Color.fromARGB(255, 237, 241, 255),
          inverse100: const Color.fromARGB(255, 233, 237, 236),
          inverse000: const Color.fromARGB(255, 22, 18, 19),
          // Main Modal's text
          foreground100: const Color.fromARGB(255, 22, 18, 19),
          // Secondary Modal's text
          foreground150: const Color.fromARGB(255, 22, 18, 19),
        ),
        darkColors: Web3ModalColors.darkMode.copyWith(
          accent100: const Color.fromARGB(255, 161, 183, 231),
          background100: const Color.fromARGB(255, 30, 59, 236),
          // Main Modal's background color
          background125: const Color.fromARGB(255, 12, 23, 99),
          background175: const Color.fromARGB(255, 78, 103, 230),
          inverse100: const Color.fromARGB(255, 22, 18, 19),
          inverse000: const Color.fromARGB(255, 233, 237, 236),
          // Main Modal's text
          foreground100: const Color.fromARGB(255, 233, 237, 236),
          // Secondary Modal's text
          foreground150: const Color.fromARGB(255, 233, 237, 236),
        ),
        radiuses: Web3ModalRadiuses.square,
      );
}
