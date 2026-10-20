import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/call_room_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/call_sheet.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/member_interactions.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/member_sheet.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/member_tile.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/voice_level.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/ui/app_ui.dart';
import 'package:podium/providers/api/podium/models/outposts/liveData.dart';

enum _Filter { all, hands, stage, talking, listeners }

void openParticipantsSheet({bool showHands = false}) {
  Get.bottomSheet(
    ParticipantsSheet(showHands: showHands),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class ParticipantsSheet extends StatefulWidget {
  final bool showHands;
  const ParticipantsSheet({super.key, this.showHands = false});

  @override
  State<ParticipantsSheet> createState() => _ParticipantsSheetState();
}

class _ParticipantsSheetState extends State<ParticipantsSheet> {
  final controller = Get.find<OutpostCallController>();
  final room = findCallRoom();
  late _Filter filter = widget.showHands ? _Filter.hands : _Filter.all;

  List<_Filter> get _filters => [
        for (final f in _Filter.values)
          if (f != _Filter.hands || (room?.channelAvailable.value ?? false)) f,
      ];

  @override
  void dispose() {
    controller.searchedValueInMeet.value = '';
    super.dispose();
  }

  bool _matches(LiveMember m, String? creatorId) {
    final query = controller.searchedValueInMeet.value.toLowerCase();
    if (query.isNotEmpty &&
        !(m.name ?? '').toLowerCase().contains(query) &&
        !m.aptos_address.toLowerCase().contains(query)) {
      return false;
    }
    final onStage = isStageMember(m, creatorId: creatorId);
    return switch (filter) {
      _Filter.all => true,
      _Filter.hands => room?.isHandRaised(m.uuid) ?? false,
      _Filter.stage => onStage,
      _Filter.talking => m.is_speaking,
      _Filter.listeners => !onStage,
    };
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: CallSheet.maxHeight(context, 0.8),
      child: Obx(() {
        final members = controller.members.value;
        final talking = members.where((m) => m.is_speaking).length;
        return CallSheet(
          title: 'People',
          subtitle: talking == 0
              ? '${members.length} in the outpost'
              : '${members.length} in the outpost · $talking talking',
          icon: Icons.people_alt_rounded,
          padding: EdgeInsets.zero,
          trailing: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AppIconButton(
              icon: Icons.refresh_rounded,
              tooltip: 'Refresh',
              size: 36,
              onTap: () {
                HapticFeedback.selectionClick();
                controller.fetchLiveData(withJoin: true);
              },
            ),
          ),
          child: _content(),
        );
      }),
    );
  }

  Widget _content() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            onChanged: (v) => controller.searchedValueInMeet.value = v,
            keyboardAppearance: Brightness.dark,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Search by name or address',
              prefixIcon: Icon(Icons.search_rounded, size: 20),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              for (final f in _filters)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _FilterPill(
                    label: switch (f) {
                      _Filter.all => 'All',
                      _Filter.hands => '✋ Hands',
                      _Filter.stage => 'Speakers',
                      _Filter.talking => 'Talking now',
                      _Filter.listeners => 'Listeners',
                    },
                    selected: filter == f,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => filter = f);
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Obx(() {
            final creatorId = controller.outpost.value?.creator_user_uuid;
            controller.searchedValueInMeet.value;
            controller.speakingTick.value;
            final hands = room?.raisedHandUuids ?? const <String>[];
            final members = controller.members.value
                .where((m) => _matches(m, creatorId))
                .toList();
            if (filter == _Filter.hands) {
              members.sort((a, b) =>
                  hands.indexOf(a.uuid).compareTo(hands.indexOf(b.uuid)));
            }
            return RefreshIndicator(
              onRefresh: () async => controller.fetchLiveData(withJoin: true),
              child: members.isEmpty
                  ? ListView(
                      children: [
                        filter == _Filter.hands
                            ? const AppEmptyState(
                                compact: true,
                                icon: Icons.back_hand_outlined,
                                title: 'No hands raised',
                              )
                            : const AppEmptyState(
                                compact: true,
                                icon: Icons.person_search_rounded,
                                title: 'No one matches',
                                message: 'Try another name or filter.',
                              ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                      itemCount: members.length,
                      itemBuilder: (context, index) => _ParticipantRow(
                        key: ValueKey(members[index].uuid),
                        member: members[index],
                        isCreator: members[index].uuid == creatorId,
                      ),
                    ),
            );
          }),
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tint = AppColors.primary;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? tint.withAlpha(36) : AppColors.fill,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? tint.withAlpha(150) : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? tint : ColorName.white.withAlpha(200),
            ),
          ),
        ),
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  final LiveMember member;
  final bool isCreator;
  const _ParticipantRow({
    super.key,
    required this.member,
    required this.isCreator,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = member.uuid == myId;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onTap: () => openMemberSheet(member.uuid),
      leading: MemberAvatar(member: member, size: 38, isCreator: isCreator),
      title: Text(
        isMe ? 'You' : (member.name ?? 'User'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isMe ? ColorName.primaryBlue : ColorName.white,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: ReactionCounts(address: member.address),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (findCallRoom()?.isHandRaised(member.uuid) ?? false)
            const Text('✋', style: TextStyle(fontSize: 16))
          else if (member.is_speaking)
            VoiceLevelBuilder(
              uuid: member.uuid,
              builder: (context, level) => VoiceBars(
                level: level,
                color: callSpeakingColor,
                height: 14,
                bars: 4,
              ),
            ),
          TalkTimeBuilder(builder: (context) {
            final time = member.remaining_time;
            return Text(
              isCreator ? 'Host' : formatTalkTime(time),
              style: TextStyle(
                fontSize: 12,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: isCreator
                    ? callAccentColor
                    : time < 120
                        ? callDangerColor
                        : ColorName.greyText,
              ),
            );
          }),
        ],
      ),
    );
  }
}
