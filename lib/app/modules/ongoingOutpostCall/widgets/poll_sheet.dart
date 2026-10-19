import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/call_room_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/call_sheet.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/member_interactions.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/widgets/ui/app_ui.dart';

void openPollSheet() {
  if (findCallRoom() == null) return;
  Get.bottomSheet(
    const PollSheet(),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

void openCreatePollSheet() {
  if (findCallRoom() == null) return;
  Get.bottomSheet(
    const CreatePollSheet(),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

String votesLabel(int count) => count == 1 ? '1 vote' : '$count votes';

class PollSheet extends GetView<CallRoomController> {
  const PollSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: CallSheet.maxHeight(context, 0.85)),
      child: CallSheet(
        title: 'Poll',
        trailing: Obx(() {
          final poll = controller.activePoll.value;
          if (poll == null) return const SizedBox.shrink();
          return PollStatusChip(open: poll.isOpen);
        }),
        child: Obx(() {
          final poll = controller.activePoll.value;
          if (poll == null) return const _NoPoll();
          final myVote = controller.myVotes[poll.id];
          final showResults =
              myVote != null || controller.amIHost || !poll.isOpen;
          final leaders = poll.isOpen ? const <int>{} : poll.leaders;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  poll.question,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _subtitle(poll, myVote),
                  style: TextStyle(
                    fontSize: 12,
                    color: ColorName.greyText,
                  ),
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < poll.options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: PollOptionRow(
                      label: poll.options[i],
                      count: poll.counts[i],
                      percent: poll.percentOf(i),
                      fraction: poll.fractionOf(i),
                      selected: myVote == i,
                      leading: leaders.contains(i),
                      showResults: showResults,
                      onTap: poll.isOpen ? () => controller.vote(i) : null,
                    ),
                  ),
                const SizedBox(height: 8),
                if (controller.canEndPoll)
                  OutlinedButton.icon(
                    onPressed: () {
                      controller.endPoll();
                      Toast.info(
                        title: 'Poll ended',
                        message: 'Final results are visible to everyone',
                      );
                    },
                    icon: const Icon(Icons.stop_circle_outlined, size: 18),
                    label: const Text('End poll'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: callDangerColor,
                      side: BorderSide(color: callDangerColor.withAlpha(120)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  )
                else if (controller.canStartPoll)
                  FilledButton.icon(
                    onPressed: () {
                      Get.closeOverlay();
                      openCreatePollSheet();
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('New poll'),
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorName.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _subtitle(PollSnapshot poll, int? myVote) {
    final votes = votesLabel(poll.total);
    if (!poll.isOpen) {
      return poll.total == 0
          ? 'Ended · No votes were cast'
          : 'Final results · $votes';
    }
    if (myVote == null) return 'Tap an option to vote · $votes';
    return '$votes · You can change your vote until the poll ends';
  }
}

class _NoPoll extends StatelessWidget {
  const _NoPoll();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.poll_outlined, size: 40, color: ColorName.greyText),
          const SizedBox(height: 12),
          const Text(
            'No poll right now',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class PollStatusChip extends StatelessWidget {
  final bool open;
  const PollStatusChip({super.key, required this.open});

  @override
  Widget build(BuildContext context) {
    final color = open ? callSpeakingColor : ColorName.greyText;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            open ? 'LIVE' : 'ENDED',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class PollOptionRow extends StatelessWidget {
  final String label;
  final int count;
  final int percent;
  final double fraction;
  final bool selected;
  final bool leading;
  final bool showResults;
  final VoidCallback? onTap;
  const PollOptionRow({
    super.key,
    required this.label,
    required this.count,
    required this.percent,
    required this.fraction,
    required this.selected,
    required this.leading,
    required this.showResults,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = leading
        ? callAccentColor
        : selected
            ? ColorName.primaryBlue
            : ColorName.white;
    final borderColor = leading
        ? callAccentColor.withAlpha(150)
        : selected
            ? ColorName.primaryBlue.withAlpha(170)
            : ColorName.cardBorder;
    return Material(
      color: ColorName.white.withAlpha(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) => Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutCubic,
                    width: showResults ? constraints.maxWidth * fraction : 0,
                    color: accent.withAlpha(leading || selected ? 45 : 22),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              child: Row(
                children: [
                  Icon(
                    leading
                        ? Icons.emoji_events_rounded
                        : selected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                    size: 20,
                    color: leading || selected ? accent : ColorName.greyText,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: leading || selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (showResults) ...[
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$percent%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color:
                                leading || selected ? accent : ColorName.white,
                          ),
                        ),
                        Text(
                          votesLabel(count),
                          style: TextStyle(
                            fontSize: 12,
                            color: ColorName.greyText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreatePollSheet extends StatefulWidget {
  const CreatePollSheet({super.key});

  @override
  State<CreatePollSheet> createState() => _CreatePollSheetState();
}

class _CreatePollSheetState extends State<CreatePollSheet> {
  final room = Get.find<CallRoomController>();
  final question = TextEditingController();
  final options = [TextEditingController(), TextEditingController()];

  @override
  void initState() {
    super.initState();
    question.addListener(_changed);
    for (final o in options) {
      o.addListener(_changed);
    }
  }

  @override
  void dispose() {
    question.dispose();
    for (final o in options) {
      o.dispose();
    }
    super.dispose();
  }

  void _changed() => setState(() {});

  bool get _valid =>
      question.text.trim().isNotEmpty &&
      options.where((o) => o.text.trim().isNotEmpty).length >=
          PollSnapshot.minOptions;

  void _addOption() {
    if (options.length >= PollSnapshot.maxOptions) return;
    setState(() => options.add(TextEditingController()..addListener(_changed)));
  }

  void _removeOption(int index) {
    if (options.length <= PollSnapshot.minOptions) return;
    setState(() => options.removeAt(index).dispose());
  }

  void _start() {
    if (!room.canStartPoll) {
      Toast.warning(
        title: "Couldn't start poll",
        message: 'Another poll is still running',
      );
      return;
    }
    final started = room.startPoll(
      question.text,
      options.map((o) => o.text).toList(),
    );
    if (!started) return;
    Get.closeOverlay();
    Toast.info(
      title: 'Poll started',
      message: 'Everyone in the outpost can vote now',
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: CallSheet.maxHeight(context, 0.75),
      child: CallSheet(
        title: 'New poll',
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                children: [
                  const _FieldLabel('Question'),
                  _PollTextField(
                    controller: question,
                    hint: 'What do you want to ask?',
                    maxLength: PollSnapshot.maxQuestionLength,
                    maxLines: 3,
                    autofocus: true,
                    showCounter: true,
                  ),
                  const SizedBox(height: 14),
                  const _FieldLabel('Options'),
                  for (var i = 0; i < options.length; i++)
                    Padding(
                      key: ObjectKey(options[i]),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: _PollTextField(
                              controller: options[i],
                              hint: 'Option ${i + 1}',
                              maxLength: PollSnapshot.maxOptionLength,
                            ),
                          ),
                          if (options.length > PollSnapshot.minOptions)
                            IconButton(
                              onPressed: () => _removeOption(i),
                              icon: const Icon(Icons.close_rounded, size: 20),
                              color: ColorName.greyText,
                              tooltip: 'Remove option',
                            ),
                        ],
                      ),
                    ),
                  if (options.length < PollSnapshot.maxOptions)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _addOption,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add option'),
                        style: TextButton.styleFrom(
                          foregroundColor: ColorName.primaryBlue,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    'Everyone in the outpost can vote once and change their '
                    'vote until you end the poll.',
                    style: TextStyle(fontSize: 12, color: ColorName.greyText),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: ColorName.cardBorder)),
              ),
              child: FilledButton.icon(
                onPressed: _valid ? _start : null,
                icon: const Icon(Icons.bar_chart_rounded, size: 20),
                label: const Text('Start poll'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: ColorName.primaryBlue,
                  foregroundColor: AppColors.onPrimary,
                  disabledBackgroundColor: ColorName.white.withAlpha(18),
                  disabledForegroundColor: ColorName.white.withAlpha(90),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          color: ColorName.greyText,
        ),
      ),
    );
  }
}

class _PollTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLength;
  final int maxLines;
  final bool autofocus;
  final bool showCounter;
  const _PollTextField({
    required this.controller,
    required this.hint,
    required this.maxLength,
    this.maxLines = 1,
    this.autofocus = false,
    this.showCounter = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      minLines: 1,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardAppearance: Brightness.dark,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        isDense: true,
        counterText: showCounter ? null : '',
        counterStyle: TextStyle(fontSize: 12, color: ColorName.greyText),
        hintText: hint,
        filled: true,
        fillColor: ColorName.white.withAlpha(10),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
