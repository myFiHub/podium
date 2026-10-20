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

/// Where the call audio plays: speaker, earpiece, wired or Bluetooth.
mixin _CallAudioRoute on GetxController {
  final audioRoutes = <AudioRoute>[].obs;

  AudioRoute? get selectedAudioRoute =>
      audioRoutes.firstOrNullWhere((r) => r.selected);

  void _onAudioDevices(dynamic raw) {
    audioRoutes.assignAll(AudioRoute.listFrom(raw));
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
