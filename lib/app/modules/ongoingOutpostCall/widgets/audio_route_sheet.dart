import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/call_room_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/call_sheet.dart';
import 'package:podium/utils/palette.dart';

IconData audioRouteIcon(String? type) => switch (type) {
      'EARPIECE' => Icons.phone_in_talk_rounded,
      'HEADPHONES' => Icons.headphones_rounded,
      'BLUETOOTH' => Icons.bluetooth_audio_rounded,
      'CAR' => Icons.directions_car_rounded,
      _ => Icons.volume_up_rounded,
    };

void openAudioRouteSheet() {
  if (findCallRoom() == null) return;
  Get.bottomSheet(
    const AudioRouteSheet(),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

/// Shows where the call audio plays; hidden until Jitsi reports its devices.
class AudioRouteButton extends StatelessWidget {
  const AudioRouteButton({super.key});

  @override
  Widget build(BuildContext context) {
    final room = findCallRoom();
    if (room == null) return const SizedBox.shrink();
    return Obx(() {
      if (room.audioRoutes.isEmpty) return const SizedBox.shrink();
      final selected = room.selectedAudioRoute;
      return IconButton(
        tooltip: 'Audio output: ${selected?.label ?? 'Speaker'}',
        visualDensity: VisualDensity.compact,
        icon: Icon(audioRouteIcon(selected?.type), size: 22),
        onPressed: openAudioRouteSheet,
      );
    });
  }
}

class AudioRouteSheet extends GetView<CallRoomController> {
  const AudioRouteSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return CallSheet(
      title: 'Play audio through',
      child: Obx(() {
        final routes = controller.audioRoutes.toList();
        if (routes.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No audio outputs found',
              textAlign: TextAlign.center,
              style: TextStyle(color: ColorName.greyText),
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final route in routes)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Icon(
                  audioRouteIcon(route.type),
                  color:
                      route.selected ? ColorName.primaryBlue : ColorName.white,
                ),
                title: Text(
                  route.label,
                  style: TextStyle(
                    fontWeight:
                        route.selected ? FontWeight.w700 : FontWeight.w400,
                    color: route.selected
                        ? ColorName.primaryBlue
                        : ColorName.white,
                  ),
                ),
                trailing: route.selected
                    ? Icon(Icons.check_rounded, color: ColorName.primaryBlue)
                    : null,
                onTap: () {
                  HapticFeedback.selectionClick();
                  controller.selectAudioRoute(route);
                  Get.closeOverlay();
                },
              ),
          ],
        );
      }),
    );
  }
}
