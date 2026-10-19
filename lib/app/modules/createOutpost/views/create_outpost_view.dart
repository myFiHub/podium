import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/createOutpost/widgets/addGuestsPopup.dart';
import 'package:podium/app/modules/createOutpost/widgets/addHostsPopup.dart';
import 'package:podium/app/modules/createOutpost/widgets/tags_input.dart';
import 'package:podium/app/modules/global/widgets/cohosts_widget.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/root.dart';
import 'package:podium/widgets/ui/app_ui.dart';

import '../controllers/create_outpost_controller.dart';

class CreateGroupView extends GetView<CreateOutpostController> {
  const CreateGroupView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (res, r) {
        controller.introFinished(false);
      },
      child: PageWrapper(
        child: Scaffold(
          body: Column(
            children: [
              const _TitleBar(),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SectionLabel('Details'),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                _SelectPicture(
                                  key: controller.intro_selectImageKey,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    children: [
                                      _OutpostNameInput(
                                        key: controller.intro_outpostNameKey,
                                      ),
                                      const SizedBox(height: 8),
                                      _SubjectInput(
                                        key: controller.intro_outpostSubjectKey,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _TagsInput(
                              key: controller.intro_tagsKey,
                            ),
                            const SizedBox(height: 8),
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Text(
                                'Separate tags with a space or comma',
                                style: AppText.caption,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _SelectAccessType(
                        key: controller.intro_outpostAccessTypeKey,
                      ),
                      _SelectSpeakerType(
                        key: controller.intro_outpostSpeakerTypeKey,
                      ),
                      const _SectionLabel('Team'),
                      const _SelectCohosts(),
                      const _SectionLabel('Schedule'),
                      const AppCard(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ScheduleToggle(),
                            _AddLumaEventCheckboxAndButtons(),
                          ],
                        ),
                      ),
                      const _SectionLabel('Settings'),
                      const AppCard(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          children: [
                            _AdultsCheckbox(),
                            _RowDivider(),
                            _RecordableCheckbox(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: const _CreateButton(),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) {
    return AppSectionHeader(
      title: title,
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: AppColors.border,
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBadge({required this.icon, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final Color color;
  final VoidCallback? onTap;
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.color = AppColors.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            _IconBadge(icon: icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _SelectPicture extends GetWidget<CreateOutpostController> {
  const _SelectPicture({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedFile = controller.fileLocalAddress.value;
      final hasImage = selectedFile != '';
      return SizedBox(
        width: 104,
        height: 104,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Material(
                color: Colors.white.withAlpha(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: hasImage
                        ? Colors.transparent
                        : AppColors.primary.withAlpha(90),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    controller.pickImage();
                  },
                  child: hasImage
                      ? Image.file(
                          File(selectedFile),
                          fit: BoxFit.cover,
                          cacheWidth: 320,
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 28,
                              color: AppColors.primary,
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Cover',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              'max 2MB',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            if (hasImage)
              Positioned(
                right: -4,
                bottom: -4,
                child: IgnorePointer(
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ColorName.cardBackground,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _ScheduleToggle extends GetView<CreateOutpostController> {
  const _ScheduleToggle();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isScheduled = controller.isScheduled.value;
      final scheduledFor = controller.scheduledFor.value;
      final selected = scheduledFor != 0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingRow(
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
                          : Colors.white.withAlpha(10),
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
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
                              const Icon(
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

millisecondsToFormattedDateWithTime(int milliseconds) {
// if a number is less than 10, add a 0 before it
  String addZero(int number) {
    return number < 10 ? '0$number' : number.toString();
  }

  final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
  final day = addZero(date.day);
  final month = addZero(date.month);
  final year = date.year;
  final hour = addZero(date.hour);
  final minute = addZero(date.minute);
  return '$day/$month/$year $hour:$minute';
}

class _TagsInput extends GetWidget<CreateOutpostController> {
  const _TagsInput({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DynamicTags(
      onTagsChanged: (values) {
        controller.setTags(values);
      },
    );
  }
}

class _TextInput extends StatelessWidget {
  final String hintText;
  final String initialValue;
  final ValueChanged<String> onChanged;
  const _TextInput({
    required this.hintText,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      keyboardAppearance: Brightness.dark,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.next,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      decoration: InputDecoration(hintText: hintText),
    );
  }
}

class _SubjectInput extends GetWidget<CreateOutpostController> {
  const _SubjectInput({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _TextInput(
      initialValue: controller.outpostSubject.value,
      hintText: 'Main subject (optional)',
      onChanged: (value) => controller.outpostSubject.value = value,
    );
  }
}

class _TitleBar extends GetWidget<CreateOutpostController> {
  const _TitleBar();

  @override
  Widget build(BuildContext context) {
    controller.contextForIntro = context;
    return const AppPageHeader(
      title: 'New Outpost',
      subtitle: 'Set the stage for your conversation',
      showBack: true,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
    );
  }
}

class _OutpostNameInput extends GetWidget<CreateOutpostController> {
  const _OutpostNameInput({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _TextInput(
      hintText: 'Outpost name',
      initialValue: controller.outpostName.value,
      onChanged: (value) => controller.outpostName.value = value,
    );
  }
}

class _CreateButton extends GetWidget<CreateOutpostController> {
  const _CreateButton();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.isCreatingNewOutpost.value;
      final bool shouldSelectTicketHolersForAccess =
          controller.shouldSelectTicketHolersForAccess;
      final bool shouldSelectTicketHolersForSpeaking =
          controller.shouldSelectTicketHolersForSpeaking;
      final isScheduled = controller.isScheduled.value;
      final scheduledFor = controller.scheduledFor.value;
      final missingLumaPeople = controller.addToLuma.value &&
          (controller.lumaGuests.isEmpty || controller.lumaHosts.isEmpty);
      final hasThingsToDo = shouldSelectTicketHolersForAccess ||
          shouldSelectTicketHolersForSpeaking ||
          (isScheduled && scheduledFor == 0) ||
          missingLumaPeople;

      String? hint;
      if (shouldSelectTicketHolersForAccess) {
        hint = 'Choose the tickets required to join';
      } else if (shouldSelectTicketHolersForSpeaking) {
        hint = 'Choose the tickets required to speak';
      } else if (isScheduled && scheduledFor == 0) {
        hint = 'Pick a date and time for your scheduled outpost';
      } else if (missingLumaPeople) {
        hint = 'Add at least one Luma host and one guest';
      }

      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: ColorName.cardBackground.withAlpha(235),
          border: const Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.bottomCenter,
              child: hint == null || loading
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              hint,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.caption.copyWith(
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            AppPrimaryButton(
              label: 'Create Outpost',
              icon: Icons.rocket_launch_rounded,
              loading: loading,
              onPressed: hasThingsToDo
                  ? null
                  : () {
                      controller.create();
                    },
            ),
          ],
        ),
      );
    });
  }
}

class _AddLumaEventCheckboxAndButtons extends GetView<CreateOutpostController> {
  const _AddLumaEventCheckboxAndButtons();

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
            const _RowDivider(),
            _SettingRow(
              icon: Icons.event_available_rounded,
              color: AppColors.success,
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

class _AdultsCheckbox extends GetView<CreateOutpostController> {
  const _AdultsCheckbox();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final isChecked = controller.newOutpostHasAdultContent.value;
        return _SettingRow(
          icon: Icons.eighteen_up_rating_outlined,
          color: AppColors.danger,
          title: 'Adults speaking',
          subtitle: 'Room content for 18+',
          onTap: () {
            controller.newOutpostHasAdultContent.value = !isChecked;
          },
          trailing: Switch(
            value: isChecked,
            activeTrackColor: AppColors.danger,
            onChanged: (value) {
              controller.newOutpostHasAdultContent.value = value;
            },
          ),
        );
      },
    );
  }
}

class _RecordableCheckbox extends GetView<CreateOutpostController> {
  const _RecordableCheckbox();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final isChecked = controller.newOutpostIsRecorable.value;
        return _SettingRow(
          icon: Icons.radio_button_checked_rounded,
          color: AppColors.danger,
          title: 'Recordable',
          subtitle: 'Outpost sessions can be recorded by you',
          onTap: () {
            controller.newOutpostIsRecorable.value = !isChecked;
          },
          trailing: Switch(
            value: isChecked,
            onChanged: (value) {
              controller.newOutpostIsRecorable.value = value;
            },
          ),
        );
      },
    );
  }
}

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
                      color: selected ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 6),
                  const Icon(
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

class _SelectSpeakerType extends GetWidget<CreateOutpostController> {
  const _SelectSpeakerType({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel('Who can speak'),
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

class _SelectAccessType extends GetWidget<CreateOutpostController> {
  const _SelectAccessType({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel('Who can join'),
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

class _SelectCohosts extends GetView<CreateOutpostController> {
  const _SelectCohosts();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cohosts = controller.cohosts.value;
      final count = cohosts.length;
      return AppCard(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: _SettingRow(
          icon: Icons.group_add_rounded,
          title: 'Cohosts',
          subtitle: count == 0
              ? 'Add cohosts to help manage the outpost'
              : '$count cohost${count > 1 ? 's' : ''} selected · tap to review',
          onTap: count == 0
              ? () => _showAddCohostsBottomSheet()
              : () => _showCohostsDialog(),
          trailing: AppIconButton(
            icon: Icons.add_rounded,
            tooltip: 'Add cohosts',
            size: 36,
            color: AppColors.primary,
            background: AppColors.primary.withAlpha(24),
            onTap: () => _showAddCohostsBottomSheet(),
          ),
        ),
      );
    });
  }

  void _showCohostsDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Selected Cohosts'),
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        content: Obx(() {
          final cohosts = controller.cohosts.value;
          if (cohosts.isEmpty) {
            return const AppEmptyState(
              icon: Icons.group_outlined,
              title: 'No cohosts selected',
              compact: true,
            );
          }
          return SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: cohosts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final cohost = cohosts[index];
                final hasImage =
                    cohost.image != null && cohost.image!.isNotEmpty;
                return Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                  decoration: BoxDecoration(
                    color: AppColors.fill,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary.withAlpha(40),
                        backgroundImage: hasImage
                            ? CachedNetworkImageProvider(
                                cohost.image!,
                                maxWidth: 160,
                              )
                            : null,
                        child: hasImage
                            ? null
                            : const Icon(
                                Icons.person_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          cohost.name ?? 'Unknown',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove',
                        icon: const Icon(
                          Icons.remove_circle_outline_rounded,
                          color: AppColors.danger,
                        ),
                        onPressed: () {
                          controller.cohosts.removeAt(index);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }),
        actions: [
          TextButton(
            onPressed: () => Get.closeOverlay(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddCohostsBottomSheet() {
    Get.bottomSheet(
      CohostsSearchBottomSheet(
        initialCohostUuids:
            controller.cohosts.value.map((u) => u.uuid).toList(),
        isCreator: true, // Always true for create outpost
        onConfirm: (cohostUuids) {
          // Convert UUIDs back to UserModel objects
          final currentCohosts = controller.cohosts.value;
          final newCohosts = cohostUuids.map((uuid) {
            return currentCohosts.firstWhere(
              (user) => user.uuid == uuid,
              orElse: () => UserModel(
                uuid: uuid,
                address: '',
                name: 'Unknown User',
              ),
            );
          }).toList();
          controller.cohosts.value = newCohosts;
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
