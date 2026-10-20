import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/call_room_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/member_interactions.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/poll_sheet.dart';
import 'package:podium/utils/palette.dart';

/// Compact card for the running (or just ended) poll on the call page.
class PollCard extends StatelessWidget {
  const PollCard({super.key});

  @override
  Widget build(BuildContext context) {
    final room = findCallRoom();
    if (room == null) return const SizedBox.shrink();
    return Obx(() {
      final poll = room.activePoll.value;
      final hiddenId = room.hiddenPollId.value;
      final visible = poll != null && poll.id != hiddenId;
      return AnimatedSize(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topCenter,
            children: [...previous, if (current != null) current],
          ),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, -0.15), end: Offset.zero)
                  .animate(animation),
              child: child,
            ),
          ),
          child: visible
              ? _PollCardBody(
                  key: ValueKey(poll.id),
                  poll: poll,
                  myVote: room.myVotes[poll.id],
                  onDismiss: room.hidePollCard,
                )
              : const SizedBox(width: double.infinity),
        ),
      );
    });
  }
}

class _PollCardBody extends StatelessWidget {
  final PollSnapshot poll;
  final int? myVote;
  final VoidCallback onDismiss;
  const _PollCardBody({
    super.key,
    required this.poll,
    required this.myVote,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final open = poll.isOpen;
    final leaders = poll.leaders.toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: ColorName.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: open
                ? ColorName.primaryBlue.withAlpha(110)
                : ColorName.cardBorder,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: openPollSheet,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: ColorName.primaryBlue.withAlpha(open ? 40 : 18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.poll_rounded,
                        size: 20,
                        color:
                            open ? ColorName.primaryBlue : ColorName.greyText,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            open ? 'LIVE POLL' : 'POLL ENDED',
                            style: TextStyle(
                              fontSize: 12,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                              color:
                                  open ? callSpeakingColor : ColorName.greyText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            poll.question,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!open)
                      IconButton(
                        onPressed: onDismiss,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        color: ColorName.greyText,
                        tooltip: 'Hide',
                      )
                    else
                      const SizedBox(width: 8),
                  ],
                ),
                if (!open && leaders.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 46, right: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.emoji_events_rounded,
                          size: 16,
                          color: callAccentColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            leaders.length == 1
                                ? '${poll.options[leaders.first]} · '
                                    '${poll.percentOf(leaders.first)}%'
                                : 'Tie: ${leaders.map((i) => poll.options[i]).join(', ')}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: callAccentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 46),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          myVote == null
                              ? votesLabel(poll.total)
                              : '${votesLabel(poll.total)} · You voted',
                          style: TextStyle(
                            fontSize: 12,
                            color: ColorName.greyText,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: openPollSheet,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: ColorName.primaryBlue,
                          backgroundColor: open && myVote == null
                              ? ColorName.primaryBlue.withAlpha(30)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          open && myVote == null ? 'Vote' : 'View results',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
