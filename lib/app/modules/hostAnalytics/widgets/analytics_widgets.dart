import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:podium/app/modules/global/utils/getContract.dart';
import 'package:podium/app/modules/global/widgets/img.dart';
import 'package:podium/providers/api/podium/models/analytics/host_analytics.dart';
import 'package:podium/utils/format_amount.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/ui/app_ui.dart';
import 'package:shimmer/shimmer.dart';

const _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

/// The server's offset in minutes for the viewer's local time.
int localUtcOffsetMinutes() => DateTime.now().timeZoneOffset.inMinutes;

String formatMinutes(double minutes) {
  if (minutes < 1) return minutes <= 0 ? '0m' : '<1m';
  if (minutes < 60) return '${minutes.round()}m';
  final hours = minutes / 60;
  if (hours < 10) return '${hours.toStringAsFixed(1)}h';
  return '${NumberFormat.compact().format(hours.round())}h';
}

String formatCount(num value) => NumberFormat.compact().format(value);

String formatPercent(double share) => '${(share * 100).round()}%';

String formatHour(int hour) =>
    DateFormat.j().format(DateTime(2000, 1, 1, hour));

String formatSlot(HeatmapCell cell) =>
    '${_dayNames[cell.dow.clamp(0, 6)]} ${formatHour(cell.hour)}';

String formatEarned(double amount, String chainId) {
  final currency = chainId.isEmpty ? '' : chainInfoByChainId(chainId).currency;
  return formatAmount(amount, currency).trim();
}

class AnalyticsWindowPicker extends StatelessWidget {
  const AnalyticsWindowPicker({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final AnalyticsWindow selected;
  final ValueChanged<AnalyticsWindow> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final window in AnalyticsWindow.values) ...[
          GestureDetector(
            onTap: () => onSelect(window),
            child: AppPill(
              label: window.label,
              filled: window == selected,
              color: window == selected ? AppColors.primary : null,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class KpiTile extends StatelessWidget {
  const KpiTile({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.detail,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorName.white.withAlpha(8),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: ColorName.white,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// The headline numbers for a window, two per row.
class KpiGrid extends StatelessWidget {
  const KpiGrid({
    super.key,
    required this.totals,
    required this.earnedChainId,
  });

  final HostTotals totals;
  final String earnedChainId;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      KpiTile(
        icon: Icons.groups_rounded,
        color: AppColors.live,
        label: 'Peak listeners',
        value: formatCount(totals.peakListeners),
        detail: 'avg ${totals.avgPeakListeners.toStringAsFixed(1)} per session',
      ),
      KpiTile(
        icon: Icons.person_add_alt_1_rounded,
        color: AppColors.primary,
        label: 'Unique listeners',
        value: formatCount(totals.uniqueListeners),
        detail: '${formatCount(totals.returningListeners)} came back',
      ),
      KpiTile(
        icon: Icons.headphones_rounded,
        color: AppColors.violet,
        label: 'Listening time',
        value: formatMinutes(totals.listenMinutes),
        detail: '${formatMinutes(totals.avgListenMinutes)} per visit',
      ),
      KpiTile(
        icon: Icons.timer_outlined,
        color: AppColors.success,
        label: 'Stayed 10+ min',
        value: formatPercent(totals.retention10MinRate),
        detail: '${formatCount(totals.listenerVisits)} visits',
      ),
      KpiTile(
        icon: Icons.podcasts_rounded,
        color: AppColors.magenta,
        label: 'Sessions',
        value: formatCount(totals.sessions),
        detail: '${formatMinutes(totals.hostedMinutes)} hosted',
      ),
      KpiTile(
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.accent,
        label: 'Earned',
        value: formatEarned(totals.earned, earnedChainId),
        detail: '${formatCount(totals.cheers)} cheers · '
            '${formatCount(totals.boos)} boos',
      ),
    ];
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: tiles[i]),
              const SizedBox(width: 10),
              Expanded(child: tiles[i + 1]),
            ],
          ),
        ],
      ],
    );
  }
}

class AnalyticsSection extends StatelessWidget {
  const AnalyticsSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppText.cardTitle),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: AppText.caption),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Listener visits per day, with the busiest day labeled.
class DailyActivityChart extends StatelessWidget {
  const DailyActivityChart({super.key, required this.points});

  final List<DailyPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Text('No sessions in this period', style: AppText.muted);
    }
    final best = points.reduce(
      (a, b) => b.listenerVisits > a.listenerVisits ? b : a,
    );
    final first = points.first.date;
    final last = points.last.date;
    final dateFormat = DateFormat.MMMd();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepaintBoundary(
          child: SizedBox(
            height: 110,
            child: CustomPaint(
              painter: _BarsPainter(
                values: [for (final p in points) p.listenerVisits.toDouble()],
                color: AppColors.primary,
                track: AppColors.fill,
                highlight: points.indexOf(best),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(dateFormat.format(first), style: AppText.caption),
            const Spacer(),
            Text(dateFormat.format(last), style: AppText.caption),
          ],
        ),
        if (best.listenerVisits > 0) ...[
          const SizedBox(height: 8),
          Text(
            'Best day: ${DateFormat.MMMEd().format(best.date)} · '
            '${best.listenerVisits} listener visits, peak ${best.peakListeners}',
            style: AppText.caption.copyWith(color: ColorName.white),
          ),
        ],
      ],
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.values,
    required this.color,
    required this.track,
    required this.highlight,
  });

  final List<double> values;
  final Color color;
  final Color track;
  final int highlight;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxValue = values.reduce(math.max);
    final slot = size.width / values.length;
    final gap = math.min(4.0, slot * 0.3);
    final barWidth = math.max(1.0, slot - gap);
    final radius = Radius.circular(math.min(4, barWidth / 2));
    final trackPaint = Paint()..color = track;
    final barPaint = Paint()..color = color.withAlpha(150);
    final highlightPaint = Paint()..color = color;
    for (var i = 0; i < values.length; i++) {
      final left = i * slot + gap / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, 0, barWidth, size.height),
          radius,
        ),
        trackPaint,
      );
      if (maxValue <= 0 || values[i] <= 0) continue;
      final h = math.max(3.0, size.height * values[i] / maxValue);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, size.height - h, barWidth, h),
          radius,
        ),
        i == highlight ? highlightPaint : barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      !identical(old.values, values) ||
      old.color != color ||
      old.track != track ||
      old.highlight != highlight;
}

/// How many listeners were still there after each mark.
class RetentionBars extends StatelessWidget {
  const RetentionBars({super.key, required this.points});

  final List<RetentionPoint> points;

  @override
  Widget build(BuildContext context) {
    final shown = points.where((p) => p.minute > 0).toList();
    if (shown.isEmpty || points.every((p) => p.listeners == 0)) {
      return Text('No listeners yet', style: AppText.muted);
    }
    return Column(
      children: [
        for (final p in shown)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Text('${p.minute}+ min', style: AppText.caption),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: p.share.clamp(0, 1),
                      minHeight: 8,
                      backgroundColor: AppColors.fill,
                      color: AppColors.success,
                    ),
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    formatPercent(p.share),
                    textAlign: TextAlign.end,
                    style: AppText.caption.copyWith(
                      color: ColorName.white,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Top time slots plus a 7-day by 24-hour heatmap of when the audience listens.
class BestTimeToGoLive extends StatelessWidget {
  const BestTimeToGoLive({
    super.key,
    required this.cells,
    required this.bestSlots,
  });

  final List<HeatmapCell> cells;
  final List<HeatmapCell> bestSlots;

  @override
  Widget build(BuildContext context) {
    if (cells.isEmpty) {
      return Text(
        'Not enough listening data yet. Host a few sessions and check back.',
        style: AppText.muted,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (i, slot) in bestSlots.indexed)
              AppPill(
                icon: i == 0 ? Icons.star_rounded : Icons.schedule_rounded,
                label: '${formatSlot(slot)} · ${slot.users}',
                color: i == 0 ? AppColors.accent : AppColors.primary,
                filled: i == 0,
              ),
          ],
        ),
        const SizedBox(height: 14),
        _Heatmap(cells: cells),
      ],
    );
  }
}

class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.cells});

  final List<HeatmapCell> cells;

  static const _labelWidth = 30.0;
  static const _rowHeight = 16.0;
  static const _rowGap = 3.0;

  @override
  Widget build(BuildContext context) {
    final grid = List.generate(7, (_) => List<int>.filled(24, 0));
    for (final c in cells) {
      if (c.dow >= 0 && c.dow < 7 && c.hour >= 0 && c.hour < 24) {
        grid[c.dow][c.hour] += c.users;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 7 * _rowHeight + 6 * _rowGap,
          child: Row(
            children: [
              SizedBox(
                width: _labelWidth,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final d in _dayNames)
                      SizedBox(
                        height: _rowHeight,
                        child: Text(
                          d,
                          style: AppText.caption.copyWith(fontSize: 10),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: RepaintBoundary(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _HeatmapPainter(
                      grid: grid,
                      color: AppColors.accent,
                      empty: AppColors.fill,
                      rowGap: _rowGap,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: _labelWidth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final h in const [0, 6, 12, 18, 23])
                Text(
                  formatHour(h),
                  style: AppText.caption.copyWith(fontSize: 10),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter({
    required this.grid,
    required this.color,
    required this.empty,
    required this.rowGap,
  });

  final List<List<int>> grid;
  final Color color;
  final Color empty;
  final double rowGap;

  @override
  void paint(Canvas canvas, Size size) {
    var maxValue = 0;
    for (final row in grid) {
      for (final v in row) {
        if (v > maxValue) maxValue = v;
      }
    }
    const colGap = 2.0;
    final cellW = (size.width - colGap * 23) / 24;
    final cellH = (size.height - rowGap * 6) / 7;
    final radius = Radius.circular(math.min(3, cellW / 3));
    final emptyPaint = Paint()..color = empty;
    final paint = Paint();
    for (var d = 0; d < 7; d++) {
      for (var h = 0; h < 24; h++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            h * (cellW + colGap),
            d * (cellH + rowGap),
            cellW,
            cellH,
          ),
          radius,
        );
        final v = grid[d][h];
        if (v == 0 || maxValue == 0) {
          canvas.drawRRect(rect, emptyPaint);
          continue;
        }
        final t = v / maxValue;
        paint.color = color.withAlpha((50 + 205 * t).round());
        canvas.drawRRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_HeatmapPainter old) =>
      !identical(old.grid, grid) || old.color != color || old.empty != empty;
}

class EarningsByChain extends StatelessWidget {
  const EarningsByChain({super.key, required this.items});

  final List<ChainEarnings> items;

  @override
  Widget build(BuildContext context) {
    final nonZero = items.where((e) => e.totalAmount > 0).toList();
    if (nonZero.isEmpty) {
      return Text('Nothing yet', style: AppText.muted);
    }
    return Column(
      children: [
        for (final (i, e) in nonZero.indexed) ...[
          if (i > 0) Divider(height: 1, thickness: 1, color: AppColors.border),
          _EarningRow(item: e),
        ],
      ],
    );
  }
}

class _EarningRow extends StatelessWidget {
  const _EarningRow({required this.item});

  final ChainEarnings item;

  @override
  Widget build(BuildContext context) {
    final chain = chainInfoByChainId(item.chainId);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Img(
            src: chain.chainIcon ?? '',
            size: 22,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chain.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body,
                ),
                Text(
                  '${item.cheers} cheers · ${item.boos} boos',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatAmount(item.totalAmount, chain.currency),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder shown while a dashboard loads.
class AnalyticsSkeleton extends StatelessWidget {
  const AnalyticsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var row = 0; row < 3; row++) ...[
          if (row > 0) const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(child: _SkeletonTile()),
              SizedBox(width: 10),
              Expanded(child: _SkeletonTile()),
            ],
          ),
        ],
        const _SkeletonSection(child: _SkeletonBars()),
        const _SkeletonSection(child: _SkeletonRetention()),
      ],
    );
  }
}

class _SkeletonShimmer extends StatelessWidget {
  const _SkeletonShimmer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: ColorName.white.withAlpha(16),
      highlightColor: ColorName.white.withAlpha(40),
      child: child,
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({this.width, this.height = 10, this.radius = 6});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ColorName.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorName.white.withAlpha(8),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: const _SkeletonShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Bone(width: 16, height: 16, radius: 999),
                SizedBox(width: 6),
                _Bone(width: 72),
              ],
            ),
            SizedBox(height: 12),
            _Bone(width: 64, height: 20),
            SizedBox(height: 8),
            _Bone(width: 96, height: 9),
          ],
        ),
      ),
    );
  }
}

class _SkeletonSection extends StatelessWidget {
  const _SkeletonSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(top: 12),
      child: _SkeletonShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: _Bone(width: 120, height: 14),
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: _Bone(width: 180, height: 9),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _SkeletonBars extends StatelessWidget {
  const _SkeletonBars();

  static const _heights = [
    0.35, 0.55, 0.4, 0.7, 0.5, 0.85, 0.45, //
    0.6, 0.3, 0.75, 0.55, 0.95, 0.5, 0.65,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 110,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final h in _heights)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: FractionallySizedBox(
                      heightFactor: h,
                      child: const _Bone(height: double.infinity, radius: 4),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          children: [
            _Bone(width: 40, height: 9),
            Spacer(),
            _Bone(width: 40, height: 9),
          ],
        ),
      ],
    );
  }
}

class _SkeletonRetention extends StatelessWidget {
  const _SkeletonRetention();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 4; i++)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                _Bone(width: 44, height: 9),
                SizedBox(width: 12),
                Expanded(child: _Bone(height: 8, radius: 999)),
                SizedBox(width: 12),
                _Bone(width: 28, height: 9),
              ],
            ),
          ),
      ],
    );
  }
}
