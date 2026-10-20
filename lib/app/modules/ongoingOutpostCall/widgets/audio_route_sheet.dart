import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/call_room_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/call_sheet.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/ui/app_ui.dart';

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
      title: 'Audio output',
      subtitle: 'Choose where you hear the room',
      icon: Icons.speaker_group_rounded,
      child: Obx(() {
        final routes = controller.audioRoutes.toList();
        if (routes.isEmpty) {
          return const AppEmptyState(
            compact: true,
            icon: Icons.speaker_rounded,
            title: 'No audio outputs found',
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, route) in routes.indexed)
              AppEntrance(
                index: i,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RouteOption(
                    icon: audioRouteIcon(route.type),
                    label: route.label,
                    selected: route.selected,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.selectAudioRoute(route);
                      Get.closeOverlay();
                    },
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _RouteOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RouteOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tint = AppColors.primary;
    return AppCard(
      onTap: selected ? null : onTap,
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      radius: AppRadius.lg,
      color: selected ? tint.withAlpha(20) : ColorName.white.withAlpha(6),
      borderColor: selected ? tint.withAlpha(150) : AppColors.border,
      child: Row(
        children: [
          AppIconTile(
            icon: icon,
            color: selected ? tint : ColorName.greyText,
            size: 40,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? tint : ColorName.white,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? tint : Colors.transparent,
              border: Border.all(
                color: selected ? tint : ColorName.greyText.withAlpha(120),
                width: 1.5,
              ),
            ),
            child: selected
                ? Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: AppColors.onColor(tint),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
