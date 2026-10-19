import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:podium/app/modules/global/widgets/img.dart';
import 'package:podium/app/modules/outpostDetail/controllers/outpost_detail_controller.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/providers/api/luma/models/eventModel.dart';
import 'package:podium/providers/api/luma/models/guest.dart';
import 'package:podium/utils/truncate.dart';
import 'package:podium/widgets/ui/app_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';

bool _hasStarted(String? startAt) {
  final start = DateTime.tryParse(startAt ?? '');
  if (start == null) return false;
  return DateTime.now().isAfter(start);
}

class LumaDetailsDialog extends GetView<OutpostDetailController> {
  const LumaDetailsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final eventStartAt = controller.lumaEventDetails.value?.event.start_at;
    final isStarted = _hasStarted(eventStartAt);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text('Luma Details', style: AppText.title),
                  ),
                  if (isStarted) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(28),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.success.withAlpha(70),
                        ),
                      ),
                      child: Shimmer.fromColors(
                        baseColor: Colors.white,
                        highlightColor: AppColors.success,
                        child: const Text(
                          "Started",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  AppIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Close',
                    size: 36,
                    onTap: () {
                      Get.close();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _Info(),
              const SizedBox(height: 12),
              const _Contents(),
              const SizedBox(height: 12),
              const _DoneButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Info extends GetView<OutpostDetailController> {
  const _Info();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final event = controller.lumaEventDetails.value;
      final outpost = controller.outpost.value;
      final isStarted = _hasStarted(event?.event.start_at);
      final cover = event?.event.cover_url;

      return AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (cover != null && cover.isNotEmpty) ...[
                  Img(
                    src: cover,
                    size: 44,
                    alt: 'luma event',
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EVENT NAME',
                        style: AppText.label,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event?.event.name ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.cardTitle.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (outpost?.subject.isNotEmpty ?? false) ...[
              const SizedBox(height: 10),
              Text(
                outpost?.subject ?? '',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppText.muted,
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(
                  icon: Icons.public_rounded,
                  text: event?.event.timezone ?? '',
                ),
                if (!isStarted)
                  _MetaChip(
                    icon: Icons.schedule_rounded,
                    text: _isoStringToDate(event?.event.start_at ?? ''),
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ColorName.greyText),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _isoStringToDate(String isoString) {
  final date = DateTime.tryParse(isoString);
  if (date == null) return '';
  return DateFormat('yyyy/MM/dd hh:mm a').format(date);
}

class _Contents extends GetView<OutpostDetailController> {
  const _Contents();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 42,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.fill,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: ColorName.greyText,
                dividerColor: Colors.transparent,
                tabs: [
                  Obx(() {
                    final hosts = controller.lumaHosts.value;
                    return Tab(text: "Hosts (${hosts.length})");
                  }),
                  Obx(() {
                    final guests = controller.lumaEventGuests.value;
                    return Tab(text: "Guests (${guests.length})");
                  }),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TabBarView(
                children: [
                  Obx(() {
                    final hosts = controller.lumaHosts.value;
                    if (hosts.isEmpty) {
                      return const _EmptyTab(title: 'No hosts');
                    }
                    return ListView.separated(
                      itemBuilder: (context, index) {
                        return _HostItem(host: hosts[index]);
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemCount: hosts.length,
                    );
                  }),
                  Obx(() {
                    final guests = controller.lumaEventGuests.value;
                    if (guests.isEmpty) {
                      return const _EmptyTab(title: 'No guests yet');
                    }
                    return ListView.separated(
                      itemBuilder: (context, index) {
                        return _GuestItem(guest: guests[index]);
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemCount: guests.length,
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  final String title;
  const _EmptyTab({required this.title});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: AppEmptyState(
        icon: Icons.people_outline_rounded,
        title: title,
        compact: true,
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  final Widget? leading;
  final String? name;
  final String? email;
  final Widget? trailing;
  const _PersonRow({this.leading, this.name, this.email, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name?.isNotEmpty ?? false)
                  Text(
                    name!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                Text(
                  email ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _HostItem extends StatelessWidget {
  final Luma_HostModel host;
  const _HostItem({required this.host});
  @override
  Widget build(BuildContext context) {
    return _PersonRow(
      leading: Img(
        src: host.avatar_url,
        size: 38,
        alt: host.name,
        borderRadius: const BorderRadius.all(Radius.circular(19)),
      ),
      name: host.name,
      email: truncate(host.email),
    );
  }
}

class _GuestItem extends StatelessWidget {
  final GuestDataModel guest;
  const _GuestItem({required this.guest});

  @override
  Widget build(BuildContext context) {
    final status = guest.approval_status;
    return _PersonRow(
      name: guest.user_name,
      email: truncate(guest.user_email),
      trailing: switch (status) {
        'pending' => const AppPill(
            label: 'Pending',
            color: AppColors.accent,
            icon: Icons.schedule_rounded,
          ),
        'approved' => const AppPill(
            label: 'Approved',
            color: AppColors.success,
            icon: Icons.check_rounded,
          ),
        'rejected' => const AppPill(
            label: 'Rejected',
            color: AppColors.danger,
            icon: Icons.close_rounded,
          ),
        _ => null,
      },
    );
  }
}

class _DoneButton extends GetView<OutpostDetailController> {
  const _DoneButton();
  @override
  Widget build(BuildContext context) {
    final eventLink = controller.lumaEventDetails.value?.event.url;
    return Row(
      children: [
        Expanded(
          child: AppSecondaryButton(
            label: 'Close',
            onPressed: () {
              Get.close();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppPrimaryButton(
            label: 'Share Luma Link',
            icon: Icons.ios_share_rounded,
            onPressed: () {
              Share.share(
                eventLink ?? '',
              );
            },
          ),
        ),
      ],
    );
  }
}

openLumaDetailsDialog() {
  Get.dialog(
    const LumaDetailsDialog(),
  );
}
