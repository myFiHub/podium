import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/call_room_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/call_sheet.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/member_interactions.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/member_sheet.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/member_tile.dart';
import 'package:podium/gen/colors.gen.dart';
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
      child: CallSheet(
        title: 'People',
        padding: EdgeInsets.zero,
        trailing: IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded, color: ColorName.greyText),
          onPressed: () => controller.fetchLiveData(withJoin: true),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (v) => controller.searchedValueInMeet.value = v,
                keyboardAppearance: Brightness.dark,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search by name or address',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  filled: true,
                  fillColor: Colors.white.withAlpha(10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  for (final f in _filters)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(switch (f) {
                          _Filter.all => 'All',
                          _Filter.hands => '✋ Hands',
                          _Filter.stage => 'Speakers',
                          _Filter.talking => 'Talking now',
                          _Filter.listeners => 'Listeners',
                        }),
                        selected: filter == f,
                        showCheckmark: false,
                        selectedColor: ColorName.primaryBlue.withAlpha(40),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: filter == f
                              ? ColorName.primaryBlue
                              : ColorName.greyText,
                        ),
                        side: BorderSide(
                          color: filter == f
                              ? ColorName.primaryBlue
                              : ColorName.cardBorder,
                        ),
                        onSelected: (_) => setState(() => filter = f),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Obx(() {
                final creatorId = controller.outpost.value?.creator_user_uuid;
                final _ = controller.searchedValueInMeet.value;
                final hands = room?.raisedHandUuids ?? const <String>[];
                final members = controller.sortedMembers.value
                    .where((m) => _matches(m, creatorId))
                    .toList();
                if (filter == _Filter.hands) {
                  members.sort((a, b) =>
                      hands.indexOf(a.uuid).compareTo(hands.indexOf(b.uuid)));
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      controller.fetchLiveData(withJoin: true),
                  child: members.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 60),
                            Center(
                              child: Text(
                                filter == _Filter.hands
                                    ? 'No hands raised'
                                    : 'No one matches',
                                style:
                                    const TextStyle(color: ColorName.greyText),
                              ),
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
          color: isMe ? ColorName.primaryBlue : Colors.white,
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
            const Icon(Icons.graphic_eq_rounded,
                color: callSpeakingColor, size: 18),
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
