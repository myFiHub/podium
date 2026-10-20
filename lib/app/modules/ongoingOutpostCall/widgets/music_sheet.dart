import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/call_room_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/call_sheet.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/member_interactions.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/voice_level.dart';
import 'package:podium/app/services/music_source_service.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/ui/app_ui.dart';

void openMusicSheet() {
  final room = findCallRoom();
  if (room == null || !room.canControlMusic) return;
  Get.bottomSheet(
    const MusicSheet(),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

void openListenerMusicSheet() {
  if (findCallRoom() == null) return;
  Get.bottomSheet(
    const ListenerMusicSheet(),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

String _clock(Duration d) {
  final minutes = d.inMinutes;
  final seconds = d.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

Color get _musicColor => callSpeakingColor;

/// Host controls: pick a track and control playback for the whole room.
class MusicSheet extends GetView<CallRoomController> {
  const MusicSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: CallSheet.maxHeight(context, 0.9)),
      child: CallSheet(
        title: 'Music',
        subtitle: 'Plays for everyone in the room',
        icon: Icons.library_music_rounded,
        iconColor: _musicColor,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Obx(() {
                return AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: controller.nowPlaying.value == null
                      ? const SizedBox(width: double.infinity)
                      : const Padding(
                          padding: EdgeInsets.only(bottom: 18),
                          child: _HostNowPlaying(),
                        ),
                );
              }),
              const _TrackPicker(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded "cover" square: dancing bars while playing, a note otherwise.
class _TrackArt extends StatelessWidget {
  final bool playing;
  final bool current;
  final double size;
  const _TrackArt({
    required this.playing,
    this.current = true,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    final tint = current ? _musicColor : ColorName.greyText;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: current
              ? [
                  _musicColor.withAlpha(90),
                  AppColors.primary.withAlpha(60),
                  AppColors.violet.withAlpha(70),
                ]
              : [ColorName.white.withAlpha(16), ColorName.white.withAlpha(6)],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: current ? _musicColor.withAlpha(110) : AppColors.border,
        ),
      ),
      child: Center(
        child: current && playing
            ? VoiceBars(
                level: 0.6,
                color: ColorName.white,
                height: size * 0.4,
                bars: 4,
              )
            : Icon(
                Icons.music_note_rounded,
                size: size * 0.45,
                color: current ? ColorName.white : tint,
              ),
      ),
    );
  }
}

class _HostNowPlaying extends GetView<CallRoomController> {
  const _HostNowPlaying();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final track = controller.nowPlaying.value;
      if (track == null) return const SizedBox.shrink();
      final playing = controller.musicPlaying.value;
      final loading = controller.musicLoading.value;
      final loop = controller.musicLoop.value;
      final controllerUuid = controller.musicControllerUuid.value;
      final byOther = controllerUuid != null && controllerUuid != myId;
      return AppCard(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _musicColor.withAlpha(30),
            AppColors.surfaceGlass,
            AppColors.violet.withAlpha(22),
          ],
        ),
        borderColor: _musicColor.withAlpha(90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _TrackArt(playing: playing && !loading),
                const SizedBox(width: 14),
                Expanded(
                  child: _TrackTitle(
                    track: track,
                    caption: byOther
                        ? 'Started by '
                            '${controller.displayNameOf(uuid: controllerUuid)}'
                        : playing
                            ? 'Now playing'
                            : 'Paused',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const _SeekBar(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RoundControl(
                  tooltip: loop ? 'Loop on' : 'Loop off',
                  icon: Icons.repeat_one_rounded,
                  active: loop,
                  onPressed: () => controller.setMusicLoop(!loop),
                ),
                const SizedBox(width: 20),
                _PlayButton(
                  playing: playing,
                  loading: loading,
                  onPressed: controller.toggleMusicPlay,
                ),
                const SizedBox(width: 20),
                _RoundControl(
                  tooltip: 'Stop for everyone',
                  icon: Icons.stop_rounded,
                  color: callDangerColor,
                  onPressed: controller.stopMusic,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(4, 4, 10, 8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(30),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                children: [
                  _VolumeRow(
                    label: 'Room',
                    icon: Icons.groups_rounded,
                    value: controller.roomMusicVolume.value,
                    onChanged: controller.setRoomMusicVolume,
                  ),
                  _VolumeRow(
                    label: 'You',
                    icon: Icons.headphones_rounded,
                    value: controller.localMusicVolume.value,
                    muted: controller.localMusicMuted.value,
                    onToggleMute: controller.toggleLocalMusicMute,
                    onChanged: controller.setLocalMusicVolume,
                  ),
                  Text(
                    'Room changes it for everyone, You only on this device',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: ColorName.greyText),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _PlayButton extends StatelessWidget {
  final bool playing;
  final bool loading;
  final VoidCallback onPressed;
  const _PlayButton({
    required this.playing,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final fg = AppColors.onColor(_musicColor);
    return AppPressScale(
      scale: 0.9,
      child: Tooltip(
        message: playing ? 'Pause' : 'Play',
        child: Material(
          color: _musicColor,
          shape: const CircleBorder(),
          elevation: 0,
          shadowColor: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: loading
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onPressed();
                  },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _musicColor.withAlpha(playing ? 110 : 60),
                    blurRadius: playing ? 22 : 12,
                  ),
                ],
              ),
              child: Center(
                child: loading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: fg,
                        ),
                      )
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: Icon(
                          playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          key: ValueKey(playing),
                          size: 32,
                          color: fg,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool active;
  final Color? color;
  const _RoundControl({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.active = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? (active ? _musicColor : ColorName.greyText);
    return IconButton(
      tooltip: tooltip,
      onPressed: () {
        HapticFeedback.selectionClick();
        onPressed();
      },
      icon: Icon(icon, size: 22),
      style: IconButton.styleFrom(
        fixedSize: const Size.square(44),
        foregroundColor: tint,
        backgroundColor: tint.withAlpha(active || color != null ? 30 : 12),
        side: BorderSide(
          color: tint.withAlpha(active || color != null ? 90 : 30),
        ),
      ),
    );
  }
}

class _TrackTitle extends StatelessWidget {
  final MusicTrack track;
  final String? caption;
  const _TrackTitle({required this.track, this.caption});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (caption != null)
          Text(
            caption!.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.label.copyWith(
              fontSize: 10,
              color: _musicColor,
            ),
          ),
        const SizedBox(height: 3),
        Text(
          track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.cardTitle.copyWith(fontSize: 16),
        ),
        if (track.artist != null)
          Text(
            track.artist!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption,
          ),
      ],
    );
  }
}

class _SeekBar extends StatefulWidget {
  const _SeekBar();

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  double? _dragMs;

  @override
  Widget build(BuildContext context) {
    final room = findCallRoom();
    if (room == null) return const SizedBox.shrink();
    return StreamBuilder<Duration>(
      stream: room.musicPosition,
      builder: (context, snapshot) {
        final duration = room.musicDuration;
        final position = snapshot.data ?? room.musicPositionNow;
        final totalMs = duration?.inMilliseconds ?? 0;
        final timeStyle = TextStyle(
          fontSize: 11,
          color: ColorName.greyText,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
        if (totalMs <= 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              _clock(position),
              textAlign: TextAlign.center,
              style: timeStyle,
            ),
          );
        }
        final valueMs = (_dragMs ?? position.inMilliseconds.toDouble())
            .clamp(0.0, totalMs.toDouble());
        return Column(
          children: [
            SliderTheme(
              data: _sliderTheme(context, trackHeight: 4),
              child: Slider(
                value: valueMs,
                max: totalMs.toDouble(),
                onChanged: (v) => setState(() => _dragMs = v),
                onChangeEnd: (v) {
                  setState(() => _dragMs = null);
                  room.seekMusic(Duration(milliseconds: v.round()));
                },
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _clock(Duration(milliseconds: valueMs.round())),
                      style: timeStyle,
                    ),
                    Text(
                      '-${_clock(duration! - Duration(milliseconds: valueMs.round()))}',
                      style: timeStyle,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

SliderThemeData _sliderTheme(BuildContext context, {double trackHeight = 3}) {
  return SliderTheme.of(context).copyWith(
    trackHeight: trackHeight,
    activeTrackColor: _musicColor,
    inactiveTrackColor: ColorName.white.withAlpha(24),
    thumbColor: ColorName.white,
    overlayColor: _musicColor.withAlpha(36),
    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
    trackShape: const RoundedRectSliderTrackShape(),
    padding: const EdgeInsets.symmetric(horizontal: 8),
  );
}

class _VolumeRow extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final bool muted;
  final VoidCallback? onToggleMute;

  /// Shown instead of the level icon while not muted.
  final IconData? icon;
  const _VolumeRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.muted = false,
    this.onToggleMute,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final silent = muted || value == 0;
    final shown = silent
        ? Icons.volume_off_rounded
        : icon ??
            (value < 0.5 ? Icons.volume_down_rounded : Icons.volume_up_rounded);
    return Row(
      children: [
        IconButton(
          tooltip: onToggleMute == null
              ? label
              : (muted ? 'Unmute for me' : 'Mute for me'),
          visualDensity: VisualDensity.compact,
          onPressed: onToggleMute,
          icon: Icon(
            shown,
            size: 20,
            color: silent ? callDangerColor : ColorName.greyText,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ColorName.greyText,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: _sliderTheme(context),
            child: Slider(
              value: muted ? 0 : value.clamp(0.0, 1.0),
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '${((muted ? 0 : value) * 100).round()}%',
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ColorName.white,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

enum _Source { library, upload, link }

class _TrackPicker extends StatefulWidget {
  const _TrackPicker();

  @override
  State<_TrackPicker> createState() => _TrackPickerState();
}

class _TrackPickerState extends State<_TrackPicker> {
  _Source _source = _Source.library;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('PICK A TRACK', style: AppText.label),
        const SizedBox(height: 10),
        AppSegmented<_Source>(
          value: _source,
          color: _musicColor,
          onChanged: (s) {
            HapticFeedback.selectionClick();
            setState(() => _source = s);
          },
          segments: const [
            (_Source.library, 'Library', Icons.queue_music_rounded),
            (_Source.upload, 'Upload', Icons.upload_rounded),
            (_Source.link, 'Link', Icons.link_rounded),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 290,
          child: IndexedStack(
            index: _source.index,
            children: const [_LibraryTab(), _UploadTab(), _LinkTab()],
          ),
        ),
      ],
    );
  }
}

Future<void> _play(MusicTrack track) async {
  final room = findCallRoom();
  if (room == null) return;
  HapticFeedback.lightImpact();
  await room.playTrack(track);
}

class _LibraryTab extends StatefulWidget {
  const _LibraryTab();

  @override
  State<_LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<_LibraryTab> {
  late Future<List<MusicTrack>> _tracks =
      MusicSourceService.instance.loadLibrary();

  void _reload() => setState(() {
        _tracks = MusicSourceService.instance.loadLibrary(refresh: true);
      });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MusicTrack>>(
      future: _tracks,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: _musicColor,
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return AppEmptyState(
            compact: true,
            icon: Icons.cloud_off_rounded,
            title: "Couldn't load the library",
            message: 'Check your connection and try again.',
            onAction: _reload,
          );
        }
        final tracks = snapshot.data ?? const [];
        if (tracks.isEmpty) {
          return const AppEmptyState(
            compact: true,
            icon: Icons.library_music_outlined,
            title: 'No tracks yet',
            message: 'Upload a file or paste a link to play something.',
          );
        }
        final room = findCallRoom();
        return Obx(() {
          final currentId = room?.nowPlaying.value?.id;
          final playing = room?.musicPlaying.value ?? false;
          return ListView.separated(
            padding: const EdgeInsets.only(top: 2, bottom: 8),
            itemCount: tracks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final track = tracks[index];
              return _LibraryRow(
                track: track,
                current: track.id == currentId,
                playing: playing,
              );
            },
          );
        });
      },
    );
  }
}

class _LibraryRow extends StatelessWidget {
  final MusicTrack track;
  final bool current;
  final bool playing;
  const _LibraryRow({
    required this.track,
    required this.current,
    required this.playing,
  });

  @override
  Widget build(BuildContext context) {
    final duration = track.durationMs;
    return AppPressScale(
      enabled: !current,
      child: Material(
        color: current ? _musicColor.withAlpha(22) : AppColors.fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: current ? _musicColor.withAlpha(110) : Colors.transparent,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: current ? null : () => _play(track),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
            child: Row(
              children: [
                _TrackArt(playing: playing, current: current, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              current ? FontWeight.w700 : FontWeight.w600,
                          color: current ? _musicColor : ColorName.white,
                        ),
                      ),
                      if (track.artist != null)
                        Text(
                          track.artist!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.caption,
                        ),
                    ],
                  ),
                ),
                if (duration != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    _clock(Duration(milliseconds: duration)),
                    style: TextStyle(
                      fontSize: 12,
                      color: ColorName.greyText,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
                const SizedBox(width: 10),
                Icon(
                  current
                      ? Icons.graphic_eq_rounded
                      : Icons.play_circle_fill_rounded,
                  size: 26,
                  color: current ? _musicColor : ColorName.white.withAlpha(150),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UploadTab extends StatelessWidget {
  const _UploadTab();

  Future<void> _pick() async {
    final outpostId = Get.find<OutpostCallController>().outpost.value?.uuid;
    if (outpostId == null) return;
    final track = await MusicSourceService.instance.pickAndUpload(
      outpostId: outpostId,
    );
    if (track != null) await _play(track);
  }

  @override
  Widget build(BuildContext context) {
    final service = MusicSourceService.instance;
    return Obx(() {
      final uploading = service.uploading.value;
      final progress = service.uploadProgress.value;
      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: CustomPaint(
          foregroundPainter: _DashedBorderPainter(
            color: _musicColor.withAlpha(uploading ? 160 : 90),
            radius: AppRadius.lg,
          ),
          child: Material(
            color: _musicColor.withAlpha(uploading ? 18 : 10),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: uploading ? null : _pick,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIconTile(
                        icon: uploading
                            ? Icons.cloud_upload_rounded
                            : Icons.audio_file_rounded,
                        color: _musicColor,
                        size: 56,
                        circle: true,
                        bordered: true,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        uploading
                            ? 'Uploading… ${(progress * 100).round()}%'
                            : 'Tap to choose an audio file',
                        style: AppText.cardTitle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'MP3, M4A, AAC, WAV, OGG or FLAC · up to 30 MB',
                        textAlign: TextAlign.center,
                        style: AppText.caption,
                      ),
                      const SizedBox(height: 16),
                      if (uploading)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            minHeight: 6,
                            value: progress > 0 ? progress : null,
                            color: _musicColor,
                            backgroundColor: ColorName.white.withAlpha(20),
                          ),
                        )
                      else
                        AppPill(
                          label: 'Plays for everyone right away',
                          icon: Icons.bolt_rounded,
                          color: _musicColor,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.75),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dash = 7.0;
    const gap = 5.0;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

class _LinkTab extends StatefulWidget {
  const _LinkTab();

  @override
  State<_LinkTab> createState() => _LinkTabState();
}

class _LinkTabState extends State<_LinkTab> {
  final _url = TextEditingController();
  final _title = TextEditingController();

  @override
  void dispose() {
    _url.dispose();
    _title.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    _url.text = text;
  }

  Future<void> _submit() async {
    final track = MusicSourceService.trackFromLink(
      _url.text,
      title: _title.text,
    );
    if (track == null) {
      Toast.error(
        title: 'Invalid link',
        message: 'Paste a direct http(s) link to an audio file',
      );
      return;
    }
    FocusScope.of(context).unfocus();
    final ok = await findCallRoom()?.playTrack(track) ?? false;
    if (ok && mounted) {
      _url.clear();
      _title.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: 'https://…/track.mp3',
              prefixIcon: const Icon(Icons.link_rounded),
              suffixIcon: TextButton(
                onPressed: _paste,
                style: TextButton.styleFrom(foregroundColor: _musicColor),
                child: const Text('Paste'),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _title,
            maxLength: MusicTrack.maxTitleLength,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              hintText: 'Title (optional)',
              prefixIcon: Icon(Icons.title_rounded),
              counterText: '',
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Use a direct link to an audio file, not a streaming page.',
              style: AppText.caption,
            ),
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder(
            valueListenable: _url,
            builder: (context, value, _) => Obx(() {
              final loading = findCallRoom()?.musicLoading.value ?? false;
              return AppPrimaryButton(
                label: 'Play for everyone',
                icon: Icons.play_arrow_rounded,
                color: _musicColor,
                loading: loading,
                onPressed: value.text.trim().isEmpty ? null : _submit,
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// What a listener sees: the track and their own volume, which only
/// changes the music on this device.
class ListenerMusicSheet extends GetView<CallRoomController> {
  const ListenerMusicSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return CallSheet(
      title: 'Now playing',
      icon: Icons.headphones_rounded,
      iconColor: _musicColor,
      child: Obx(() {
        final track = controller.nowPlaying.value;
        if (track == null) {
          return const AppEmptyState(
            compact: true,
            icon: Icons.music_off_rounded,
            title: 'No music is playing',
          );
        }
        final by = controller.musicControllerUuid.value;
        final playing = controller.musicPlaying.value;
        return AppCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _musicColor.withAlpha(30),
              AppColors.surfaceGlass,
              AppColors.violet.withAlpha(22),
            ],
          ),
          borderColor: _musicColor.withAlpha(90),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _TrackArt(playing: playing),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _TrackTitle(
                      track: track,
                      caption: by == null
                          ? (playing ? 'Now playing' : 'Paused')
                          : 'Shared by ${controller.displayNameOf(uuid: by)}'
                              '${playing ? '' : ' · paused'}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _VolumeRow(
                label: 'You',
                icon: Icons.headphones_rounded,
                value: controller.localMusicVolume.value,
                muted: controller.localMusicMuted.value,
                onToggleMute: controller.toggleLocalMusicMute,
                onChanged: controller.setLocalMusicVolume,
              ),
              Text(
                'Only changes the music on your device',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: ColorName.greyText),
              ),
            ],
          ),
        );
      }),
    );
  }
}
