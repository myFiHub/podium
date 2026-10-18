part of 'call_room_controller.dart';

enum PollStatus { open, ended }

/// Public poll state, as broadcast by the host that owns the poll.
class PollSnapshot {
  static const maxQuestionLength = 200;
  static const maxOptionLength = 80;
  static const minOptions = 2;
  static const maxOptions = 6;

  final String id;
  final String ownerUuid;
  final String question;
  final List<String> options;
  final List<int> counts;
  final PollStatus status;

  /// Bumped by the owner on every change so late, out-of-order snapshots are
  /// dropped.
  final int version;

  const PollSnapshot({
    required this.id,
    required this.ownerUuid,
    required this.question,
    required this.options,
    required this.counts,
    required this.status,
    required this.version,
  });

  bool get isOpen => status == PollStatus.open;

  int get total => counts.fold(0, (sum, c) => sum + c);

  double fractionOf(int option) => total == 0 ? 0 : counts[option] / total;

  int percentOf(int option) => (fractionOf(option) * 100).round();

  /// Options sharing the highest count; empty when nobody voted.
  Set<int> get leaders {
    if (total == 0) return const {};
    final top = counts.reduce(max);
    return {
      for (var i = 0; i < counts.length; i++)
        if (counts[i] == top) i,
    };
  }

  PollSnapshot copyWith({
    List<int>? counts,
    PollStatus? status,
    int? version,
  }) =>
      PollSnapshot(
        id: id,
        ownerUuid: ownerUuid,
        question: question,
        options: options,
        counts: counts ?? this.counts,
        status: status ?? this.status,
        version: version ?? this.version,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'by': ownerUuid,
        'q': question,
        'opts': options,
        'counts': counts,
        'total': total,
        'status': status.name,
        'v': version,
      };

  static PollSnapshot? tryParse(Map<String, dynamic> data) {
    final id = data['id'];
    final by = data['by'];
    final q = data['q'];
    final opts = data['opts'];
    final counts = data['counts'];
    final status = data['status'];
    final version = data['v'];
    if (id is! String || id.isEmpty || by is! String || q is! String) {
      return null;
    }
    if (opts is! List || counts is! List || opts.length != counts.length) {
      return null;
    }
    if (opts.length < minOptions || opts.length > maxOptions) return null;
    if (opts.any((o) => o is! String) || counts.any((c) => c is! num)) {
      return null;
    }
    if (status != 'open' && status != 'ended') return null;
    return PollSnapshot(
      id: id,
      ownerUuid: by,
      question: _clip(q.trim(), maxQuestionLength),
      options: [
        for (final o in opts) _clip((o as String).trim(), maxOptionLength),
      ],
      counts: [for (final c in counts) max(0, (c as num).toInt())],
      status: status == 'open' ? PollStatus.open : PollStatus.ended,
      version: version is num ? version.toInt() : 0,
    );
  }

  static String _clip(String s, int length) =>
      s.length > length ? s.substring(0, length) : s;
}

/// Live polls. The host who starts a poll keeps every vote in memory and
/// broadcasts aggregated snapshots; everyone else only tracks their own vote.
/// Votes can be changed until the poll ends.
mixin _CallPolls on GetxController {
  /// The running poll, or the last ended one until a new poll starts.
  final activePoll = Rxn<PollSnapshot>();

  /// pollId -> option index chosen on this device.
  final myVotes = <String, int>{}.obs;

  /// Ended poll whose card the user dismissed from the call page.
  final hiddenPollId = RxnString();

  /// voterUuid -> option index; only set while this device owns [activePoll].
  Map<String, int>? _ownedVotes;
  Timer? _pollBroadcastTimer;
  String? _pollHostJitsiId;
  ({String senderId, Map<String, dynamic> data})? _unverifiedPoll;

  String? uuidOf(String? jitsiId);
  String? jitsiIdOf(String uuid);
  bool isHostUuid(String? uuid);
  bool get amIHost;

  bool get canManagePolls => amIHost;

  bool get iOwnActivePoll {
    final poll = activePoll.value;
    return poll != null && poll.ownerUuid == myId && _ownedVotes != null;
  }

  bool get canStartPoll {
    final poll = activePoll.value;
    return canManagePolls && (poll == null || !poll.isOpen);
  }

  bool get canEndPoll => iOwnActivePoll && activePoll.value!.isOpen;

  bool startPoll(String question, List<String> options) {
    if (!canStartPoll) return false;
    final q = question.trim();
    final opts =
        options.map((o) => o.trim()).where((o) => o.isNotEmpty).toList();
    if (q.isEmpty ||
        q.length > PollSnapshot.maxQuestionLength ||
        opts.length < PollSnapshot.minOptions ||
        opts.length > PollSnapshot.maxOptions ||
        opts.any((o) => o.length > PollSnapshot.maxOptionLength)) {
      return false;
    }
    _ownedVotes = <String, int>{};
    _pollHostJitsiId = null;
    hiddenPollId.value = null;
    activePoll.value = PollSnapshot(
      id: '$myId-${DateTime.now().millisecondsSinceEpoch}',
      ownerUuid: myId,
      question: q,
      options: opts,
      counts: List.filled(opts.length, 0),
      status: PollStatus.open,
      version: 0,
    );
    _sendPoll();
    return true;
  }

  void vote(int option) {
    final poll = activePoll.value;
    if (poll == null || !poll.isOpen) return;
    if (option < 0 || option >= poll.options.length) return;
    final previous = myVotes[poll.id];
    if (previous == option) return;
    if (iOwnActivePoll) {
      _recordVote(myId, option);
      return;
    }
    myVotes[poll.id] = option;
    final counts = [...poll.counts];
    if (previous != null && counts[previous] > 0) counts[previous]--;
    counts[option]++;
    activePoll.value = poll.copyWith(counts: counts);
    jitsiMeet.sendEndpointTextMessage(
      to: jitsiIdOf(poll.ownerUuid) ?? _pollHostJitsiId ?? '',
      message: _pollEnvelope('pollVote', {'id': poll.id, 'opt': option}),
    );
  }

  void endPoll() {
    if (!canEndPoll) return;
    final poll = activePoll.value!;
    activePoll.value = poll.copyWith(
      status: PollStatus.ended,
      version: poll.version + 1,
    );
    _sendPoll();
  }

  void hidePollCard() => hiddenPollId.value = activePoll.value?.id;

  void _recordVote(String voterUuid, int option) {
    final poll = activePoll.value;
    final votes = _ownedVotes;
    if (poll == null || votes == null) return;
    votes[voterUuid] = option;
    if (voterUuid == myId) myVotes[poll.id] = option;
    final counts = List.filled(poll.options.length, 0);
    for (final v in votes.values) {
      counts[v]++;
    }
    activePoll.value = poll.copyWith(
      counts: counts,
      version: poll.version + 1,
    );
    _pollBroadcastTimer ??= Timer(const Duration(milliseconds: 300), () {
      _pollBroadcastTimer = null;
      _sendPoll();
    });
  }

  /// Broadcasts the snapshot, or targets one participant (with their own vote
  /// so a rejoining voter sees their choice again).
  void _sendPoll({String to = '', String? recipientUuid}) {
    if (!iOwnActivePoll) return;
    if (to.isEmpty) {
      _pollBroadcastTimer?.cancel();
      _pollBroadcastTimer = null;
    }
    final mine = recipientUuid == null ? null : _ownedVotes![recipientUuid];
    jitsiMeet.sendEndpointTextMessage(
      to: to,
      message: _pollEnvelope('poll', {
        ...activePoll.value!.toJson(),
        if (mine != null) 'mine': mine,
      }),
    );
  }

  String _pollEnvelope(String type, Map<String, dynamic> body) => jsonEncode({
        'podium': CallRoomController._envelopeVersion,
        't': type,
        'uid': myId,
        ...body,
      });

  /// Late joiners get the current snapshot once their listeners are up.
  void _onPollPeerJoined(String participantId) {
    if (!iOwnActivePoll) return;
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (isClosed) return;
      _sendPoll(to: participantId, recipientUuid: uuidOf(participantId));
    });
  }

  /// Nobody can collect votes once the owner is gone; a later snapshot from
  /// the owner (e.g. after a reconnect) reopens it.
  void _onPollPeerLeft(String? uuid) {
    final poll = activePoll.value;
    if (poll == null || !poll.isOpen || uuid == null) return;
    if (poll.ownerUuid == uuid && !iOwnActivePoll) {
      activePoll.value = poll.copyWith(status: PollStatus.ended);
    }
  }

  void _retryUnverifiedPoll() {
    final pending = _unverifiedPoll;
    if (pending == null || uuidOf(pending.senderId) == null) return;
    _unverifiedPoll = null;
    _onPollMessage(pending.senderId, pending.data);
  }

  void _onPollMessage(String senderId, Map<String, dynamic> data) {
    final senderUuid = uuidOf(senderId);
    if (senderUuid == null) {
      _unverifiedPoll = (senderId: senderId, data: data);
      return;
    }
    if (!isHostUuid(senderUuid)) return;
    final poll = PollSnapshot.tryParse(data);
    if (poll == null || poll.ownerUuid != senderUuid) return;
    final current = activePoll.value;
    final isNew = current?.id != poll.id;
    if (!isNew && poll.version < current!.version) return;
    if (isNew && iOwnActivePoll && current!.isOpen) return;
    if (isNew) {
      _ownedVotes = null;
      _pollBroadcastTimer?.cancel();
      _pollBroadcastTimer = null;
    }
    _pollHostJitsiId = senderId;
    final mine = data['mine'];
    if (mine is int && mine >= 0 && mine < poll.options.length) {
      myVotes[poll.id] = mine;
    }
    activePoll.value = poll;
    if (isNew && poll.isOpen) {
      Toast.info(title: '📊 New poll', message: poll.question);
    }
  }

  void _onPollVote(String senderId, Map<String, dynamic> data) {
    final poll = activePoll.value;
    if (poll == null || !iOwnActivePoll || !poll.isOpen) return;
    if (data['id'] != poll.id) return;
    final option = data['opt'];
    if (option is! int || option < 0 || option >= poll.options.length) return;
    final voter = uuidOf(senderId) ?? data['uid']?.toString();
    if (voter == null || voter.isEmpty || voter == myId) return;
    if (_ownedVotes![voter] == option) return;
    _recordVote(voter, option);
  }

  @override
  void onClose() {
    _pollBroadcastTimer?.cancel();
    super.onClose();
  }
}
