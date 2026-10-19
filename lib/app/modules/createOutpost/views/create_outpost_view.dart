import '../controllers/create_outpost_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/createOutpost/widgets/outpost_access_options.dart';
import 'package:podium/app/modules/createOutpost/widgets/outpost_details_inputs.dart';
import 'package:podium/app/modules/createOutpost/widgets/outpost_schedule.dart';
import 'package:podium/app/modules/createOutpost/widgets/outpost_settings_toggles.dart';
import 'package:podium/root.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/ui/app_ui.dart';

class CreateGroupView extends GetView<CreateOutpostController> {
  const CreateGroupView({super.key});
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
                      const AppSectionLabel('Details'),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                SelectPicture(
                                  key: controller.intro_selectImageKey,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    children: [
                                      OutpostNameInput(
                                        key: controller.intro_outpostNameKey,
                                      ),
                                      const SizedBox(height: 8),
                                      SubjectInput(
                                        key: controller.intro_outpostSubjectKey,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TagsInput(
                              key: controller.intro_tagsKey,
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                'Separate tags with a space or comma',
                                style: AppText.caption,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SelectAccessType(
                        key: controller.intro_outpostAccessTypeKey,
                      ),
                      SelectSpeakerType(
                        key: controller.intro_outpostSpeakerTypeKey,
                      ),
                      const AppSectionLabel('Team'),
                      const SelectCohosts(),
                      const AppSectionLabel('Schedule'),
                      const AppCard(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ScheduleToggle(),
                            AddLumaEventCheckboxAndButtons(),
                          ],
                        ),
                      ),
                      const AppSectionLabel('Settings'),
                      const AppCard(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          children: [
                            AdultsCheckbox(),
                            AppRowDivider(),
                            RecordableCheckbox(),
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

String millisecondsToFormattedDateWithTime(int milliseconds) {
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
          border: Border(top: BorderSide(color: AppColors.border)),
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
                          Icon(
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
