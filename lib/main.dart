import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:podium/app/modules/global/bindings/global_bindings.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/lib/jitsiMeet.dart';
import 'package:podium/env.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/root.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/theme.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'app/routes/app_pages.dart';
import 'package:app_links/app_links.dart';

StreamSubscription<Uri>? _linkSubscription;

late AppLinks _appLinks;

Future<void> initDeepLinks() async {
  _appLinks = AppLinks();

  // Handle links
  final initialLink = await _appLinks.getInitialLink();
  log.f('initial link: $initialLink');
  if (initialLink != null) {
    processLink(initialLink.toString());
  }
  _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
    log.f('deep link: $uri');
    processLink(uri.toString());
  });
}

processLink(String? link) async {
  if (link != null) {
    log.f('deep link: $link');
    late String deepLinkedPage;
    if (link.startsWith('podium://')) {
      deepLinkedPage = link.replaceAll('podium://', '/');
    } else if (link.startsWith(Env.baseDeepLinkUrl)) {
      deepLinkedPage = link.replaceAll(Env.baseDeepLinkUrl, "");
      deepLinkedPage = deepLinkedPage.replaceAll("?id=", "/");
      deepLinkedPage = deepLinkedPage.replaceAll('?referrerId=', '/');
    } else {
      deepLinkedPage = '';
    }
    if (deepLinkedPage.isEmpty) return;
    final isGlobalControllerInitialized = Get.isRegistered<GlobalController>();
    if (isGlobalControllerInitialized) {
      final globalController = Get.find<GlobalController>();
      globalController.setDeepLinkRoute(deepLinkedPage);
    } else {
      final globalController = Get.put(
        GlobalController(),
        permanent: true,
      );
      globalController.setDeepLinkRoute(deepLinkedPage);
    }
  }
}

void main() async {
  await GetStorage.init();
  HttpApis.configure();
  runApp(MyApp());
}

preCache(BuildContext context) {
  Assets.images.values.forEach((asset) {
    if (!asset.path.contains('.svg'))
      precacheImage(AssetImage(asset.path), context);
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _isDarkMode = true;
  ReownAppKitModalThemeData? _themeData;

  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    initDeepLinks();

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
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _handleDetached() async {
    jitsiMeet.hangUp();
    jitsiMethodChannel.invokeMethod<String>('hangUp');
    log.f('Detached');
  }

  void _pushState(String state) {
    log.i('States: $state');
  }

  void _handleStateChange(AppLifecycleState state) {
    final isGlobalControllerReady = Get.isRegistered<GlobalController>();
    if (isGlobalControllerReady) {
      final globalController = Get.find<GlobalController>();
      globalController.appLifecycleState.value = state;
    }
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
    preCache(context);
    return ReownAppKitModalTheme(
      isDarkMode: _isDarkMode,
      themeData: _themeData,
      child: GetMaterialApp(
        theme: darkThemeData,
        defaultTransition: Transition.native,
        // showPerformanceOverlay: true,
        onDispose: () {
          jitsiMeet.hangUp();
        },
        builder: (_, child) {
          return SafeArea(
            child: Root(
              child: child!,
            ),
          );
        },
        binds: globalBindings,
        debugShowCheckedModeBanner: false,
        initialRoute: AppPages.INITIAL,
        getPages: AppPages.routes,
      ),
    );
  }

// ignore: unused_element
  void _toggleTheme() => setState(() {
        _themeData = (_themeData == null) ? _customTheme : null;
      });
// ignore: unused_element
  void _toggleBrightness() => setState(() {
        _isDarkMode = !_isDarkMode;
      });

  ReownAppKitModalThemeData get _customTheme => ReownAppKitModalThemeData(
        lightColors: ReownAppKitModalColors.lightMode.copyWith(
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
        darkColors: ReownAppKitModalColors.darkMode.copyWith(
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
        radiuses: ReownAppKitModalRadiuses.square,
      );
}
