part of 'call_room_controller.dart';

/// An audio output reported by Jitsi's native AudioMode module.
class AudioRoute {
  final String? uid;

  /// One of `SPEAKER`, `EARPIECE`, `HEADPHONES`, `BLUETOOTH` or `CAR`.
  final String type;
  final String? name;
  final bool selected;

  const AudioRoute({
    required this.uid,
    required this.type,
    required this.name,
    required this.selected,
  });

  static const knownTypes = {
    'SPEAKER',
    'EARPIECE',
    'HEADPHONES',
    'BLUETOOTH',
    'CAR',
  };

  /// Display label; Bluetooth and car devices show their own name.
  String get label {
    final deviceName = name?.trim() ?? '';
    switch (type) {
      case 'SPEAKER':
        return 'Speaker';
      case 'EARPIECE':
        return 'Phone';
      case 'HEADPHONES':
        return 'Headphones';
      case 'BLUETOOTH':
        return deviceName.isNotEmpty ? deviceName : 'Bluetooth';
      case 'CAR':
        return deviceName.isNotEmpty ? deviceName : 'Car audio';
      default:
        return type;
    }
  }

  AudioRoute withSelected(bool value) =>
      AudioRoute(uid: uid, type: type, name: name, selected: value);

  bool sameDevice(AudioRoute other) =>
      type == other.type && (uid ?? '') == (other.uid ?? '');

  /// Parses the `devices` list of an `audioDevices` event, skipping unknown
  /// types, ordered speaker, phone, wired, then wireless.
  static List<AudioRoute> listFrom(dynamic raw) {
    if (raw is! List) return const [];
    final routes = <AudioRoute>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final type = item['type']?.toString().toUpperCase();
      if (type == null || !knownTypes.contains(type)) continue;
      routes.add(AudioRoute(
        uid: item['uid']?.toString(),
        type: type,
        name: item['name']?.toString(),
        selected: item['selected'] == true,
      ));
    }
    const order = ['SPEAKER', 'EARPIECE', 'HEADPHONES', 'BLUETOOTH', 'CAR'];
    routes
        .sort((a, b) => order.indexOf(a.type).compareTo(order.indexOf(b.type)));
    return routes;
  }
}

/// A microphone reported by Jitsi's native AudioMode module.
class AudioInput {
  final String uid;

  /// One of `BUILTIN`, `WIRED`, `BLUETOOTH`, `USB`, `CAR` or `OTHER`.
  final String type;
  final String? name;

  /// Whether this is the microphone in use.
  final bool selected;

  /// Whether the user picked this microphone; when none is, the system picks.
  final bool preferred;

  const AudioInput({
    required this.uid,
    required this.type,
    required this.name,
    required this.selected,
    required this.preferred,
  });

  String get label {
    final deviceName = name?.trim() ?? '';
    switch (type) {
      case 'BUILTIN':
        return 'Built-in microphone';
      case 'WIRED':
        return 'Wired headset';
      case 'BLUETOOTH':
        return deviceName.isNotEmpty ? deviceName : 'Bluetooth';
      case 'USB':
        return deviceName.isNotEmpty ? deviceName : 'USB microphone';
      case 'CAR':
        return deviceName.isNotEmpty ? deviceName : 'Car audio';
      default:
        return deviceName.isNotEmpty ? deviceName : 'Microphone';
    }
  }

  AudioInput withPreferred(bool value) => AudioInput(
        uid: uid,
        type: type,
        name: name,
        selected: selected,
        preferred: value,
      );

  /// Parses the `inputs` list of an `audioInputs` event, ordered built-in,
  /// wired, USB, then wireless.
  static List<AudioInput> listFrom(dynamic raw) {
    if (raw is! List) return const [];
    final inputs = <AudioInput>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final uid = item['uid']?.toString();
      if (uid == null || uid.isEmpty) continue;
      inputs.add(AudioInput(
        uid: uid,
        type: item['type']?.toString().toUpperCase() ?? 'OTHER',
        name: item['name']?.toString(),
        selected: item['selected'] == true,
        preferred: item['preferred'] == true,
      ));
    }
    const order = ['BUILTIN', 'WIRED', 'USB', 'BLUETOOTH', 'CAR', 'OTHER'];
    int rank(AudioInput i) {
      final index = order.indexOf(i.type);
      return index < 0 ? order.length : index;
    }

    inputs.sort((a, b) => rank(a).compareTo(rank(b)));
    return inputs;
  }
}

/// Where the call audio plays (speaker, earpiece, wired or Bluetooth) and
/// which microphone it records from.
mixin _CallAudioRoute on GetxController {
  final audioRoutes = <AudioRoute>[].obs;
  final audioInputs = <AudioInput>[].obs;

  AudioRoute? get selectedAudioRoute =>
      audioRoutes.firstOrNullWhere((r) => r.selected);

  /// The microphone in use, whether picked by the user or the system.
  AudioInput? get activeAudioInput =>
      audioInputs.firstOrNullWhere((i) => i.selected);

  /// True when the system picks the microphone.
  bool get isAutomaticAudioInput => audioInputs.none((i) => i.preferred);

  void _onAudioDevices(dynamic raw) {
    audioRoutes.assignAll(AudioRoute.listFrom(raw));
  }

  void _onAudioInputs(dynamic raw) {
    audioInputs.assignAll(AudioInput.listFrom(raw));
  }

  /// Picks the microphone, or lets the system pick when [input] is null. The
  /// OS may move the output too (a Bluetooth headset mic brings playback with
  /// it); the native side reports the resulting route back.
  void selectAudioInput(AudioInput? input) {
    if (input == null ? isAutomaticAudioInput : input.preferred) return;
    audioInputs.assignAll([
      for (final i in audioInputs) i.withPreferred(i.uid == input?.uid),
    ]);
    jitsiMeet.sendPodiumCommand('setAudioInput', {
      if (input != null) 'uid': input.uid,
    });
  }

  void selectAudioRoute(AudioRoute route) {
    if (route.selected) return;
    audioRoutes.assignAll([
      for (final r in audioRoutes) r.withSelected(r.sameDevice(route)),
    ]);
    jitsiMeet.sendPodiumCommand('setAudioDevice', {
      if (route.uid != null) 'uid': route.uid,
      'type': route.type,
    });
  }
}
