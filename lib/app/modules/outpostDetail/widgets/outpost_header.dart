import '../controllers/outpost_detail_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/popUpsAndModals/outpostImage.dart';
import 'package:podium/app/modules/global/widgets/img.dart';
import 'package:podium/app/modules/global/widgets/outpostsList.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/ui/app_ui.dart';

class OutpostImage extends GetView<OutpostDetailController> {
  final double height;
  const OutpostImage({super.key, this.height = 190});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final outpost = controller.outpost.value;
      if (outpost == null) return SizedBox(height: height);

      final imageUrl =
          outpost.image.isEmpty ? Constants.logoUrl : outpost.image;

      return GestureDetector(
        onTap: () {
          openOutpostImageDialog(
            outpost: outpost,
          );
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Img(
                  src: imageUrl,
                  width: constraints.maxWidth,
                  height: height,
                  alt: outpost.name,
                  borderRadius: BorderRadius.zero,
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.45, 1],
                          colors: [
                            Colors.transparent,
                            ColorName.cardBackground.withAlpha(230),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(110),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.open_in_full_rounded,
                      size: 14,
                      color: ColorName.white,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    });
  }
}

class ShareIconButton extends StatelessWidget {
  final OutpostModel outpost;
  const ShareIconButton({super.key, required this.outpost});

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: Icons.ios_share_rounded,
      tooltip: 'Copy link',
      onTap: () {
        final url = generateOutpostShareUrl(outpostId: outpost.uuid);
        // copy to clipboard and toast
        Clipboard.setData(ClipboardData(text: url));
        Toast.info(title: 'Copied!', message: 'URL copied to clipboard');
      },
    );
  }
}

class OutpostTopBar extends StatelessWidget {
  final OutpostModel outpost;
  const OutpostTopBar({super.key, required this.outpost});

  @override
  Widget build(BuildContext context) {
    final canShare = canShareOutpostUrl(outpost: outpost) == true;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          AppIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back',
            onTap: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(
              'OUTPOST',
              textAlign: TextAlign.center,
              style: AppText.label,
            ),
          ),
          if (canShare)
            ShareIconButton(outpost: outpost)
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class OutpostHeroCard extends StatelessWidget {
  final OutpostModel outpost;
  final bool iAmOwner;
  const OutpostHeroCard({super.key, required this.outpost, required this.iAmOwner});

  @override
  Widget build(BuildContext context) {
    final isUpcoming =
        outpost.scheduled_for > DateTime.now().millisecondsSinceEpoch;
    final pills = <Widget>[
      if (outpost.creator_joined)
        AppPill(
          label: 'Host is live',
          color: AppColors.success,
          icon: Icons.circle,
        ),
      if (isUpcoming)
        AppPill(
          label: 'Scheduled',
          color: AppColors.accent,
          icon: Icons.event_rounded,
        ),
      if (outpost.is_recordable)
        AppPill(
          label: 'Recordable',
          color: AppColors.danger,
          icon: Icons.fiber_manual_record_rounded,
        ),
      if (outpost.has_adult_content)
        AppPill(
          label: '18+',
          color: AppColors.danger,
          icon: Icons.explicit_rounded,
        ),
    ];
    final creatorName = outpost.creator_user_name ?? '';
    return AppCard(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OutpostImage(),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pills.isNotEmpty) ...[
                  Wrap(spacing: 6, runSpacing: 6, children: pills),
                  const SizedBox(height: 12),
                ],
                Text(
                  outpost.name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.pageTitle.copyWith(fontSize: 24),
                ),
                if (outpost.subject.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    outpost.subject,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body.copyWith(color: ColorName.greyText),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Img(
                      src: outpost.creator_user_image,
                      size: 32,
                      alt: creatorName.isEmpty ? 'OO' : creatorName,
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hosted by', style: AppText.caption),
                          Text(
                            iAmOwner ? 'You' : creatorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.cardTitle.copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OutpostAccessInfo extends StatelessWidget {
  final OutpostModel outpost;
  final bool iAmOwner;
  const OutpostAccessInfo({super.key, required this.outpost, required this.iAmOwner});

  @override
  Widget build(BuildContext context) {
    final speakers = _OutpostInfoTile(
      icon: Icons.mic_rounded,
      color: AppColors.success,
      label: 'Speakers',
      value: parseSpeakerType(outpost.speak_type),
    );
    if (!iAmOwner) return speakers;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _OutpostInfoTile(
              icon: Icons.lock_open_rounded,
              color: AppColors.primary,
              label: 'Access',
              value: parseAccessType(outpost.enter_type),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: speakers),
        ],
      ),
    );
  }
}

class _OutpostInfoTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _OutpostInfoTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          AppIconTile(size: 36, circle: true, icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label.toUpperCase(), style: AppText.label),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.cardTitle.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
