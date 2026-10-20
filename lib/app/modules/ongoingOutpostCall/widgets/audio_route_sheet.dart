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

IconData audioInputIcon(String? type) => switch (type) {
      'WIRED' => Icons.headset_mic_rounded,
      'BLUETOOTH' => Icons.bluetooth_audio_rounded,
      'USB' => Icons.usb_rounded,
      'CAR' => Icons.directions_car_rounded,
      _ => Icons.mic_rounded,
    };

void openAudioRouteSheet() {
  if (findCallRoom() == null) return;
  Get.bottomSheet(
    const AudioRouteSheet(),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

/// Opens the audio sheet; hidden until Jitsi reports its devices.
class AudioRouteButton extends StatelessWidget {
  const AudioRouteButton({super.key});

  @override
  Widget build(BuildContext context) {
    final room = findCallRoom();
    if (room == null) return const SizedBox.shrink();
    return Obx(() {
      if (room.audioRoutes.isEmpty && room.audioInputs.isEmpty) {
        return const SizedBox.shrink();
      }
      final selected = room.selectedAudioRoute;
      final mic = room.activeAudioInput;
      return IconButton(
        tooltip: [
          'Audio output: ${selected?.label ?? 'Speaker'}',
          if (mic != null) 'Microphone: ${mic.label}',
        ].join('\n'),
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
      title: 'Audio',
      subtitle: 'Choose where you hear the room and which mic you use',
      icon: Icons.speaker_group_rounded,
      child: Obx(() {
        final routes = controller.audioRoutes.toList();
        final inputs = controller.audioInputs.toList();
        if (routes.isEmpty && inputs.isEmpty) {
          return const AppEmptyState(
            compact: true,
            icon: Icons.speaker_rounded,
            title: 'No audio devices found',
          );
        }
        final automatic = controller.isAutomaticAudioInput;
        final active = controller.activeAudioInput;
        var index = 0;
        Widget entry(Widget child) => AppEntrance(
              index: index++,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: child,
              ),
            );
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (routes.isNotEmpty) ...[
                const _SectionLabel('Output'),
                for (final route in routes)
                  entry(_RouteOption(
                    icon: audioRouteIcon(route.type),
                    label: route.label,
                    selected: route.selected,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.selectAudioRoute(route);
                    },
                  )),
              ],
              if (inputs.isNotEmpty) ...[
                if (routes.isNotEmpty) const SizedBox(height: 8),
                const _SectionLabel('Microphone'),
                entry(_RouteOption(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Automatic',
                  subtitle: active != null ? 'Using ${active.label}' : null,
                  selected: automatic,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    controller.selectAudioInput(null);
                  },
                )),
                for (final input in inputs)
                  entry(_RouteOption(
                    icon: audioInputIcon(input.type),
                    label: input.label,
                    subtitle: !automatic && input.selected && !input.preferred
                        ? 'In use'
                        : null,
                    selected: input.preferred,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.selectAudioInput(input);
                    },
                  )),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: ColorName.greyText,
        ),
      ),
    );
  }
}

class _RouteOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _RouteOption({
    required this.icon,
    required this.label,
    this.subtitle,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? tint : ColorName.white,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: ColorName.greyText,
                    ),
                  ),
              ],
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
