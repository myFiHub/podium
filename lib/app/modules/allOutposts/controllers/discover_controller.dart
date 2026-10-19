import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/data/repositories/repositories.dart';
import 'package:podium/providers/api/podium/models/discovery/discovery_models.dart';
import 'package:podium/services/server_features.dart';

/// The Explore route is rebuilt on every navbar visit, so results outlive the
/// controller to avoid refetching on each tab switch.
class _DiscoverCache {
  List<DiscoveredOutpost> following = const [];
  List<DiscoveredOutpost> live = const [];
  final trending = <TrendingWindow, List<DiscoveredOutpost>>{};
  final trendingAt = <TrendingWindow, DateTime>{};
  List<PopularTagModel> tags = const [];
  DateTime? liveAt;
  DateTime? tagsAt;
}

final _cache = _DiscoverCache();

/// Live, following, trending and tag rails above the Explore list.
class DiscoverController extends GetxController {
  static const _railSize = 12;
  static const _tagsCount = 16;
  static const _liveTtl = Duration(seconds: 45);
  static const _trendingTtl = Duration(minutes: 2);
  static const _tagsTtl = Duration(minutes: 10);
  static const _livePollInterval = Duration(seconds: 60);

  final _repo = Get.find<OutpostRepository>();
  final _global = Get.find<GlobalController>();
  final _features = Get.find<ServerFeatures>();

  final liveFromFollowings = Rx<List<DiscoveredOutpost>>(_cache.following);
  final liveNow = Rx<List<DiscoveredOutpost>>(_cache.live);
  final trending = Rx<List<DiscoveredOutpost>>(const []);
  final trendingWindow = TrendingWindow.week.obs;
  final popularTags = Rx<List<PopularTagModel>>(_cache.tags);
  final isLoadingTrending = false.obs;

  /// True until the first load finishes, so rails can show placeholders.
  final isFirstLoad = true.obs;

  Timer? _pollTimer;
  Worker? _lifecycleWorker;
  Worker? _loginWorker;
  Worker? _featureWorker;
  bool _liveInFlight = false;
  int _trendingRequest = 0;

  bool get _loggedIn => _global.myUserInfo.value != null;
  bool get _supported => _features.discovery.value;

  @override
  void onInit() {
    super.onInit();
    trending.value = _cache.trending[trendingWindow.value] ?? const [];
    isFirstLoad.value = _cache.liveAt == null;
    _lifecycleWorker = ever<AppLifecycleState>(
      _global.appLifecycleState,
      (state) {
        if (state == AppLifecycleState.resumed) {
          _startPolling();
          _loadLive();
        } else {
          _pollTimer?.cancel();
        }
      },
    );
    _loginWorker = ever(_global.myUserInfo, (_) => _loadLive(force: true));
    _featureWorker = ever<bool>(_features.discovery, (supported) {
      if (supported) _loadAll(force: true);
    });
    _loadAll();
    _startPolling();
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    _lifecycleWorker?.dispose();
    _loginWorker?.dispose();
    _featureWorker?.dispose();
    super.onClose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_livePollInterval, (_) => _loadLive());
  }

  Future<void> _loadAll({bool force = false}) async {
    if (!_supported) {
      isFirstLoad.value = false;
      return;
    }
    await Future.wait([
      _loadLive(force: force),
      _loadTrending(force: force),
      _loadTags(force: force),
    ]);
    isFirstLoad.value = false;
  }

  /// Pull-to-refresh and the page refresh button.
  Future<void> refreshAll() async {
    if (!_supported) await _features.probe();
    await _loadAll(force: true);
  }

  bool _fresh(DateTime? at, Duration ttl) =>
      at != null && DateTime.now().difference(at) < ttl;

  Future<void> _loadLive({bool force = false}) async {
    if (!_supported ||
        _liveInFlight ||
        (!force && _fresh(_cache.liveAt, _liveTtl))) {
      return;
    }
    _liveInFlight = true;
    try {
      final results = await Future.wait([
        _loggedIn
            ? _repo.getLiveFromFollowings(limit: _railSize)
            : Future.value(const <DiscoveredOutpost>[]),
        _repo.getLiveOutposts(limit: _railSize * 2),
      ]);
      final following = results[0];
      final shown = {for (final o in following) o.outpost.uuid};
      final live = results[1]
          .where((o) => !shown.contains(o.outpost.uuid))
          .take(_railSize)
          .toList();
      _cache
        ..following = following
        ..live = live
        ..liveAt = DateTime.now();
      if (isClosed) return;
      liveFromFollowings.value = following;
      liveNow.value = live;
    } finally {
      _liveInFlight = false;
    }
  }

  Future<void> _loadTrending({bool force = false}) async {
    final window = trendingWindow.value;
    if (!force && _fresh(_cache.trendingAt[window], _trendingTtl)) {
      trending.value = _cache.trending[window]!;
      return;
    }
    final request = ++_trendingRequest;
    isLoadingTrending.value = true;
    try {
      final items =
          await _repo.getTrendingOutposts(window: window, limit: _railSize);
      _cache.trending[window] = items;
      _cache.trendingAt[window] = DateTime.now();
      if (isClosed || request != _trendingRequest) return;
      trending.value = items;
    } finally {
      if (!isClosed && request == _trendingRequest) {
        isLoadingTrending.value = false;
      }
    }
  }

  Future<void> _loadTags({bool force = false}) async {
    if (!force && _fresh(_cache.tagsAt, _tagsTtl)) return;
    final tags = await _repo.getPopularTags(limit: _tagsCount);
    // An empty reply after an error shouldn't wipe tags we already have.
    if (tags.isEmpty && _cache.tags.isNotEmpty) return;
    _cache
      ..tags = tags
      ..tagsAt = DateTime.now();
    if (isClosed) return;
    popularTags.value = tags;
  }

  void selectTrendingWindow(TrendingWindow window) {
    if (trendingWindow.value == window) return;
    trendingWindow.value = window;
    trending.value = _cache.trending[window] ?? const [];
    _loadTrending();
  }
}
