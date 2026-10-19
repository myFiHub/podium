import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/utils/getContract.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/modules/global/widgets/loading_widget.dart';
import 'package:podium/app/modules/myProfile/controllers/my_profile_controller.dart';
import 'package:podium/app/modules/records/controllers/records_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/ui/app_ui.dart';
import 'package:shimmer/shimmer.dart';

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int value;
  const _StatTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorName.white.withAlpha(8),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: ColorName.white,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class MyProfileStatistics extends GetWidget<MyProfileController> {
  const MyProfileStatistics({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final payments = controller.payments.value;
      final loading = controller.isGettingPayments.value;
      if (loading) {
        return const AppCard(
          child: SizedBox(
            height: 120,
            child: Center(child: LoadingWidget()),
          ),
        );
      }
      final incomeEntries = payments.income.entries.toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.celebration_rounded,
                        color: AppColors.accent,
                        label: 'Cheers received',
                        value: payments.numberOfCheersReceived,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.thumb_down_alt_rounded,
                        color: AppColors.danger,
                        label: 'Boos received',
                        value: payments.numberOfBoosReceived,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.celebration_outlined,
                        color: AppColors.accent,
                        label: 'Cheers sent',
                        value: payments.numberOfCheersSent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.thumb_down_alt_outlined,
                        color: AppColors.danger,
                        label: 'Boos sent',
                        value: payments.numberOfBoosSent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            child: AppSettingsRow(
              icon: Icons.graphic_eq_rounded,
              iconColor: AppColors.accent,
              title: 'Recorded Audios',
              subtitle: 'Listen back to your outpost recordings',
              onTap: () {
                final isRegistered = Get.isRegistered<RecordsController>();
                if (isRegistered) {
                  final recordsController = Get.find<RecordsController>();
                  recordsController.loadRecordings();
                }
                Navigate.to(
                  type: NavigationTypes.toNamed,
                  route: Routes.RECORDS,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    AppIconTile(
                      bordered: true,
                      icon: Icons.account_balance_wallet_outlined,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 14),
                    Text('Earned', style: AppText.cardTitle),
                  ],
                ),
                const SizedBox(height: 12),
                if (incomeEntries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text('Nothing yet', style: AppText.muted),
                  ),
                for (final e in incomeEntries) ...[
                  _IncomeRow(chainId: e.key, amount: e.value.toString()),
                  if (e.key != incomeEntries.last.key)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.border,
                    ),
                ],
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _IncomeRow extends StatelessWidget {
  final String chainId;
  final String amount;
  const _IncomeRow({required this.chainId, required this.amount});

  @override
  Widget build(BuildContext context) {
    final chainInfo = chainInfoByChainId(chainId);
    final currency = chainInfo.currency;
    final chainName = chainInfo.name;
    final chainIcon = chainInfo.chainIcon!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Img(
            src: chainIcon,
            size: 22,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              chainName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$amount $currency',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class PriceSkeleton extends StatelessWidget {
  const PriceSkeleton({super.key, 
    required this.price,
    required this.isLoading,
  });

  final String price;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return Text(
        price,
        textAlign: TextAlign.end,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: ColorName.white,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
    }

    return Shimmer.fromColors(
      baseColor: ColorName.white.withAlpha(20),
      highlightColor: ColorName.white.withAlpha(50),
      period: const Duration(milliseconds: 900),
      child: Container(
        width: 56,
        height: 14,
        decoration: BoxDecoration(
          color: ColorName.white.withAlpha(20),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
