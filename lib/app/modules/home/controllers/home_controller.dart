import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/allOutposts/controllers/discover_controller.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/controllers/users_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/data/repositories/repositories.dart';
import 'package:podium/providers/api/podium/models/discovery/discovery_models.dart';
import 'package:podium/providers/api/podium/models/home/home_feed.dart';
import 'package:podium/services/server_features.dart';

/// Results outlive the controller so a rebuilt tabs page (e.g. after logging
/// in again) doesn't refetch everything.
class _HomeCache {
  String? userId;
  HomeFeed? feed;
  DateTime? feedAt;
  List<DiscoveredOutpost> live = const [];
  DateTime? liveAt;
  bool feedSupported = true;
}

final _cache = _HomeCache();

class HomeController extends GetxController {
  static const _feedTtl = Duration(minutes: 2);
  static const _liveTtl = Duration(seconds: 45);
  static const _livePollInterval = Duration(seconds: 60);
  static const _liveRailSize = 12;

  final OutpostsController outpostsController = Get.find<OutpostsController>();
  final _repo = Get.find<OutpostRepository>();
  final _global = Get.find<GlobalController>();
  final _features = Get.find<ServerFeatures>();

  final feed = Rxn<HomeFeed>(_cache.feed);
  final liveFromFollowings = Rx<List<DiscoveredOutpost>>(_cache.live);
  final isLoadingFeed = false.obs;

  /// False once the server answers 404, so the page falls back to outposts.
  final feedSupported = _cache.feedSupported.obs;

  /// Suggested people followed from the home page, by uuid.
  final followed = <String>{}.obs;
  final followInProgress = <String>{}.obs;

  Timer? _pollTimer;
  final _workers = <Worker>[];
  bool _feedInFlight = false;
  bool _liveInFlight = false;

  bool get _onHome => _global.activeRoute.value == Routes.HOME;
  bool get _resumed =>
      _global.appLifecycleState.value == AppLifecycleState.resumed;
  String? get _userId => _global.myUserInfo.value?.uuid;

  @override
  void onInit() {
    super.onInit();
    if (_cache.userId != null && _cache.userId != _userId) _clearCache();
    _workers.addAll([
      ever(_global.activeRoute, (_) => _onVisibilityChanged()),
      ever(_global.appLifecycleState, (_) => _onVisibilityChanged()),
      ever(_global.myUserInfo, (user) {
        if (user?.uuid == _cache.userId) return;
        _clearCache();
        refreshFeed();
      }),
      ever<bool>(_features.discovery, (supported) {
        if (supported) _loadLive(force: true);
      }),
    ]);
    _loadFeed();
    _onVisibilityChanged();
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    for (final worker in _workers) {
      worker.dispose();
    }
    super.onClose();
  }

  void _clearCache() {
    _cache
      ..userId = _userId
      ..feed = null
      ..feedAt = null
      ..live = const []
      ..liveAt = null;
    feed.value = null;
    liveFromFollowings.value = const [];
    followed.clear();
  }

  /// Refreshes stale sections when Home comes back into view, and polls the
  /// live rail only while it's on screen.
  void _onVisibilityChanged() {
    if (!_onHome || !_resumed) {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }
    _loadFeed();
    if (_pollTimer != null) return;
    _loadLive();
    _pollTimer = Timer.periodic(_livePollInterval, (_) => _loadLive());
  }

  bool _fresh(DateTime? at, Duration ttl) =>
      at != null && DateTime.now().difference(at) < ttl;

  /// The refresh button and pull-to-refresh.
  Future<void> refreshOutposts() async {
    await Future.wait([
      outpostsController.fetchMyOutpostsPage(0),
      refreshFeed(),
    ]);
  }

  Future<void> refreshFeed() async {
    if (!_features.discovery.value) await _features.probe();
    await Future.wait([_loadFeed(force: true), _loadLive(force: true)]);
  }

  Future<void> _loadFeed({bool force = false}) async {
    if (_userId == null || _feedInFlight) return;
    if (!force && _fresh(_cache.feedAt, _feedTtl)) return;
    if (!force && !feedSupported.value) return;
    _feedInFlight = true;
    isLoadingFeed.value = feed.value == null;
    _prefetchExplore();
    try {
      final result = await _repo.getHomeFeed(
        utcOffsetMinutes: DateTime.now().timeZoneOffset.inMinutes,
      );
      _cache
        ..userId = _userId
        ..feed = result
        ..feedAt = DateTime.now()
        ..feedSupported = true;
      if (isClosed) return;
      feedSupported.value = true;
      feed.value = result;
      followed.removeWhere(
        (uuid) => !result.suggestedPeople.any((p) => p.uuid == uuid),
      );
    } on ApiFailure catch (e) {
      // Keep whatever we already show; only a 404 means "not supported".
      if (e.statusCode == 404) {
        _cache.feedSupported = false;
        if (!isClosed) feedSupported.value = false;
      }
    } finally {
      _feedInFlight = false;
      if (!isClosed) isLoadingFeed.value = false;
    }
  }

  /// Warms the Explore tab alongside the feed so opening it rarely shows
  /// placeholders. Creating [DiscoverController] starts its loads, and its
  /// cache TTLs keep repeat calls cheap.
  void _prefetchExplore() {
    if (Get.isRegistered<DiscoverController>()) Get.find<DiscoverController>();
    if (outpostsController.outposts.value.isEmpty &&
        !outpostsController.isGettingAllOutposts.value) {
      outpostsController.fetchAllOutpostsPage(0);
    }
  }

  Future<void> _loadLive({bool force = false}) async {
    if (_userId == null ||
        !_features.discovery.value ||
        _liveInFlight ||
        (!force && _fresh(_cache.liveAt, _liveTtl))) {
      return;
    }
    _liveInFlight = true;
    try {
      final items = await _repo.getLiveFromFollowings(limit: _liveRailSize);
      _cache
        ..live = items
        ..liveAt = DateTime.now();
      if (!isClosed) liveFromFollowings.value = items;
    } finally {
      _liveInFlight = false;
    }
  }

  Future<void> toggleFollow(SuggestedUser user) async {
    final uuid = user.uuid;
    if (followInProgress.contains(uuid)) return;
    final follow = !followed.contains(uuid);
    followInProgress.add(uuid);
    // Optimistic, so the button reacts at once.
    follow ? followed.add(uuid) : followed.remove(uuid);
    try {
      final ok = await Get.find<UsersController>().followUnfollow(uuid, follow);
      if (!ok) follow ? followed.remove(uuid) : followed.add(uuid);
    } finally {
      followInProgress.remove(uuid);
    }
  }

  void openProfile(String uuid) =>
      Get.find<UsersController>().openUserProfile(uuid);
}
