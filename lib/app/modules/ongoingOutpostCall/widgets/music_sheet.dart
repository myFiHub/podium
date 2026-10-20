import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/call_room_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/call_sheet.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/member_interactions.dart';
import 'package:podium/app/services/music_source_service.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/palette.dart';

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

/// Host controls: pick a track and control playback for the whole room.
class MusicSheet extends GetView<CallRoomController> {
  const MusicSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: CallSheet.maxHeight(context, 0.9)),
      child: CallSheet(
        title: 'Music',
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Obx(() {
                if (controller.nowPlaying.value == null) {
                  return const SizedBox.shrink();
                }
                return const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: _HostNowPlaying(),
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

class _HostNowPlaying extends GetView<CallRoomController> {
  const _HostNowPlaying();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: callSpeakingColor.withAlpha(18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: callSpeakingColor.withAlpha(80)),
      ),
      child: Obx(() {
        final track = controller.nowPlaying.value;
        if (track == null) return const SizedBox.shrink();
        final playing = controller.musicPlaying.value;
        final loading = controller.musicLoading.value;
        final loop = controller.musicLoop.value;
        final controllerUuid = controller.musicControllerUuid.value;
        final byOther = controllerUuid != null && controllerUuid != myId;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TrackTitle(track: track),
            if (byOther)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Started by ${controller.displayNameOf(uuid: controllerUuid)}',
                  style: TextStyle(fontSize: 12, color: ColorName.greyText),
                ),
              ),
            const SizedBox(height: 4),
            const _SeekBar(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: loop ? 'Loop on' : 'Loop off',
                  onPressed: () => controller.setMusicLoop(!loop),
                  icon: Icon(
                    Icons.repeat_one_rounded,
                    color: loop ? callSpeakingColor : ColorName.greyText,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 56,
                  height: 56,
                  child: loading
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : IconButton.filled(
                          tooltip: playing ? 'Pause' : 'Play',
                          style: IconButton.styleFrom(
                            backgroundColor: callSpeakingColor,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: controller.toggleMusicPlay,
                          icon: Icon(
                            playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 30,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Stop for everyone',
                  onPressed: controller.stopMusic,
                  icon: Icon(Icons.stop_rounded, color: callDangerColor),
                ),
              ],
            ),
            _VolumeRow(
              label: 'Room volume',
              value: controller.roomMusicVolume.value,
              onChanged: controller.setRoomMusicVolume,
            ),
            _VolumeRow(
              label: 'Your volume',
              icon: Icons.headphones_rounded,
              value: controller.localMusicVolume.value,
              muted: controller.localMusicMuted.value,
              onToggleMute: controller.toggleLocalMusicMute,
              onChanged: controller.setLocalMusicVolume,
            ),
            Text(
              'Room volume changes it for everyone, your volume only on '
              'this device',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: ColorName.greyText),
            ),
          ],
        );
      }),
    );
  }
}

class _TrackTitle extends StatelessWidget {
  final MusicTrack track;
  const _TrackTitle({required this.track});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.music_note_rounded, color: callSpeakingColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              if (track.artist != null)
                Text(
                  track.artist!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: ColorName.greyText),
                ),
            ],
          ),
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
        if (totalMs <= 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _clock(position),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: ColorName.greyText),
            ),
          );
        }
        final valueMs = (_dragMs ?? position.inMilliseconds.toDouble())
            .clamp(0.0, totalMs.toDouble());
        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: valueMs,
                max: totalMs.toDouble(),
                activeColor: callSpeakingColor,
                onChanged: (v) => setState(() => _dragMs = v),
                onChangeEnd: (v) {
                  setState(() => _dragMs = null);
                  room.seekMusic(Duration(milliseconds: v.round()));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _clock(Duration(milliseconds: valueMs.round())),
                    style: TextStyle(fontSize: 11, color: ColorName.greyText),
                  ),
                  Text(
                    _clock(duration!),
                    style: TextStyle(fontSize: 11, color: ColorName.greyText),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
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
    final shown = muted || value == 0
        ? Icons.volume_off_rounded
        : icon ??
            (value < 0.5
                ? Icons.volume_down_rounded
                : Icons.volume_up_rounded);
    return Row(
      children: [
        IconButton(
          tooltip: onToggleMute == null
              ? label
              : (muted ? 'Unmute for me' : 'Mute for me'),
          visualDensity: VisualDensity.compact,
          onPressed: onToggleMute,
          icon: Icon(shown, size: 20, color: ColorName.greyText),
        ),
        SizedBox(
          width: 84,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: ColorName.greyText),
          ),
        ),
        Expanded(
          child: Slider(
            value: muted ? 0 : value.clamp(0.0, 1.0),
            activeColor: callSpeakingColor,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '${((muted ? 0 : value) * 100).round()}%',
            textAlign: TextAlign.end,
            style: TextStyle(fontSize: 12, color: ColorName.greyText),
          ),
        ),
      ],
    );
  }
}

class _TrackPicker extends StatelessWidget {
  const _TrackPicker();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            indicatorColor: callSpeakingColor,
            labelColor: ColorName.white,
            unselectedLabelColor: ColorName.greyText,
            dividerColor: ColorName.cardBorder,
            tabs: const [
              Tab(text: 'Library'),
              Tab(text: 'Upload'),
              Tab(text: 'Link'),
            ],
          ),
          const SizedBox(
            height: 280,
            child: TabBarView(
              children: [_LibraryTab(), _UploadTab(), _LinkTab()],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _play(MusicTrack track) async {
  final room = findCallRoom();
  if (room == null) return;
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
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          );
        }
        if (snapshot.hasError) {
          return _TabMessage(
            icon: Icons.cloud_off_rounded,
            text: "Couldn't load the library",
            action: TextButton(onPressed: _reload, child: const Text('Retry')),
          );
        }
        final tracks = snapshot.data ?? const [];
        if (tracks.isEmpty) {
          return const _TabMessage(
            icon: Icons.library_music_outlined,
            text: 'No tracks in the library yet',
          );
        }
        final room = findCallRoom();
        return Obx(() {
          final currentId = room?.nowPlaying.value?.id;
          return ListView.builder(
            padding: const EdgeInsets.only(top: 4),
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              final current = track.id == currentId;
              final duration = track.durationMs;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Icon(
                  current ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
                  color: current ? callSpeakingColor : ColorName.greyText,
                ),
                title: Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                    color: current ? callSpeakingColor : ColorName.white,
                  ),
                ),
                subtitle: track.artist == null
                    ? null
                    : Text(
                        track.artist!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: ColorName.greyText),
                      ),
                trailing: duration == null
                    ? null
                    : Text(
                        _clock(Duration(milliseconds: duration)),
                        style: TextStyle(
                          fontSize: 12,
                          color: ColorName.greyText,
                        ),
                      ),
                onTap: current ? null : () => _play(track),
              );
            },
          );
        });
      },
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
      return _TabMessage(
        icon: Icons.upload_file_rounded,
        text: uploading
            ? 'Uploading… ${(progress * 100).round()}%'
            : 'MP3, M4A, AAC, WAV, OGG or FLAC, up to 30 MB',
        action: uploading
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: LinearProgressIndicator(
                  value: progress > 0 ? progress : null,
                  color: callSpeakingColor,
                ),
              )
            : FilledButton.icon(
                onPressed: _pick,
                style: FilledButton.styleFrom(
                  backgroundColor: callSpeakingColor,
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.audio_file_rounded, size: 18),
                label: const Text('Choose audio file'),
              ),
      );
    });
  }
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
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Audio link',
              hintText: 'https://…/track.mp3',
              prefixIcon: Icon(Icons.link_rounded),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _title,
            maxLength: MusicTrack.maxTitleLength,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'Title (optional)',
              prefixIcon: Icon(Icons.title_rounded),
              counterText: '',
            ),
          ),
          const SizedBox(height: 14),
          Obx(() {
            final loading = findCallRoom()?.musicLoading.value ?? false;
            return FilledButton.icon(
              onPressed: loading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: callSpeakingColor,
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text('Play for everyone'),
            );
          }),
        ],
      ),
    );
  }
}

class _TabMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;
  const _TabMessage({required this.icon, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: ColorName.greyText),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: ColorName.greyText),
          ),
          if (action != null) ...[
            const SizedBox(height: 14),
            action!,
          ],
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
      child: Obx(() {
        final track = controller.nowPlaying.value;
        if (track == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No music is playing',
              textAlign: TextAlign.center,
              style: TextStyle(color: ColorName.greyText),
            ),
          );
        }
        final by = controller.musicControllerUuid.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TrackTitle(track: track),
            if (by != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Shared by ${controller.displayNameOf(uuid: by)}'
                  '${controller.musicPlaying.value ? '' : ' · paused'}',
                  style: TextStyle(fontSize: 12, color: ColorName.greyText),
                ),
              ),
            const SizedBox(height: 12),
            _VolumeRow(
              label: 'Your volume',
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
        );
      }),
    );
  }
}
