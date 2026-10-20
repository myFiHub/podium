part of 'call_room_controller.dart';

class MusicTrack {
  final String id;
  final String url;
  final String title;
  final String? artist;
  final int? durationMs;

  const MusicTrack({
    required this.id,
    required this.url,
    required this.title,
    this.artist,
    this.durationMs,
  });

  static const maxTitleLength = 120;

  MusicTrack withDuration(int? ms) => MusicTrack(
        id: id,
        url: url,
        title: title,
        artist: artist,
        durationMs: ms ?? durationMs,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'title': title,
        if (artist != null) 'artist': artist,
        if (durationMs != null) 'durationMs': durationMs,
      };

  static MusicTrack? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final url = raw['url'];
    final title = raw['title'];
    if (id is! String || id.isEmpty || url is! String || title is! String) {
      return null;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      return null;
    }
    final artist = raw['artist'];
    final duration = raw['durationMs'];
    return MusicTrack(
      id: id,
      url: url,
      title: _clip(title.trim(), maxTitleLength),
      artist: artist is String && artist.trim().isNotEmpty
          ? _clip(artist.trim(), maxTitleLength)
          : null,
      durationMs: duration is num && duration > 0 ? duration.toInt() : null,
    );
  }

  static String _clip(String s, int length) =>
      s.length > length ? s.substring(0, length) : s;
}

/// A host's music state, as broadcast over the data channel.
class MusicBroadcast {
  final String byUuid;
  final int seq;
  final MusicTrack? track;
  final bool playing;
  final int positionMs;
  final double volume;
  final bool loop;

  const MusicBroadcast({
    required this.byUuid,
    required this.seq,
    required this.track,
    required this.playing,
    required this.positionMs,
    required this.volume,
    required this.loop,
  });

  bool get stopped => track == null;

  Map<String, dynamic> toJson() => {
        'by': byUuid,
        'seq': seq,
        if (track != null) 'track': track!.toJson(),
        'playing': playing,
        'pos': positionMs,
        'vol': volume,
        'loop': loop,
      };

  static MusicBroadcast? tryParse(Map<String, dynamic> data) {
    final by = data['by'];
    final seq = data['seq'];
    if (by is! String || by.isEmpty || seq is! num) return null;
    final rawTrack = data['track'];
    final track = rawTrack == null ? null : MusicTrack.tryParse(rawTrack);
    if (rawTrack != null && track == null) return null;
    final pos = data['pos'];
    final vol = data['vol'];
    return MusicBroadcast(
      byUuid: by,
      seq: seq.toInt(),
      track: track,
      playing: track != null && data['playing'] == true,
      positionMs: pos is num && pos > 0 ? pos.toInt() : 0,
      volume: vol is num ? vol.toDouble().clamp(0.0, 1.0) : 1.0,
      loop: data['loop'] == true,
    );
  }
}

/// Rules for keeping every device's playback in step with the host.
abstract final class MusicSync {
  static const heartbeat = Duration(seconds: 5);
  static const staleAfter = Duration(seconds: 15);
  static const driftToleranceMs = 750;

  /// Applied to the music while this device's microphone is live, so less of
  /// it is picked up and sent back into the call.
  static const duckWhileTalking = 0.35;

  /// Sequence numbers are Lamport clocks: a host taking over has seen every
  /// earlier state, so its next number is always higher. Equal numbers from
  /// two hosts acting at once are settled by uuid.
  static bool accepts({
    required int seq,
    required String byUuid,
    required int lastSeq,
    required String? lastByUuid,
  }) {
    if (seq != lastSeq) return seq > lastSeq;
    return lastByUuid == null || byUuid.compareTo(lastByUuid) >= 0;
  }

  /// Where the host's playback is now, [elapsedMs] after it reported
  /// [positionMs].
  static int expectedPositionMs({
    required int positionMs,
    required int elapsedMs,
    required bool playing,
    required bool loop,
    int? durationMs,
  }) {
    if (!playing) return positionMs;
    final int position = positionMs + (elapsedMs > 0 ? elapsedMs : 0);
    if (durationMs == null || durationMs <= 0) return position;
    if (loop) return position % durationMs;
    return position < durationMs ? position : durationMs;
  }

  static bool needsSeek(int expectedMs, int actualMs) =>
      (expectedMs - actualMs).abs() > driftToleranceMs;

  static double effectiveVolume({
    required double room,
    required double local,
    required bool muted,
    required bool micLive,
  }) {
    if (muted) return 0;
    final v = room.clamp(0.0, 1.0) * local.clamp(0.0, 1.0);
    return micLive ? v * duckWhileTalking : v;
  }
}

/// Music picked by the creator or a cohost, played on every device and kept
/// in sync through the data channel. The host that last acted controls it.
mixin _CallMusic on GetxController {
  static const _localVolumeKey = 'call_music_local_volume';

  String? uuidOf(String? jitsiId);
  bool isHostUuid(String? uuid);
  bool get amIHost;
  bool get _micLive;

  final nowPlaying = Rxn<MusicTrack>();
  final musicPlaying = false.obs;
  final musicLoading = false.obs;
  final musicLoop = false.obs;
  final roomMusicVolume = 0.8.obs;
  final localMusicVolume = 1.0.obs;
  final localMusicMuted = false.obs;
  final musicControllerUuid = RxnString();

  AudioPlayer? _musicPlayer;
  StreamSubscription<PlayerState>? _musicStateSub;
  int _musicSeq = 0;
  String? _musicSeqBy;
  int _musicLoadToken = 0;
  Timer? _musicHeartbeat;
  Timer? _musicStale;
  Timer? _musicVolumeBroadcast;

  /// Jitsi owns the audio session; the player must not reconfigure or
  /// deactivate it, or the call's audio cuts out.
  AudioPlayer get _player {
    final existing = _musicPlayer;
    if (existing != null) return existing;
    final player = AudioPlayer(
      handleInterruptions: false,
      handleAudioSessionActivation: false,
      androidApplyAudioAttributes: false,
    );
    _musicStateSub = player.playerStateStream.listen(_onPlayerState);
    _musicPlayer = player;
    return player;
  }

  bool get canControlMusic => amIHost;

  bool get iControlMusic => musicControllerUuid.value == myId;

  Stream<Duration> get musicPosition => _player.positionStream;

  Duration get musicPositionNow => _musicPlayer?.position ?? Duration.zero;

  Duration? get musicDuration {
    final ms = nowPlaying.value?.durationMs;
    return _musicPlayer?.duration ??
        (ms == null ? null : Duration(milliseconds: ms));
  }

  void _initMusic() {
    final stored = GetStorage().read(_localVolumeKey);
    if (stored is num) localMusicVolume.value = stored.toDouble().clamp(0, 1);
  }

  // Host controls ------------------------------------------------------------

  /// Loads [track] on this device first, so a link that can't be played is
  /// reported here instead of failing on everyone's phone.
  Future<bool> playTrack(MusicTrack track) async {
    if (!canControlMusic) return false;
    final token = ++_musicLoadToken;
    musicLoading.value = true;
    try {
      final duration = await _player.setUrl(track.url);
      if (token != _musicLoadToken || isClosed) return false;
      nowPlaying.value = track.withDuration(duration?.inMilliseconds);
    } catch (e) {
      l.e('music: cannot load ${track.url}: $e');
      if (token == _musicLoadToken) {
        Toast.error(
          title: "Can't play this track",
          message: 'The audio could not be loaded. Try another file or link.',
        );
      }
      return false;
    } finally {
      if (token == _musicLoadToken) musicLoading.value = false;
    }
    _takeMusicControl();
    await _player.setLoopMode(musicLoop.value ? LoopMode.one : LoopMode.off);
    _applyMusicVolume();
    musicPlaying.value = true;
    _player.play();
    _broadcastMusic();
    return true;
  }

  void toggleMusicPlay() {
    if (!canControlMusic || nowPlaying.value == null) return;
    _takeMusicControl();
    if (musicPlaying.value) {
      musicPlaying.value = false;
      _player.pause();
    } else {
      musicPlaying.value = true;
      _player.play();
    }
    _broadcastMusic();
  }

  Future<void> seekMusic(Duration position) async {
    if (!canControlMusic || nowPlaying.value == null) return;
    _takeMusicControl();
    await _player.seek(position);
    _broadcastMusic();
  }

  void setRoomMusicVolume(double volume) {
    if (!canControlMusic) return;
    roomMusicVolume.value = volume.clamp(0.0, 1.0);
    _applyMusicVolume();
    if (nowPlaying.value == null) return;
    _takeMusicControl();
    _musicVolumeBroadcast ??= Timer(const Duration(milliseconds: 300), () {
      _musicVolumeBroadcast = null;
      _broadcastMusic();
    });
  }

  void setMusicLoop(bool loop) {
    if (!canControlMusic) return;
    musicLoop.value = loop;
    _musicPlayer?.setLoopMode(loop ? LoopMode.one : LoopMode.off);
    if (nowPlaying.value == null) return;
    _takeMusicControl();
    _broadcastMusic();
  }

  void stopMusic() {
    if (!canControlMusic || nowPlaying.value == null) return;
    _takeMusicControl();
    _stopMusicLocally();
    _sendMusic(_snapshotMusic(stopped: true));
    musicControllerUuid.value = null;
  }

  // Listener controls --------------------------------------------------------

  void setLocalMusicVolume(double volume) {
    localMusicVolume.value = volume.clamp(0.0, 1.0);
    if (localMusicVolume.value > 0) localMusicMuted.value = false;
    GetStorage().write(_localVolumeKey, localMusicVolume.value);
    _applyMusicVolume();
  }

  void toggleLocalMusicMute() {
    localMusicMuted.value = !localMusicMuted.value;
    _applyMusicVolume();
  }

  void _applyMusicVolume() {
    _musicPlayer?.setVolume(MusicSync.effectiveVolume(
      room: roomMusicVolume.value,
      local: localMusicVolume.value,
      muted: localMusicMuted.value,
      micLive: _micLive,
    ));
  }

  // Sync ---------------------------------------------------------------------

  void _takeMusicControl() {
    if (iControlMusic) return;
    musicControllerUuid.value = myId;
    _musicStale?.cancel();
    _musicHeartbeat?.cancel();
    _musicHeartbeat = Timer.periodic(MusicSync.heartbeat, (_) {
      if (iControlMusic && nowPlaying.value != null) _broadcastMusic();
    });
  }

  MusicBroadcast _snapshotMusic({bool stopped = false}) {
    _musicSeq++;
    _musicSeqBy = myId;
    return MusicBroadcast(
      byUuid: myId,
      seq: _musicSeq,
      track: stopped ? null : nowPlaying.value,
      playing: !stopped && musicPlaying.value,
      positionMs: musicPositionNow.inMilliseconds,
      volume: roomMusicVolume.value,
      loop: musicLoop.value,
    );
  }

  void _broadcastMusic({String to = ''}) {
    if (!iControlMusic || nowPlaying.value == null) return;
    if (to.isEmpty) {
      _musicVolumeBroadcast?.cancel();
      _musicVolumeBroadcast = null;
    }
    _sendMusic(_snapshotMusic(), to: to);
  }

  void _sendMusic(MusicBroadcast state, {String to = ''}) {
    jitsiMeet.sendEndpointTextMessage(
      to: to,
      message: jsonEncode({
        'podium': CallRoomController._envelopeVersion,
        't': 'music',
        'uid': myId,
        ...state.toJson(),
      }),
    );
  }

  /// Asks whoever controls the music for its state, e.g. after joining.
  void _requestMusicState() {
    jitsiMeet.sendEndpointTextMessage(
      message: jsonEncode({
        'podium': CallRoomController._envelopeVersion,
        't': 'musicRequest',
        'uid': myId,
      }),
    );
  }

  void _onMusicRequest(String senderId) {
    if (iControlMusic) _broadcastMusic(to: senderId);
  }

  void _onMusicPeerJoined(String participantId) {
    if (!iControlMusic) return;
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!isClosed) _broadcastMusic(to: participantId);
    });
  }

  void _onMusicMessage(String senderId, Map<String, dynamic> data) {
    final receivedAt = DateTime.now();
    final senderUuid = uuidOf(senderId);
    if (senderUuid == null || !isHostUuid(senderUuid)) return;
    final state = MusicBroadcast.tryParse(data);
    if (state == null || state.byUuid != senderUuid || senderUuid == myId) {
      return;
    }
    if (!MusicSync.accepts(
      seq: state.seq,
      byUuid: state.byUuid,
      lastSeq: _musicSeq,
      lastByUuid: _musicSeqBy,
    )) {
      return;
    }
    _musicSeq = state.seq;
    _musicSeqBy = state.byUuid;
    _musicHeartbeat?.cancel();
    _musicHeartbeat = null;
    if (state.stopped) {
      musicControllerUuid.value = null;
      _stopMusicLocally();
      return;
    }
    musicControllerUuid.value = state.byUuid;
    _musicStale?.cancel();
    _musicStale = Timer(MusicSync.staleAfter, () {
      if (!iControlMusic) {
        musicControllerUuid.value = null;
        _stopMusicLocally();
      }
    });
    _applyRemoteMusic(state, receivedAt);
  }

  Future<void> _applyRemoteMusic(
    MusicBroadcast state,
    DateTime receivedAt,
  ) async {
    final track = state.track!;
    roomMusicVolume.value = state.volume;
    musicLoop.value = state.loop;
    if (nowPlaying.value?.id != track.id || _musicPlayer?.audioSource == null) {
      final token = ++_musicLoadToken;
      musicLoading.value = true;
      try {
        final duration = await _player.setUrl(track.url);
        if (token != _musicLoadToken || isClosed) return;
        nowPlaying.value = track.withDuration(duration?.inMilliseconds);
      } catch (e) {
        l.e('music: cannot load ${track.url}: $e');
        return;
      } finally {
        if (token == _musicLoadToken) musicLoading.value = false;
      }
    } else {
      nowPlaying.value = track.withDuration(nowPlaying.value?.durationMs);
    }
    final player = _player;
    await player.setLoopMode(state.loop ? LoopMode.one : LoopMode.off);
    _applyMusicVolume();
    final expected = MusicSync.expectedPositionMs(
      positionMs: state.positionMs,
      elapsedMs: DateTime.now().difference(receivedAt).inMilliseconds,
      playing: state.playing,
      loop: state.loop,
      durationMs: player.duration?.inMilliseconds ?? track.durationMs,
    );
    if (MusicSync.needsSeek(expected, player.position.inMilliseconds)) {
      await player.seek(Duration(milliseconds: expected));
    }
    musicPlaying.value = state.playing;
    if (state.playing && !player.playing) {
      player.play();
    } else if (!state.playing && player.playing) {
      await player.pause();
    }
  }

  void _onPlayerState(PlayerState state) {
    if (state.processingState != ProcessingState.completed) return;
    if (musicLoop.value) return;
    musicPlaying.value = false;
    final player = _musicPlayer;
    if (player == null) return;
    player.pause();
    if (iControlMusic) _broadcastMusic();
  }

  void _stopMusicLocally() {
    _musicLoadToken++;
    _musicHeartbeat?.cancel();
    _musicHeartbeat = null;
    _musicStale?.cancel();
    _musicStale = null;
    _musicVolumeBroadcast?.cancel();
    _musicVolumeBroadcast = null;
    nowPlaying.value = null;
    musicPlaying.value = false;
    musicLoading.value = false;
    _musicPlayer?.stop();
  }

  void _disposeMusic() {
    _stopMusicLocally();
    _musicStateSub?.cancel();
    _musicPlayer?.dispose();
    _musicPlayer = null;
  }
}
