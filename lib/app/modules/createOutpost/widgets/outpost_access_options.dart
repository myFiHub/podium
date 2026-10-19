import '../controllers/create_outpost_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/ui/app_ui.dart';

class _Option {
  final String value;
  final String label;
  final IconData icon;
  const _Option(this.value, this.label, this.icon);
}

const _accessOptions = [
  _Option(FreeOutpostAccessTypes.public, 'Everyone', Icons.public_rounded),
  _Option(
    FreeOutpostAccessTypes.onlyLink,
    'Users having the Link',
    Icons.link_rounded,
  ),
  _Option(
    FreeOutpostAccessTypes.invited_users,
    'Invited Users',
    Icons.mail_outline_rounded,
  ),
  _Option(
    BuyableTicketTypes.onlyPodiumPassHolders,
    'Podium Pass Holders',
    Icons.confirmation_number_outlined,
  ),
];

const _speakerOptions = [
  _Option(
    FreeOutpostSpeakerTypes.everyone,
    'Everyone',
    Icons.record_voice_over_outlined,
  ),
  _Option(
    FreeOutpostSpeakerTypes.invited_users,
    'Only Invited Users',
    Icons.how_to_reg_outlined,
  ),
  _Option(
    BuyableTicketTypes.onlyPodiumPassHolders,
    'Podium Pass Holders',
    Icons.confirmation_number_outlined,
  ),
];

class _OptionGrid extends StatelessWidget {
  final List<_Option> options;
  final String selected;
  final ValueChanged<String> onChanged;
  const _OptionGrid({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < options.length; i += 2) {
      rows.add(
        Row(
          children: [
            for (var j = i; j < i + 2; j++) ...[
              if (j > i) const SizedBox(width: 10),
              Expanded(
                child: j < options.length
                    ? _OptionTile(
                        option: options[j],
                        selected: options[j].value == selected,
                        onTap: () => onChanged(options[j].value),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );
    }
    return Column(spacing: 10, children: rows);
  }
}

class _OptionTile extends StatelessWidget {
  final _Option option;
  final bool selected;
  final VoidCallback onTap;
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withAlpha(30)
          : ColorName.cardBackground.withAlpha(200),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: selected ? AppColors.primary.withAlpha(180) : AppColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 58,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  option.icon,
                  size: 20,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    option.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? ColorName.white : ColorName.greyText,
                    ),
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SelectSpeakerType extends GetWidget<CreateOutpostController> {
  const SelectSpeakerType({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSectionLabel('Who can speak'),
        Obx(
          () => _OptionGrid(
            options: _speakerOptions,
            selected: controller.outpostSpeakerType.value,
            onChanged: (value) {
              controller.setRoomSpeakingType(value);
            },
          ),
        ),
        Obx(
          () {
            final selectedList =
                controller.selectedUsersToBuyticketFrom_ToSpeak.value;
            final numberOfAddressesToAdd = controller.addressesToAddForSpeaking;
            if (controller.shouldBuyTicketToSpeak) {
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: SelectUserstoBuyTicketFrom(
                  onTap: () {
                    controller.openSelectTicketBottomSheet(
                      buyTicketToGetPermisionFor: TicketPermissionType.speak,
                    );
                  },
                  selectedListLength:
                      selectedList.length + numberOfAddressesToAdd.length,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

class SelectAccessType extends GetWidget<CreateOutpostController> {
  const SelectAccessType({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSectionLabel('Who can join'),
        Obx(
          () => _OptionGrid(
            options: _accessOptions,
            selected: controller.outpostAccessType.value,
            onChanged: (value) {
              controller.setRoomPrivacyType(value);
            },
          ),
        ),
        Obx(() {
          final selectedList =
              controller.selectedUsersToBuyTicketFrom_ToAccessRoom.value;
          final addresses = controller.addressesToAddForEntering;
          if (controller.shouldBuyTicketToAccess) {
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SelectUserstoBuyTicketFrom(
                onTap: () {
                  controller.openSelectTicketBottomSheet(
                    buyTicketToGetPermisionFor: TicketPermissionType.access,
                  );
                },
                selectedListLength: selectedList.length + addresses.length,
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }
}

class SelectUserstoBuyTicketFrom extends StatelessWidget {
  final Function onTap;
  final int selectedListLength;
  const SelectUserstoBuyTicketFrom({
    super.key,
    required this.onTap,
    required this.selectedListLength,
  });

  @override
  Widget build(BuildContext context) {
    final done = selectedListLength > 0;
    final color = done ? AppColors.success : AppColors.accent;
    return Material(
      color: color.withAlpha(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: color.withAlpha(100)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                done
                    ? Icons.verified_rounded
                    : Icons.confirmation_number_outlined,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      done
                          ? '$selectedListLength required ticket${selectedListLength > 1 ? 's' : ''}'
                          : 'Select tickets',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      done
                          ? 'Tap to review the required tickets'
                          : 'Choose whose passes grant this permission',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
