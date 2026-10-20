import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/widgets/img.dart';
import 'package:podium/app/modules/hostAnalytics/views/host_outpost_analytics_view.dart';
import 'package:podium/app/modules/hostAnalytics/widgets/analytics_widgets.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/data/repositories/repositories.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/providers/api/podium/models/analytics/host_analytics.dart';
import 'package:podium/root.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/ui/app_ui.dart';

/// Audience, retention, earnings and timing across every outpost the user hosts.
class HostDashboardView extends StatefulWidget {
  const HostDashboardView({super.key});

  @override
  State<HostDashboardView> createState() => _HostDashboardViewState();
}

class _HostDashboardViewState extends State<HostDashboardView> {
  final _repo = Get.find<OutpostRepository>();

  AnalyticsWindow _window = AnalyticsWindow.month;
  final _byWindow = <AnalyticsWindow, HostAnalyticsSummary>{};
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
      final summary = await _repo.getHostAnalyticsSummary(
        window: window,
        utcOffsetMinutes: localUtcOffsetMinutes(),
      );
      _byWindow[window] = summary;
      if (mounted && request == _request) setState(() => _loading = false);
    } on ApiFailure catch (e) {
      if (mounted && request == _request) {
        setState(() {
          _loading = false;
          _error = e.message;
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
    final summary = _byWindow[_window];
    return Scaffold(
      body: PageWrapper(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppPageHeader(
                title: 'Host dashboard',
                subtitle: 'How your outposts are doing',
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
              Expanded(child: AnalyticsBodySwitcher(child: _body(summary))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(HostAnalyticsSummary? summary) {
    if (summary == null) {
      if (_error != null) {
        return AppEmptyState(
          key: const ValueKey('error'),
          icon: Icons.insights_rounded,
          title: "Couldn't load your analytics",
          message: _error,
          onAction: () => _load(force: true),
        );
      }
      return const SingleChildScrollView(
        key: ValueKey('loading'),
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 4, 16, 32),
        child: AnalyticsSkeleton(showBestTime: true),
      );
    }
    if (summary.outpostsCount == 0) {
      return AppEmptyState(
        key: const ValueKey('empty'),
        icon: Icons.podcasts_rounded,
        title: 'Host your first outpost',
        message: 'Your audience, retention and earnings show up here once '
            'people join your sessions.',
        actionLabel: 'Start an outpost',
        onAction: () => Navigate.to(
          type: NavigationTypes.toNamed,
          route: Routes.CREATE_OUTPOST,
        ),
      );
    }
    return RefreshIndicator(
      key: const ValueKey('content'),
      onRefresh: () => _load(force: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          KpiGrid(
            totals: summary.totals,
            earnedChainId: summary.earnedChainId,
          ),
          AnalyticsSection(
            title: 'Daily listeners',
            subtitle: 'Listener visits per day',
            child: DailyActivityChart(points: summary.daily),
          ),
          AnalyticsSection(
            title: 'Retention',
            subtitle: 'Share of listener visits that lasted at least',
            child: RetentionBars(points: summary.retentionCurve),
          ),
          AnalyticsSection(
            title: 'Best time to go live',
            subtitle: _audienceSubtitle(summary.audienceSource),
            child: BestTimeToGoLive(
              cells: summary.audienceHeatmap,
              bestSlots: summary.bestSlots,
            ),
          ),
          AnalyticsSection(
            title: 'Earnings',
            subtitle: 'Cheers and boos received, after fees',
            child: EarningsByChain(items: summary.earningsByChain),
          ),
          AnalyticsSection(
            title: 'Your outposts',
            subtitle: 'Ranked by listeners in this period',
            child: _TopOutposts(
              items: summary.topOutposts,
              earnedChainId: summary.earnedChainId,
            ),
          ),
        ],
      ),
    );
  }
}

String _audienceSubtitle(AudienceSource source) => switch (source) {
      AudienceSource.followers =>
        'When your followers are listening, in your local time',
      AudienceSource.listeners =>
        'When your listeners usually join, in your local time',
      AudienceSource.none => 'In your local time',
    };

class _TopOutposts extends StatelessWidget {
  const _TopOutposts({required this.items, required this.earnedChainId});

  final List<HostOutpostStat> items;
  final String earnedChainId;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text('No sessions in this period', style: AppText.muted);
    }
    return Column(
      children: [
        for (final (i, item) in items.indexed) ...[
          if (i > 0) Divider(height: 1, thickness: 1, color: AppColors.border),
          _OutpostRow(item: item, earnedChainId: earnedChainId),
        ],
      ],
    );
  }
}

class _OutpostRow extends StatelessWidget {
  const _OutpostRow({required this.item, required this.earnedChainId});

  final HostOutpostStat item;
  final String earnedChainId;

  @override
  Widget build(BuildContext context) {
    final image = item.image ?? '';
    return InkWell(
      onTap: () => openHostOutpostAnalytics(uuid: item.uuid, name: item.name),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Img(
              src: Uri.tryParse(image)?.isAbsolute == true ? image : '',
              alt: item.name,
              ifEmpty: Assets.images.logo.path,
              size: 40,
              borderRadius:
                  const BorderRadius.all(Radius.circular(AppRadius.sm)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.cardTitle.copyWith(
                      fontSize: 14,
                      color: item.isArchived ? AppColors.textFaint : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.sessions} sessions · '
                    '${formatCount(item.uniqueListeners)} listeners · '
                    'peak ${item.peakListeners} · '
                    '${formatPercent(item.retention10MinRate)} stayed 10m',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                  formatEarned(item.earned, earnedChainId),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: item.earned > 0
                        ? AppColors.success
                        : ColorName.greyText,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textFaint,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
