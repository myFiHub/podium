import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/records/controllers/replays_controller.dart';
import 'package:podium/app/services/replay/replay_format.dart';
import 'package:podium/app/services/replay/replay_text.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/ui/app_ui.dart';

class ReplayListItem extends StatelessWidget {
  final ReplayEntry entry;

  const ReplayListItem({super.key, required this.entry});

  ReplaysController get _controller => Get.find<ReplaysController>();

  Future<void> _confirmDelete() async {
    final confirmed = await showAppConfirm(
      title: 'Delete replay',
      message: 'This removes "${entry.meta.outpost.name}" from this device.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed) _controller.delete(entry);
  }

  @override
  Widget build(BuildContext context) {
    final ready = entry.status == ReplayStatus.ready;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Slidable(
        key: ValueKey(entry.id),
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          extentRatio: ready ? 0.4 : 0.2,
          children: [
            if (ready)
              SlidableAction(
                onPressed: (_) => _controller.share(entry),
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                icon: Icons.ios_share_rounded,
                label: 'Share',
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.lg),
                ),
              ),
            SlidableAction(
              onPressed: (_) => _confirmDelete(),
              backgroundColor: AppColors.danger,
              foregroundColor: ColorName.white,
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              borderRadius: BorderRadius.horizontal(
                left: ready ? Radius.zero : const Radius.circular(AppRadius.lg),
                right: const Radius.circular(AppRadius.lg),
              ),
            ),
          ],
        ),
        child: AppCard(
          onTap: () => _controller.open(entry),
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            children: [
              _ReplayBadge(entry: entry),
              const SizedBox(width: 14),
              Expanded(child: _ReplayDetails(entry: entry)),
              const SizedBox(width: 8),
              _ReplayAction(entry: entry),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReplayBadge extends StatelessWidget {
  final ReplayEntry entry;

  const _ReplayBadge({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.violet.withAlpha(70),
            AppColors.primary.withAlpha(25),
          ],
        ),
        border: Border.all(color: AppColors.violet.withAlpha(60)),
      ),
      child: Icon(
        entry.meta.clips.isEmpty
            ? Icons.graphic_eq_rounded
            : Icons.screen_share_rounded,
        color: ColorName.white,
        size: 22,
      ),
    );
  }
}

class _ReplayDetails extends StatelessWidget {
  final ReplayEntry entry;

  const _ReplayDetails({required this.entry});

  @override
  Widget build(BuildContext context) {
    final meta = entry.meta;
    final sharedBy = meta.recordedBy.uuid == myId ? null : meta.recordedBy.name;
    final facts = [
      ReplayText.date(meta.startedAt),
      if (meta.durationMs > 0)
        ReplayText.clock(Duration(milliseconds: meta.durationMs)),
      ReplayText.size(entry.sizeBytes),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          meta.outpost.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.cardTitle,
        ),
        const SizedBox(height: 4),
        Text(
          facts.join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.caption,
        ),
        if (sharedBy != null && sharedBy.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            'Recorded by $sharedBy',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption,
          ),
        ],
        const SizedBox(height: 6),
        _ReplayStatusPills(entry: entry),
      ],
    );
  }
}

class _ReplayStatusPills extends StatelessWidget {
  final ReplayEntry entry;

  const _ReplayStatusPills({required this.entry});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReplaysController>();
    return Obx(() {
      final progress = controller.progressOf(entry.id);
      final pills = <Widget>[
        switch (entry.status) {
          ReplayStatus.recording => AppPill(
              label: 'Recording',
              icon: Icons.fiber_manual_record_rounded,
              color: AppColors.live,
            ),
          ReplayStatus.processing => AppPill(
              label: progress == null || progress <= 0
                  ? 'Saving…'
                  : 'Saving ${(progress * 100).round()}%',
              icon: Icons.hourglass_top_rounded,
              color: AppColors.accent,
            ),
          ReplayStatus.failed => AppPill(
              label: progress != null ? 'Retrying…' : 'Failed · tap to retry',
              icon: Icons.error_outline_rounded,
              color: AppColors.danger,
            ),
          ReplayStatus.ready => AppPill(
              label: 'Ready',
              icon: Icons.check_rounded,
              color: AppColors.success,
            ),
        },
        if (entry.meta.recovered)
          AppPill(
            label: 'Recovered',
            icon: Icons.healing_rounded,
            color: AppColors.accent,
          ),
      ];
      return Wrap(spacing: 6, runSpacing: 4, children: pills);
    });
  }
}

class _ReplayAction extends StatelessWidget {
  final ReplayEntry entry;

  const _ReplayAction({required this.entry});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReplaysController>();
    return Obx(() {
      final exporting = controller.exportingId.value == entry.id;
      final processing = entry.status == ReplayStatus.processing ||
          controller.progressOf(entry.id) != null;
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.fill,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: exporting || processing
            ? const Padding(
                padding: EdgeInsets.all(9),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                switch (entry.status) {
                  ReplayStatus.ready => Icons.play_arrow_rounded,
                  ReplayStatus.failed => Icons.refresh_rounded,
                  _ => Icons.more_horiz_rounded,
                },
                color: ColorName.white,
                size: 20,
              ),
      );
    });
  }
}
