part of 'call_room_controller.dart';

class RemoteScreenShare {
  final String ownerJitsiId;
  final String? ownerUuid;
  final int pcId;
  final String trackId;
  const RemoteScreenShare({
    required this.ownerJitsiId,
    required this.ownerUuid,
    required this.pcId,
    required this.trackId,
  });

  static RemoteScreenShare? fromEvent(dynamic raw, String? Function(String?) uuidOf) {
    if (raw is! Map) return null;
    final owner = raw['participantId']?.toString();
    final pcId = raw['pcId'];
    final trackId = raw['trackId']?.toString();
    if (owner == null || pcId is! num || trackId == null) return null;
    return RemoteScreenShare(
      ownerJitsiId: owner,
      ownerUuid: uuidOf(owner),
      pcId: pcId.toInt(),
      trackId: trackId,
    );
  }
}

/// Screen sharing: Jitsi captures and sends the screen, and remote shares are
/// rendered by a native window ("stage") that the Flutter UI positions.
mixin _CallScreenShare on GetxController {
  String? uuidOf(String? jitsiId);
  String displayNameOf({String? uuid, String? jitsiId});

  final remoteShare = Rxn<RemoteScreenShare>();
  final localSharing = false.obs;
  final stageMaximized = false.obs;

  /// Width / height of the shared video, once the first frame arrives.
  final stageAspect = (16 / 9).obs;

  String? _stageKey;

  bool get screenShareSupported => Platform.isAndroid;

  String get sharerName => displayNameOf(
        uuid: remoteShare.value?.ownerUuid,
        jitsiId: remoteShare.value?.ownerJitsiId,
      );

  void _onScreenShareEvent(dynamic raw, {required bool notify}) {
    final next = RemoteScreenShare.fromEvent(raw, uuidOf);
    final previous = remoteShare.value;
    if (next?.trackId == previous?.trackId && next?.pcId == previous?.pcId) {
      return;
    }
    remoteShare.value = next;
    if (next == null) {
      stageMaximized.value = false;
      stageAspect.value = 16 / 9;
      setStageRect(null);
      return;
    }
    if (notify && previous == null) {
      Toast.info(
        title: 'Screen share',
        message: '${displayNameOf(uuid: next.ownerUuid, jitsiId: next.ownerJitsiId)} '
            'is sharing their screen',
      );
    }
  }

  void _onLocalScreenShare(bool sharing) {
    localSharing.value = sharing;
    if (Get.isRegistered<OngoingOutpostCallController>()) {
      Get.find<OngoingOutpostCallController>().onScreenShareChanged(sharing);
    }
  }

  void _onStageVideoSize(Map<String, dynamic> data) {
    final w = data['width'];
    final h = data['height'];
    if (w is num && h is num && w > 0 && h > 0) {
      stageAspect.value = w / h;
    }
  }

  void startScreenShare() {
    if (!screenShareSupported || localSharing.value) return;
    if (!Get.isRegistered<OngoingOutpostCallController>()) return;
    if (!Get.find<OngoingOutpostCallController>().canStartScreenShare()) return;
    if (remoteShare.value != null) {
      Toast.info(
        title: 'Someone is sharing',
        message: '$sharerName is sharing their screen right now',
      );
      return;
    }
    jitsiMeet.toggleScreenShare(true);
  }

  void stopScreenShare() => jitsiMeet.toggleScreenShare(false);

  void toggleStageMaximized() => stageMaximized.toggle();

  /// Moves the native stage to [rect] (logical pixels, relative to the
  /// Flutter view), or hides it when [rect] is null.
  void setStageRect(Rect? rect, [double devicePixelRatio = 1]) {
    final share = remoteShare.value;
    final visible = rect != null && share != null && !rect.isEmpty;
    final left = visible ? (rect.left * devicePixelRatio).round() : 0;
    final top = visible ? (rect.top * devicePixelRatio).round() : 0;
    final width = visible ? (rect.width * devicePixelRatio).round() : 0;
    final height = visible ? (rect.height * devicePixelRatio).round() : 0;
    final key = '$visible:$left:$top:$width:$height:${share?.pcId}:${share?.trackId}';
    if (key == _stageKey) return;
    _stageKey = key;
    jitsiMeet.setStage(
      visible: visible,
      left: left,
      top: top,
      width: width,
      height: height,
      pcId: share?.pcId,
      trackId: share?.trackId,
    );
  }

  void _disposeStage() {
    _stageKey = null;
    jitsiMeet.setStage(visible: false);
  }
}
