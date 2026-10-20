int _int(Object? v) => (v as num?)?.toInt() ?? 0;
double _double(Object? v) => (v as num?)?.toDouble() ?? 0;

List<T> _list<T>(Object? v, T Function(Map<String, dynamic>) fromJson) =>
    (v as List? ?? [])
        .map((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();

enum AnalyticsWindow {
  week('7d', '7 days'),
  month('30d', '30 days'),
  quarter('90d', '90 days');

  const AnalyticsWindow(this.value, this.label);

  final String value;
  final String label;
}

class HostTotals {
  final int sessions;
  final double hostedMinutes;
  final int uniqueListeners;
  final int returningListeners;

  /// One per listener per session.
  final int listenerVisits;
  final double listenMinutes;
  final double avgListenMinutes;
  final int peakListeners;
  final double avgPeakListeners;

  /// Share of listener visits that lasted 10+ minutes, 0 to 1.
  final double retention10MinRate;
  final int cheers;
  final int boos;

  /// Net amount received on the summary's earned chain.
  final double earned;

  const HostTotals({
    required this.sessions,
    required this.hostedMinutes,
    required this.uniqueListeners,
    required this.returningListeners,
    required this.listenerVisits,
    required this.listenMinutes,
    required this.avgListenMinutes,
    required this.peakListeners,
    required this.avgPeakListeners,
    required this.retention10MinRate,
    required this.cheers,
    required this.boos,
    required this.earned,
  });

  factory HostTotals.fromJson(Map<String, dynamic> json) => HostTotals(
        sessions: _int(json['sessions']),
        hostedMinutes: _double(json['hosted_minutes']),
        uniqueListeners: _int(json['unique_listeners']),
        returningListeners: _int(json['returning_listeners']),
        listenerVisits: _int(json['listener_visits']),
        listenMinutes: _double(json['listen_minutes']),
        avgListenMinutes: _double(json['avg_listen_minutes']),
        peakListeners: _int(json['peak_listeners']),
        avgPeakListeners: _double(json['avg_peak_listeners']),
        retention10MinRate: _double(json['retention_10min_rate']),
        cheers: _int(json['cheers']),
        boos: _int(json['boos']),
        earned: _double(json['earned']),
      );
}

class DailyPoint {
  final DateTime date;
  final int sessions;
  final int listenerVisits;
  final double listenMinutes;
  final int peakListeners;

  const DailyPoint({
    required this.date,
    required this.sessions,
    required this.listenerVisits,
    required this.listenMinutes,
    required this.peakListeners,
  });

  factory DailyPoint.fromJson(Map<String, dynamic> json) => DailyPoint(
        date: DateTime.tryParse(json['date'] as String? ?? '') ??
            DateTime.now(),
        sessions: _int(json['sessions']),
        listenerVisits: _int(json['listener_visits']),
        listenMinutes: _double(json['listen_minutes']),
        peakListeners: _int(json['peak_listeners']),
      );
}

class RetentionPoint {
  final int minute;
  final int listeners;

  /// 0 to 1.
  final double share;

  const RetentionPoint({
    required this.minute,
    required this.listeners,
    required this.share,
  });

  factory RetentionPoint.fromJson(Map<String, dynamic> json) => RetentionPoint(
        minute: _int(json['minute']),
        listeners: _int(json['listeners']),
        share: _double(json['share']),
      );
}

class ChainEarnings {
  final String chainId;
  final int cheers;
  final int boos;
  final double cheersAmount;
  final double boosAmount;
  final double totalAmount;

  const ChainEarnings({
    required this.chainId,
    required this.cheers,
    required this.boos,
    required this.cheersAmount,
    required this.boosAmount,
    required this.totalAmount,
  });

  factory ChainEarnings.fromJson(Map<String, dynamic> json) => ChainEarnings(
        chainId: json['chain_id']?.toString() ?? '',
        cheers: _int(json['cheers']),
        boos: _int(json['boos']),
        cheersAmount: _double(json['cheers_amount']),
        boosAmount: _double(json['boos_amount']),
        totalAmount: _double(json['total_amount']),
      );
}

class HeatmapCell {
  /// 0 = Sunday, in the viewer's local time.
  final int dow;
  final int hour;
  final int users;

  const HeatmapCell({
    required this.dow,
    required this.hour,
    required this.users,
  });

  factory HeatmapCell.fromJson(Map<String, dynamic> json) => HeatmapCell(
        dow: _int(json['dow']),
        hour: _int(json['hour']),
        users: _int(json['users']),
      );
}

enum AudienceSource { followers, listeners, none }

class HostOutpostStat {
  final String uuid;
  final String name;
  final String? image;
  final bool isArchived;
  final int sessions;
  final int uniqueListeners;
  final int peakListeners;
  final double listenMinutes;
  final double avgListenMinutes;
  final double retention10MinRate;
  final double earned;
  final DateTime? lastSessionAt;

  const HostOutpostStat({
    required this.uuid,
    required this.name,
    required this.image,
    required this.isArchived,
    required this.sessions,
    required this.uniqueListeners,
    required this.peakListeners,
    required this.listenMinutes,
    required this.avgListenMinutes,
    required this.retention10MinRate,
    required this.earned,
    required this.lastSessionAt,
  });

  factory HostOutpostStat.fromJson(Map<String, dynamic> json) {
    final last = _int(json['last_session_at']);
    return HostOutpostStat(
      uuid: json['uuid'] as String,
      name: json['name'] as String? ?? '',
      image: json['image'] as String?,
      isArchived: json['is_archived'] as bool? ?? false,
      sessions: _int(json['sessions']),
      uniqueListeners: _int(json['unique_listeners']),
      peakListeners: _int(json['peak_listeners']),
      listenMinutes: _double(json['listen_minutes']),
      avgListenMinutes: _double(json['avg_listen_minutes']),
      retention10MinRate: _double(json['retention_10min_rate']),
      earned: _double(json['earned']),
      lastSessionAt:
          last > 0 ? DateTime.fromMillisecondsSinceEpoch(last) : null,
    );
  }
}

class HostSessionStat {
  final String uuid;
  final DateTime startedAt;
  final int durationSeconds;
  final int listeners;
  final int peakListeners;
  final double avgListenMinutes;
  final double retention10MinRate;
  final int cheers;
  final int boos;
  final double earned;

  const HostSessionStat({
    required this.uuid,
    required this.startedAt,
    required this.durationSeconds,
    required this.listeners,
    required this.peakListeners,
    required this.avgListenMinutes,
    required this.retention10MinRate,
    required this.cheers,
    required this.boos,
    required this.earned,
  });

  factory HostSessionStat.fromJson(Map<String, dynamic> json) =>
      HostSessionStat(
        uuid: json['uuid'] as String,
        startedAt: DateTime.fromMillisecondsSinceEpoch(_int(json['started_at'])),
        durationSeconds: _int(json['duration_seconds']),
        listeners: _int(json['listeners']),
        peakListeners: _int(json['peak_listeners']),
        avgListenMinutes: _double(json['avg_listen_minutes']),
        retention10MinRate: _double(json['retention_10min_rate']),
        cheers: _int(json['cheers']),
        boos: _int(json['boos']),
        earned: _double(json['earned']),
      );
}

class HostAnalyticsSummary {
  final String earnedChainId;
  final int outpostsCount;
  final HostTotals totals;
  final List<DailyPoint> daily;
  final List<RetentionPoint> retentionCurve;
  final List<ChainEarnings> earningsByChain;
  final AudienceSource audienceSource;
  final List<HeatmapCell> audienceHeatmap;
  final List<HeatmapCell> bestSlots;
  final List<HostOutpostStat> topOutposts;

  const HostAnalyticsSummary({
    required this.earnedChainId,
    required this.outpostsCount,
    required this.totals,
    required this.daily,
    required this.retentionCurve,
    required this.earningsByChain,
    required this.audienceSource,
    required this.audienceHeatmap,
    required this.bestSlots,
    required this.topOutposts,
  });

  factory HostAnalyticsSummary.fromJson(Map<String, dynamic> json) =>
      HostAnalyticsSummary(
        earnedChainId: json['earned_chain_id']?.toString() ?? '',
        outpostsCount: _int(json['outposts_count']),
        totals: HostTotals.fromJson(Map<String, dynamic>.from(json['totals'])),
        daily: _list(json['daily'], DailyPoint.fromJson),
        retentionCurve:
            _list(json['retention_curve'], RetentionPoint.fromJson),
        earningsByChain:
            _list(json['earnings_by_chain'], ChainEarnings.fromJson),
        audienceSource: AudienceSource.values.firstWhere(
          (s) => s.name == json['audience_source'],
          orElse: () => AudienceSource.none,
        ),
        audienceHeatmap: _list(json['audience_heatmap'], HeatmapCell.fromJson),
        bestSlots: _list(json['best_slots'], HeatmapCell.fromJson),
        topOutposts: _list(json['top_outposts'], HostOutpostStat.fromJson),
      );
}

class HostOutpostAnalytics {
  final String earnedChainId;
  final String outpostUuid;
  final String outpostName;
  final String? outpostImage;
  final HostTotals totals;
  final List<DailyPoint> daily;
  final List<RetentionPoint> retentionCurve;
  final List<ChainEarnings> earningsByChain;

  /// Newest first.
  final List<HostSessionStat> sessions;

  const HostOutpostAnalytics({
    required this.earnedChainId,
    required this.outpostUuid,
    required this.outpostName,
    required this.outpostImage,
    required this.totals,
    required this.daily,
    required this.retentionCurve,
    required this.earningsByChain,
    required this.sessions,
  });

  factory HostOutpostAnalytics.fromJson(Map<String, dynamic> json) {
    final outpost = Map<String, dynamic>.from(json['outpost'] as Map);
    return HostOutpostAnalytics(
      earnedChainId: json['earned_chain_id']?.toString() ?? '',
      outpostUuid: outpost['uuid'] as String,
      outpostName: outpost['name'] as String? ?? '',
      outpostImage: outpost['image'] as String?,
      totals: HostTotals.fromJson(Map<String, dynamic>.from(json['totals'])),
      daily: _list(json['daily'], DailyPoint.fromJson),
      retentionCurve: _list(json['retention_curve'], RetentionPoint.fromJson),
      earningsByChain:
          _list(json['earnings_by_chain'], ChainEarnings.fromJson),
      sessions: _list(json['sessions'], HostSessionStat.fromJson),
    );
  }
}
