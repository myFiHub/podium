import '../controllers/outpost_detail_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/createOutpost/controllers/create_outpost_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/widgets/cohosts_widget.dart';
import 'package:podium/app/modules/global/widgets/loading_widget.dart';
import 'package:podium/app/modules/outpostDetail/widgets/outpost_actions.dart';
import 'package:podium/app/modules/outpostDetail/widgets/outpost_header.dart';
import 'package:podium/app/modules/outpostDetail/widgets/outpost_members.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/root.dart';
import 'package:podium/widgets/ui/app_ui.dart';

class OutpostDetailView extends GetView<OutpostDetailController> {
  const OutpostDetailView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageWrapper(
        child: Obx(() {
          final exists = Get.isRegistered<OutpostDetailController>();
          if (!exists) return const SizedBox();
          final outpost = controller.outpost.value;
          final accesses = controller.outpostAccesses.value;
          if (outpost == null || accesses == null) {
            return const Center(child: LoadingWidget());
          }
          final iAmOwner = outpost.creator_user_uuid == myId;
          final isScheduled = outpost.scheduled_for > 0;
          final showInvite = canInvite(
            outpost: outpost,
            currentUserId: myId,
          );
          return Column(
            children: [
              OutpostTopBar(outpost: outpost),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: AppEntrance(
                        child: OutpostHeroCard(
                            outpost: outpost, iAmOwner: iAmOwner),
                      ),
                    ),
                    if (isScheduled && iAmOwner)
                      const SliverToBoxAdapter(
                        child: AppEntrance(
                          index: 1,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: ScheduledTimer(),
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(
                      child: AppEntrance(
                        index: 2,
                        child: AppSectionHeader(title: 'About this outpost'),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: AppEntrance(
                        index: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: OutpostAccessInfo(
                            outpost: outpost,
                            iAmOwner: iAmOwner,
                          ),
                        ),
                      ),
                    ),
                    if ((outpost.cohost_user_uuids?.isNotEmpty ?? false) ||
                        iAmOwner)
                      SliverToBoxAdapter(
                        child: Obx(() => CohostsWidget(
                              cohostUserUuids: outpost.cohost_user_uuids ?? [],
                              isCreator: outpost.creator_user_uuid == myId,
                              isLoading: controller.isLoadingCohosts.value,
                              onTap: () {
                                _showCohostsBottomSheet();
                              },
                            )),
                      ),
                    if (outpost.luma_event_id != null)
                      const SliverToBoxAdapter(child: LumaIconButton()),
                    if (outpost.scheduled_for != 0)
                      const SliverToBoxAdapter(child: SetReminderButton()),
                    if (iAmOwner ||
                        (outpost.cohost_user_uuids?.contains(myId) ?? false))
                      SliverToBoxAdapter(
                        child: OutpostAnalyticsButton(outpost: outpost),
                      ),
                    const MembersList(),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
              OutpostBottomActionBar(
                outpost: outpost,
                showInvite: showInvite,
              ),
            ],
          );
        }),
      ),
    );
  }

  void _showCohostsBottomSheet() {
    final controller = Get.find<OutpostDetailController>();
    final outpost = controller.outpost.value;
    if (outpost == null) return;

    Get.bottomSheet(
      CohostsSearchBottomSheet(
        initialCohostUuids: outpost.cohost_user_uuids ?? [],
        outpostUuid: outpost.uuid,
        isCreator: outpost.creator_user_uuid == myId,
        onConfirm: (cohostUuids) {
          controller.updateCohosts(cohostUuids);
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

void openInviteBottomSheet({required bool canInviteToSpeak}) {
  Get.dialog<void>(
    UserInvitationBottomSheetContent(
      canInviteToSpeak: canInviteToSpeak,
    ),
  );
}

bool canInvite({
  required OutpostModel outpost,
  required String currentUserId,
}) {
  final iAmCreator = currentUserId == outpost.creator_user_uuid;
  final isGroupPublic = outpost.enter_type == FreeOutpostAccessTypes.public;
  final amIAMember = (outpost.i_am_member);
  if (iAmCreator || isGroupPublic || amIAMember) {
    return true;
  }
  return false;
}

bool canInviteToSpeak({
  required OutpostModel outpost,
  required String currentUserId,
}) {
  final iAmCreator = currentUserId == outpost.creator_user_uuid;
  final isGroupPublic = outpost.speak_type == FreeOutpostSpeakerTypes.everyone;
  if (iAmCreator || isGroupPublic) {
    return true;
  }
  return false;
}
