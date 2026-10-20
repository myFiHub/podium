import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:podium/app/modules/hostAnalytics/widgets/analytics_widgets.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/data/repositories/repositories.dart';
import 'package:podium/providers/api/podium/models/analytics/host_analytics.dart';
import 'package:podium/root.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/ui/app_ui.dart';

abstract class HostOutpostAnalyticsParams {
  static const uuid = 'uuid';
  static const name = 'name';
}

void openHostOutpostAnalytics({required String uuid, required String name}) {
  Navigate.to(
    type: NavigationTypes.toNamed,
    route: Routes.HOST_OUTPOST_ANALYTICS,
    parameters: {
      HostOutpostAnalyticsParams.uuid: uuid,
      HostOutpostAnalyticsParams.name: name,
    },
  );
}

/// Per-session numbers for one outpost, for its creator and cohosts.
class HostOutpostAnalyticsView extends StatefulWidget {
  const HostOutpostAnalyticsView({super.key});

  @override
  State<HostOutpostAnalyticsView> createState() =>
      _HostOutpostAnalyticsViewState();
}

class _HostOutpostAnalyticsViewState extends State<HostOutpostAnalyticsView> {
  final _repo = Get.find<OutpostRepository>();
  late final String _uuid =
      Get.parameters[HostOutpostAnalyticsParams.uuid] ?? '';
  late final String _initialName =
      Get.parameters[HostOutpostAnalyticsParams.name] ?? '';

  AnalyticsWindow _window = AnalyticsWindow.month;
  final _byWindow = <AnalyticsWindow, HostOutpostAnalytics>{};
  bool _loading = false;
  String? _error;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    final window = _window;
    if (_uuid.isEmpty) {
      setState(() => _error = 'Outpost not found');
      return;
    }
    if (!force && _byWindow.containsKey(window)) {
      setState(() => _error = null);
      return;
    }
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repo.getHostOutpostAnalytics(
        outpostUuid: _uuid,
        window: window,
        utcOffsetMinutes: localUtcOffsetMinutes(),
      );
      _byWindow[window] = data;
      if (mounted && request == _request) setState(() => _loading = false);
    } on ApiFailure catch (e) {
      if (mounted && request == _request) {
        setState(() {
          _loading = false;
          _error = switch (e.statusCode) {
            403 => 'Only the host and cohosts can see these numbers.',
            404 => 'Outpost not found',
            _ => e.message,
          };
        });
      }
    }
  }

  void _selectWindow(AnalyticsWindow window) {
    if (window == _window) return;
    _window = window;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final data = _byWindow[_window];
    final name = data?.outpostName ?? _initialName;
    return Scaffold(
      body: PageWrapper(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppPageHeader(
                title: name.isEmpty ? 'Outpost analytics' : name,
                subtitle: 'Outpost analytics',
                showBack: true,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                actions: [
                  AppRefreshButton(
                    loading: _loading,
                    onTap: () => _load(force: true),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: AnalyticsWindowPicker(
                  selected: _window,
                  onSelect: _selectWindow,
                ),
              ),
              Expanded(child: AnalyticsBodySwitcher(child: _body(data))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(HostOutpostAnalytics? data) {
    if (data == null) {
      if (_error != null) {
        return AppEmptyState(
          key: const ValueKey('error'),
          icon: Icons.insights_rounded,
          title: "Couldn't load analytics",
          message: _error,
          onAction: () => _load(force: true),
        );
      }
      return const SingleChildScrollView(
        key: ValueKey('loading'),
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 4, 16, 32),
        child: AnalyticsSkeleton(),
      );
    }
    return RefreshIndicator(
      key: const ValueKey('content'),
      onRefresh: () => _load(force: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          KpiGrid(totals: data.totals, earnedChainId: data.earnedChainId),
          AnalyticsSection(
            title: 'Daily listeners',
            subtitle: 'Listener visits per day',
            child: DailyActivityChart(points: data.daily),
          ),
          AnalyticsSection(
            title: 'Retention',
            subtitle: 'Share of listener visits that lasted at least',
            child: RetentionBars(points: data.retentionCurve),
          ),
          AnalyticsSection(
            title: 'Earnings',
            subtitle: 'Cheers and boos received, after fees',
            child: EarningsByChain(items: data.earningsByChain),
          ),
          AnalyticsSection(
            title: 'Sessions',
            subtitle: data.sessions.isEmpty ? null : 'Newest first',
            child: _Sessions(
              items: data.sessions,
              earnedChainId: data.earnedChainId,
            ),
          ),
        ],
      ),
    );
  }
}

class _Sessions extends StatelessWidget {
  const _Sessions({required this.items, required this.earnedChainId});

  final List<HostSessionStat> items;
  final String earnedChainId;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        'No sessions with listeners in this period',
        style: AppText.muted,
      );
    }
    return Column(
      children: [
        for (final (i, s) in items.indexed) ...[
          if (i > 0) Divider(height: 1, thickness: 1, color: AppColors.border),
          _SessionRow(session: s, earnedChainId: earnedChainId),
        ],
      ],
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session, required this.earnedChainId});

  final HostSessionStat session;
  final String earnedChainId;

  @override
  Widget build(BuildContext context) {
    final started = DateFormat.MMMEd().add_jm().format(session.startedAt);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  started,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatMinutes(session.durationSeconds / 60)} · '
                  '${session.listeners} listeners · peak ${session.peakListeners} · '
                  '${formatPercent(session.retention10MinRate)} stayed 10m',
                  maxLines: 2,
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatEarned(session.earned, earnedChainId),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: session.earned > 0
                      ? AppColors.success
                      : ColorName.greyText,
                ),
              ),
              Text(
                '${session.cheers} cheers · ${session.boos} boos',
                style: AppText.caption.copyWith(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
