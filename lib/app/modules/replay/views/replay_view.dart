import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/replay/controllers/replay_controller.dart';
import 'package:podium/app/modules/replay/widgets/replay_panels.dart';
import 'package:podium/app/modules/replay/widgets/replay_stage.dart';
import 'package:podium/app/modules/replay/widgets/replay_transport.dart';
import 'package:podium/app/services/replay/replay_text.dart';
import 'package:podium/root.dart';
import 'package:podium/widgets/ui/app_ui.dart';

class ReplayView extends GetView<ReplayController> {
  const ReplayView({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      child: Scaffold(
        body: SafeArea(
          child: Obx(() {
            final error = controller.error.value;
            if (error != null) return _ReplayError(message: error);
            if (controller.loading.value) {
              return const Column(
                children: [
                  _ReplayHeader(),
                  Expanded(child: Center(child: CircularProgressIndicator())),
                ],
              );
            }
            final recovered = controller.meta.value?.recovered ?? false;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _ReplayHeader(),
                if (recovered)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: AppCallout(
                      text: 'The app closed during this recording, so it '
                          'ends at the last save.',
                      icon: Icons.healing_rounded,
                    ),
                  ),
                const Expanded(child: ReplayStage()),
                const SizedBox(height: 260, child: ReplayPanels()),
                const ReplayTransport(),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _ReplayHeader extends GetView<ReplayController> {
  const _ReplayHeader();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final meta = controller.meta.value;
      final by = meta?.recordedBy.name ?? '';
      return AppPageHeader(
        title: meta?.outpost.name ?? 'Replay',
        subtitle: meta == null
            ? null
            : [
                if (by.isNotEmpty) 'Recorded by $by',
                ReplayText.date(meta.startedAt),
              ].join(' · '),
        showBack: true,
        actions: [
          if (meta != null && controller.error.value == null)
            controller.sharing.value
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : AppIconButton(
                    icon: Icons.ios_share_rounded,
                    tooltip: 'Share replay',
                    onTap: controller.share,
                  ),
        ],
      );
    });
  }
}

class _ReplayError extends StatelessWidget {
  final String message;

  const _ReplayError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _ReplayHeader(),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: AppEmptyState(
                icon: Icons.play_disabled_rounded,
                title: "Can't play this replay",
                message: message,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
