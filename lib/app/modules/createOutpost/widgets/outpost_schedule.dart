import '../controllers/create_outpost_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/createOutpost/views/create_outpost_view.dart';
import 'package:podium/app/modules/createOutpost/widgets/addGuestsPopup.dart';
import 'package:podium/app/modules/createOutpost/widgets/addHostsPopup.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/ui/app_ui.dart';

class ScheduleToggle extends GetView<CreateOutpostController> {
  const ScheduleToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isScheduled = controller.isScheduled.value;
      final scheduledFor = controller.scheduledFor.value;
      final selected = scheduledFor != 0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSettingsRow(
            dense: true,
            icon: Icons.event_rounded,
            title: 'Scheduled Outpost',
            subtitle: 'Organize and notify in advance.',
            onTap: () {
              controller.toggleScheduled();
            },
            trailing: Switch(
              value: isScheduled,
              onChanged: (value) {
                controller.toggleScheduled();
              },
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !isScheduled
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                    child: Material(
                      color: selected
                          ? AppColors.primary.withAlpha(24)
                          : ColorName.white.withAlpha(10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        side: BorderSide(
                          color: selected
                              ? AppColors.primary.withAlpha(140)
                              : AppColors.accent.withAlpha(110),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          controller.openCalendarBottomSheet();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 20,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.accent,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selected
                                          ? millisecondsToFormattedDateWithTime(
                                              scheduledFor)
                                          : 'Select Date and Time',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      selected
                                          ? 'Tap to change'
                                          : 'Required for scheduled outposts',
                                      style: AppText.caption,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      );
    });
  }
}

class AddLumaEventCheckboxAndButtons extends GetView<CreateOutpostController> {
  const AddLumaEventCheckboxAndButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final addToLumaEnabled = controller.addToLuma.value;
        final isScheduled = controller.isScheduled.value;
        final scheduledFor = controller.scheduledFor.value;
        final hosts = controller.lumaHosts.value;
        final guests = controller.lumaGuests.value;
        if (!isScheduled || scheduledFor == 0) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppRowDivider(),
            AppSettingsRow(
              dense: true,
              icon: Icons.event_available_rounded,
              iconColor: AppColors.success,
              title: 'Add Outpost event to Luma',
              subtitle: 'Publish it on Luma and invite people by email',
              onTap: () {
                controller.addToLuma.value = !addToLumaEnabled;
              },
              trailing: Switch(
                value: addToLumaEnabled,
                onChanged: (value) {
                  controller.addToLuma.value = value;
                },
              ),
            ),
            if (addToLumaEnabled)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: _LumaPeopleButton(
                        icon: Icons.mic_external_on_rounded,
                        emptyLabel: 'Add Hosts',
                        count: hosts.length,
                        noun: 'host',
                        onTap: openAddHostsDialog,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _LumaPeopleButton(
                        icon: Icons.people_alt_rounded,
                        emptyLabel: 'Add Guests',
                        count: guests.length,
                        noun: 'guest',
                        onTap: openAddGuestsDialog,
                      ),
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

class _LumaPeopleButton extends StatelessWidget {
  final IconData icon;
  final String emptyLabel;
  final String noun;
  final int count;
  final VoidCallback onTap;
  const _LumaPeopleButton({
    required this.icon,
    required this.emptyLabel,
    required this.noun,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final empty = count == 0;
    final color = empty ? AppColors.accent : AppColors.success;
    return Material(
      color: color.withAlpha(22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: color.withAlpha(100)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(empty ? Icons.add_rounded : icon, size: 18, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  empty ? emptyLabel : '$count $noun${count > 1 ? 's' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
