import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/widgets/outpostsList.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/ongoing_outpost_call_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/call_header.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/control_dock.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/member_interactions.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/member_tile.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/participants_sheet.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/poll_card.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/room_overlays.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/screen_share_stage.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/providers/api/podium/models/outposts/liveData.dart';
import 'package:podium/root.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/rx_selector.dart';
import 'package:podium/widgets/ui/app_ui.dart';
import 'package:share_plus/share_plus.dart';

class OngoingGroupCallView extends GetView<OngoingOutpostCallController> {
  const OngoingGroupCallView({super.key});

  @override
  Widget build(BuildContext context) {
    if (controller.introStartCalled == false) {
      controller.introStartCalled = true;
      controller.startIntro();
    }
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (res, r) {
        final exists = Get.isRegistered<OngoingOutpostCallController>();
        if (exists) {
          controller.introFinished(false);
        }
      },
      child: const Scaffold(
        body: PageWrapper(
          child: Stack(
            children: [
              Positioned.fill(
                child: Column(
                  children: [
                    ContextSaver(),
                    SafeArea(bottom: false, child: CallTopBar()),
                    ScreenShareArea(),
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(child: _CallBody()),
                          Positioned.fill(child: RoomOverlays()),
                        ],
                      ),
                    ),
                    ControlDock(),
                  ],
                ),
              ),
              Positioned.fill(child: FullscreenStage()),
            ],
          ),
        ),
      ),
    );
  }
}

class ContextSaver extends GetView<OngoingOutpostCallController> {
  const ContextSaver({super.key});

  @override
  Widget build(BuildContext context) {
    controller.contextForIntro = context;
    return emptySpace;
  }
}

class _CallBody extends GetView<OutpostCallController> {
  const _CallBody();

  @override
  Widget build(BuildContext context) {
    final callController = Get.find<OngoingOutpostCallController>();
    return RxSelector<(bool, bool)>(
      sources: [callController.shouldShowIntro, controller.members],
      select: () => (
        callController.shouldShowIntro.value,
        controller.members.value.isNotEmpty,
      ),
      builder: (context, state, _) {
        final (showIntro, hasMembers) = state;
        return RefreshIndicator(
          onRefresh: () async => controller.fetchLiveData(withJoin: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: MyStatusCard()),
              const SliverToBoxAdapter(child: RaisedHandsBanner()),
              const SliverToBoxAdapter(child: PollCard()),
              if (showIntro) const SliverToBoxAdapter(child: _IntroDemoCard()),
              if (!hasMembers)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _JoiningPlaceholder(),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Obx(() {
                    final talking = controller.talkingCount.value;
                    return _SectionHeader(
                      title: 'On stage',
                      count: controller.stageMembers.value.length,
                      extra: talking > 0 ? '$talking talking' : null,
                    );
                  }),
                ),
                const _MemberGrid(onStage: true),
                SliverToBoxAdapter(
                  child: Obx(() {
                    final count = controller.audienceMembers.value.length;
                    return _SectionHeader(
                      title: 'Listening',
                      count: count,
                      onSeeAll: count == 0 ? null : openParticipantsSheet,
                    );
                  }),
                ),
                const _MemberGrid(onStage: false),
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MemberGrid extends GetView<OutpostCallController> {
  final bool onStage;
  const _MemberGrid({required this.onStage});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final members = onStage
          ? controller.stageMembers.value
          : controller.audienceMembers.value;
      if (!onStage && members.isEmpty) {
        return const SliverToBoxAdapter(child: _EmptyAudience());
      }
      final creatorId = controller.outpost.value?.creator_user_uuid;
      return _grid(members, creatorId);
    });
  }

  Widget _grid(List<LiveMember> members, String? creatorId) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: onStage ? 96 : 74,
          mainAxisExtent: onStage ? 124 : 88,
          crossAxisSpacing: 6,
          mainAxisSpacing: 8,
        ),
        itemCount: members.length,
        // Speakers move to the front; this lets moved tiles keep their state
        // and animations instead of being rebuilt from scratch.
        findChildIndexCallback: (key) {
          final uuid = (key as ValueKey<String>).value;
          final index = members.indexWhere((m) => m.uuid == uuid);
          return index == -1 ? null : index;
        },
        itemBuilder: (context, index) {
          final member = members[index];
          return RepaintBoundary(
            key: ValueKey(member.uuid),
            child: MemberTile(
              member: member,
              isCreator: member.uuid == creatorId,
              onStage: onStage,
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final String? extra;
  final VoidCallback? onSeeAll;
  const _SectionHeader({
    required this.title,
    required this.count,
    this.extra,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 8, 10),
      child: Row(
        children: [
          Text(title.toUpperCase(), style: AppText.label),
          const SizedBox(width: 6),
          Text('$count', style: AppText.caption),
          if (extra != null) ...[
            const SizedBox(width: 10),
            Icon(Icons.graphic_eq_rounded, size: 14, color: callSpeakingColor),
            const SizedBox(width: 3),
            Text(
              extra!,
              style: TextStyle(fontSize: 12, color: callSpeakingColor),
            ),
          ],
          const Spacer(),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: ColorName.primaryBlue,
              ),
              child: const Text('See all', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _EmptyAudience extends GetView<OutpostCallController> {
  const _EmptyAudience();

  @override
  Widget build(BuildContext context) {
    final outpost = controller.outpost.value;
    final canShare =
        outpost != null && canShareOutpostUrl(outpost: outpost) == true;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.headphones_outlined, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No listeners yet. Invite people to join.',
              style: AppText.caption,
            ),
          ),
          if (canShare)
            TextButton.icon(
              onPressed: () => SharePlus.instance.share(
                ShareParams(
                  text: generateOutpostShareUrl(outpostId: outpost.uuid),
                ),
              ),
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: const Text('Share'),
            ),
        ],
      ),
    );
  }
}

class _JoiningPlaceholder extends StatelessWidget {
  const _JoiningPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(height: 14),
          Text(
            'Getting everyone on stage…',
            style: TextStyle(color: ColorName.greyText),
          ),
        ],
      ),
    );
  }
}

/// Shown only during the coach-mark intro; carries the like/dislike and
/// cheer/boo target keys.
class _IntroDemoCard extends GetView<OngoingOutpostCallController> {
  const _IntroDemoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColorName.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ColorName.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tap anyone on stage to react',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Row(
                  key: controller.likeDislikeKey,
                  children: [
                    Expanded(
                      child: CallActionButton(
                        icon: Icon(Icons.thumb_up_rounded,
                            color: ColorName.success, size: 22),
                        label: 'Like',
                        color: ColorName.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CallActionButton(
                        icon: Icon(Icons.thumb_down_rounded,
                            color: ColorName.danger, size: 22),
                        label: 'Dislike',
                        color: ColorName.danger,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  key: controller.cheerBooKey,
                  children: [
                    Expanded(
                      child: CallActionButton(
                        icon: Assets.images.cheer.image(
                            width: 24, height: 24, color: ColorName.success),
                        label: 'Cheer',
                        color: ColorName.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CallActionButton(
                        icon: Assets.images.boo.image(
                            width: 24, height: 24, color: ColorName.danger),
                        label: 'Boo',
                        color: ColorName.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
