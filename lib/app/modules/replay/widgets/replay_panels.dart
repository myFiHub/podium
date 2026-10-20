import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/widgets/img.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/call_room_controller.dart';
import 'package:podium/app/modules/replay/controllers/replay_controller.dart';
import 'package:podium/app/services/replay/replay_text.dart';
import 'package:podium/app/services/replay/replay_timeline.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/ui/app_ui.dart';

/// Chat and poll as they were at the current moment.
class ReplayPanels extends StatelessWidget {
  const ReplayPanels({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceGlass,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            TabBar(
              dividerColor: Colors.transparent,
              indicatorColor: AppColors.primary,
              labelColor: ColorName.white,
              unselectedLabelColor: ColorName.greyText,
              tabs: const [
                Tab(height: 40, child: _ChatTabLabel()),
                Tab(height: 40, text: 'Poll'),
              ],
            ),
            const Expanded(
              child: TabBarView(children: [_ChatList(), _PollPanel()]),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatTabLabel extends GetView<ReplayController> {
  const _ChatTabLabel();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final count = controller.chat.length;
      return Text(count == 0 ? 'Chat' : 'Chat ($count)');
    });
  }
}

class _ChatList extends GetView<ReplayController> {
  const _ChatList();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final messages = controller.chat.toList();
      if (messages.isEmpty) {
        return Center(
          child: Text('No messages yet', style: AppText.muted),
        );
      }
      // Reversed so the newest message sits at the bottom, in view.
      return ListView.builder(
        reverse: true,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[messages.length - 1 - index];
          return _ChatRow(key: ValueKey(message.t), message: message);
        },
      );
    });
  }
}

class _ChatRow extends GetView<ReplayController> {
  final ReplayChatMessage message;

  const _ChatRow({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () => controller.seek(message.t),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Img(
              src: '',
              alt: message.name,
              size: 28,
              borderRadius: BorderRadius.circular(28),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${message.name} · '
                    '${ReplayText.clock(Duration(milliseconds: message.t))}',
                    style: AppText.caption,
                  ),
                  const SizedBox(height: 2),
                  Text(message.text, style: AppText.body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PollPanel extends GetView<ReplayController> {
  const _PollPanel();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final raw = controller.room.value.poll;
      final poll = raw == null ? null : PollSnapshot.tryParse(raw);
      if (poll == null) {
        return Center(
          child: Text('No poll at this point', style: AppText.muted),
        );
      }
      final leaders = poll.leaders;
      return ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        children: [
          Row(
            children: [
              Expanded(child: Text(poll.question, style: AppText.cardTitle)),
              const SizedBox(width: 8),
              AppPill(
                label: poll.isOpen ? 'Open' : 'Ended',
                color: poll.isOpen ? AppColors.success : ColorName.greyText,
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < poll.options.length; i++)
            _PollOption(
              label: poll.options[i],
              fraction: poll.fractionOf(i),
              percent: poll.percentOf(i),
              leading: !poll.isOpen && leaders.contains(i),
            ),
          const SizedBox(height: 4),
          Text(
            poll.total == 1 ? '1 vote' : '${poll.total} votes',
            style: AppText.caption,
          ),
        ],
      );
    });
  }
}

class _PollOption extends StatelessWidget {
  final String label;
  final double fraction;
  final int percent;
  final bool leading;

  const _PollOption({
    required this.label,
    required this.fraction,
    required this.percent,
    required this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final color = leading ? AppColors.success : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Stack(
          children: [
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fraction.clamp(0.0, 1.0),
                child: ColoredBox(color: color.withAlpha(50)),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                border: Border.all(color: color.withAlpha(80)),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(label, style: AppText.body)),
                  Text('$percent%', style: AppText.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
