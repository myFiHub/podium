import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

Color get _pollColor => callAccentColor;

class PollSheet extends GetView<CallRoomController> {
  const PollSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: CallSheet.maxHeight(context, 0.85)),
      child: Obx(() {
        final poll = controller.activePoll.value;
        return CallSheet(
          title: 'Poll',
          subtitle: poll == null ? null : _subtitle(poll),
          icon: Icons.poll_rounded,
          iconColor: _pollColor,
          trailing: poll == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: PollStatusChip(open: poll.isOpen),
                ),
          child: poll == null ? _noPoll() : _body(poll),
        );
      }),
    );
  }

  Widget _noPoll() {
    return AppEmptyState(
      compact: true,
      icon: Icons.poll_outlined,
      title: 'No poll right now',
      message: controller.canStartPoll
          ? 'Ask the room a quick question and see answers live.'
          : 'When the host starts a poll, you can vote here.',
      actionLabel: 'Start a poll',
      onAction: controller.canStartPoll
          ? () {
              Get.closeOverlay();
              openCreatePollSheet();
            }
          : null,
    );
  }

  Widget _body(PollSnapshot poll) {
    final myVote = controller.myVotes[poll.id];
    final showResults = myVote != null || controller.amIHost || !poll.isOpen;
    final leaders = poll.isOpen ? const <int>{} : poll.leaders;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            poll.question,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                myVote == null && poll.isOpen
                    ? Icons.touch_app_rounded
                    : Icons.how_to_vote_rounded,
                size: 14,
                color: ColorName.greyText,
              ),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(_hint(poll, myVote), style: AppText.caption)),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < poll.options.length; i++)
            AppEntrance(
              index: i,
              id: 'poll-${poll.id}-$i',
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PollOptionRow(
                  index: i,
                  label: poll.options[i],
                  count: poll.counts[i],
                  percent: poll.percentOf(i),
                  fraction: poll.fractionOf(i),
                  selected: myVote == i,
                  leading: leaders.contains(i),
                  showResults: showResults,
                  onTap: poll.isOpen
                      ? () {
                          HapticFeedback.selectionClick();
                          controller.vote(i);
                        }
                      : null,
                ),
              ),
            ),
          const SizedBox(height: 10),
          if (controller.canEndPoll)
            AppSecondaryButton(
              label: 'End poll',
              icon: Icons.stop_circle_outlined,
              color: callDangerColor,
              onPressed: () {
                controller.endPoll();
                Toast.info(
                  title: 'Poll ended',
                  message: 'Final results are visible to everyone',
                );
              },
            )
          else if (controller.canStartPoll)
            AppPrimaryButton(
              label: 'New poll',
              icon: Icons.add_rounded,
              onPressed: () {
                Get.closeOverlay();
                openCreatePollSheet();
              },
            ),
        ],
      ),
    );
  }

  String _subtitle(PollSnapshot poll) {
    if (!poll.isOpen) return 'Final results · ${votesLabel(poll.total)}';
    return votesLabel(poll.total);
  }

  String _hint(PollSnapshot poll, int? myVote) {
    if (!poll.isOpen) {
      return poll.total == 0 ? 'Ended with no votes' : 'This poll has ended';
    }
    if (myVote == null) return 'Tap an option to vote';
    return 'You can change your vote until the poll ends';
  }
}

class PollStatusChip extends StatelessWidget {
  final bool open;
  const PollStatusChip({super.key, required this.open});

  @override
  Widget build(BuildContext context) {
    final color = open ? callSpeakingColor : ColorName.greyText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBreathing(
            active: open,
            builder: (context, v) => Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  if (open)
                    BoxShadow(
                      color: color.withAlpha((160 * v).round()),
                      blurRadius: 6,
                      spreadRadius: 1.5 * v,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            open ? 'LIVE' : 'ENDED',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class PollOptionRow extends StatelessWidget {
  final int index;
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
    required this.index,
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
    final highlighted = leading || selected;
    final accent = leading
        ? _pollColor
        : selected
            ? ColorName.primaryBlue
            : ColorName.white;
    final borderColor = leading
        ? _pollColor.withAlpha(160)
        : selected
            ? ColorName.primaryBlue.withAlpha(170)
            : AppColors.border;
    return AppPressScale(
      enabled: onTap != null,
      scale: 0.98,
      child: Material(
        color: ColorName.white.withAlpha(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: borderColor, width: highlighted ? 1.5 : 1),
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
                      duration: const Duration(milliseconds: 550),
                      curve: Curves.easeOutCubic,
                      width: showResults ? constraints.maxWidth * fraction : 0,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accent.withAlpha(highlighted ? 60 : 26),
                            accent.withAlpha(highlighted ? 30 : 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 12, 14, 12),
                child: Row(
                  children: [
                    _OptionBadge(
                      index: index,
                      selected: selected,
                      leading: leading,
                      color: accent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.3,
                          fontWeight:
                              highlighted ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: !showResults
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$percent%',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: highlighted
                                          ? accent
                                          : ColorName.white,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    votesLabel(count),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: ColorName.greyText,
                                    ),
                                  ),
                                ],
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
    );
  }
}

/// Letter (A, B, C…) that turns into a check for your vote or a trophy for
/// the winning option.
class _OptionBadge extends StatelessWidget {
  final int index;
  final bool selected;
  final bool leading;
  final Color color;
  const _OptionBadge({
    required this.index,
    required this.selected,
    required this.leading,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final highlighted = selected || leading;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: highlighted ? color : ColorName.white.withAlpha(14),
        shape: BoxShape.circle,
        border: Border.all(
          color: highlighted ? color : AppColors.border,
        ),
      ),
      child: Center(
        child: leading
            ? Icon(
                Icons.emoji_events_rounded,
                size: 16,
                color: AppColors.onColor(color),
              )
            : selected
                ? Icon(
                    Icons.check_rounded,
                    size: 17,
                    color: AppColors.onColor(color),
                  )
                : Text(
                    String.fromCharCode(65 + index),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: ColorName.greyText,
                    ),
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
    HapticFeedback.selectionClick();
    setState(() => options.add(TextEditingController()..addListener(_changed)));
  }

  void _removeOption(int index) {
    if (options.length <= PollSnapshot.minOptions) return;
    HapticFeedback.selectionClick();
    setState(() => options.removeAt(index).dispose());
  }

  void _useTemplate(List<String> values) {
    HapticFeedback.selectionClick();
    while (options.length < values.length) {
      options.add(TextEditingController()..addListener(_changed));
    }
    for (var i = 0; i < options.length; i++) {
      options[i].text = i < values.length ? values[i] : '';
    }
    while (options.length > PollSnapshot.minOptions &&
        options.length > values.length) {
      options.removeLast().dispose();
    }
    setState(() {});
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
    HapticFeedback.mediumImpact();
    Get.closeOverlay();
    Toast.info(
      title: 'Poll started',
      message: 'Everyone in the outpost can vote now',
    );
  }

  static const _templates = [
    ('Yes / No', ['Yes', 'No']),
    ('Agree?', ['Agree', 'Neutral', 'Disagree']),
    ('Rate it', ['🔥 Love it', '👍 Good', '😐 Meh']),
  ];

  @override
  Widget build(BuildContext context) {
    final filled = options.where((o) => o.text.trim().isNotEmpty).length;
    return SizedBox(
      height: CallSheet.maxHeight(context, 0.8),
      child: CallSheet(
        title: 'New poll',
        subtitle: 'Everyone can vote and change it until you end it',
        icon: Icons.add_chart_rounded,
        iconColor: _pollColor,
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
                  const SizedBox(height: 10),
                  _FieldLabel(
                    'Options',
                    trailing: '$filled/${PollSnapshot.maxOptions}',
                  ),
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final (name, values) in _templates)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              avatar: Icon(
                                Icons.auto_awesome_rounded,
                                size: 14,
                                color: _pollColor,
                              ),
                              label: Text(name),
                              labelStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              backgroundColor: AppColors.fill,
                              side: BorderSide(color: AppColors.border),
                              shape: const StadiumBorder(),
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _useTemplate(values),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
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
                              prefix: _OptionPrefix(index: i),
                            ),
                          ),
                          if (options.length > PollSnapshot.minOptions)
                            IconButton(
                              onPressed: () => _removeOption(i),
                              icon: const Icon(
                                Icons.remove_circle_outline_rounded,
                                size: 20,
                              ),
                              color: ColorName.greyText,
                              tooltip: 'Remove option',
                            ),
                        ],
                      ),
                    ),
                  if (options.length < PollSnapshot.maxOptions)
                    _AddOptionButton(onTap: _addOption),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: AppPrimaryButton(
                label: 'Start poll',
                icon: Icons.bar_chart_rounded,
                onPressed: _valid ? _start : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionPrefix extends StatelessWidget {
  final int index;
  const _OptionPrefix({required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 8),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: ColorName.white.withAlpha(14),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            String.fromCharCode(65 + index),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: ColorName.greyText,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddOptionButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddOptionButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppPressScale(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: ColorName.primaryBlue.withAlpha(70)),
            color: ColorName.primaryBlue.withAlpha(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, size: 18, color: ColorName.primaryBlue),
              const SizedBox(width: 6),
              Text(
                'Add option',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ColorName.primaryBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final String? trailing;
  const _FieldLabel(this.text, {this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2, right: 2),
      child: Row(
        children: [
          Expanded(child: Text(text.toUpperCase(), style: AppText.label)),
          if (trailing != null) Text(trailing!, style: AppText.caption),
        ],
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
  final Widget? prefix;
  const _PollTextField({
    required this.controller,
    required this.hint,
    required this.maxLength,
    this.maxLines = 1,
    this.autofocus = false,
    this.showCounter = false,
    this.prefix,
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
        counterText: showCounter ? null : '',
        counterStyle: TextStyle(fontSize: 12, color: ColorName.greyText),
        hintText: hint,
        prefixIcon: prefix,
        prefixIconConstraints: const BoxConstraints(minWidth: 0),
      ),
    );
  }
}
