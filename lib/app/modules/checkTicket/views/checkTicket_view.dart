import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/checkTicket/controllers/checkTicket_controller.dart';
import 'package:podium/app/modules/createOutpost/outpost_types.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/modules/global/widgets/loading_widget.dart';
import 'package:podium/utils/truncate.dart';
import 'package:podium/widgets/ui/app_ui.dart';

class CheckTicketView extends StatelessWidget {
  const CheckTicketView({super.key, required this.controller});

  final CheckticketController controller;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(controller: controller),
              const SizedBox(height: 14),
              Expanded(
                child: Obx(() {
                  if (controller.loadingUsers.value) {
                    return const Center(child: LoadingWidget());
                  }
                  final sellers =
                      controller.allUsersToBuyTicketFrom.value.values.toList();
                  return Scrollbar(
                    child: ListView.separated(
                      itemCount: sellers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _SellerTile(
                        controller: controller,
                        key: ValueKey(sellers[index].userInfo.uuid),
                        seller: sellers[index],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),
              _EnterButton(controller: controller),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final CheckticketController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 4, top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tickets', style: AppText.title),
                const SizedBox(height: 4),
                Text(_rule, style: AppText.caption),
                const SizedBox(height: 10),
                Obx(() {
                  controller.allUsersToBuyTicketFrom.value;
                  final access = controller.checkAccess();
                  return Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _StatusPill(
                        label: 'Enter',
                        icon: Icons.login_rounded,
                        unlocked: access.canEnter,
                      ),
                      _StatusPill(
                        label: 'Speak',
                        icon: Icons.mic_rounded,
                        unlocked: access.canSpeak,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
        AppIconButton(
          icon: Icons.close_rounded,
          tooltip: 'Close',
          size: 36,
          onTap: Get.close,
        ),
      ],
    );
  }

  String get _rule {
    final enter = controller.isAccessBuyableByTicket;
    final speak = controller.isSpeakBuyableByTicket;
    if (enter && speak) {
      return 'One ticket from anyone below is enough. '
          'Each one says whether it lets you enter, speak, or both.';
    }
    if (enter) return 'Get one ticket from anyone below to enter.';
    return 'Get one ticket from anyone below to speak.';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.icon,
    required this.unlocked,
  });

  final String label;
  final IconData icon;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return AppPill(
      label: unlocked ? '$label unlocked' : '$label locked',
      icon: unlocked ? icon : Icons.lock_outline_rounded,
      color: unlocked ? AppColors.success : AppColors.textMuted,
    );
  }
}

class _SellerTile extends StatelessWidget {
  const _SellerTile({
    super.key,
    required this.controller,
    required this.seller,
  });

  final CheckticketController controller;
  final TicketSeller seller;

  @override
  Widget build(BuildContext context) {
    final user = seller.userInfo;
    final usesAptos =
        seller.accessTicketType == BuyableTicketTypes.onlyPodiumPassHolders ||
            seller.speakTicketType == BuyableTicketTypes.onlyPodiumPassHolders;
    final address = usesAptos ? user.aptos_address ?? '' : seller.address;
    return AppCard(
      radius: AppRadius.md,
      color: AppColors.fill,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Img(
            src: user.image ?? '',
            size: 40,
            alt: user.name,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.cardTitle,
                ),
                const SizedBox(height: 2),
                Text(
                  truncate(address, length: 16),
                  maxLines: 1,
                  style: AppText.caption,
                ),
                const SizedBox(height: 8),
                ..._offers(),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _BuyAction(controller: controller, seller: seller),
        ],
      ),
    );
  }

  /// One line per ticket: what it unlocks and what it costs.
  List<Widget> _offers() {
    if (seller.checking) {
      return [Text('Checking price…', style: AppText.caption)];
    }
    if (seller.hasSeparateTickets) {
      return [
        _Offer(
          unlocks: 'Enter',
          price: seller.accessPriceFullString,
          owned: seller.boughtTicketToAccess,
        ),
        const SizedBox(height: 6),
        _Offer(
          unlocks: 'Speak',
          price: seller.speakPriceFullString,
          owned: seller.boughtTicketToSpeak,
        ),
      ];
    }
    final unlocks = seller.oneTicketForBoth
        ? 'Enter + speak'
        : seller.grantsAccess
            ? 'Enter'
            : 'Speak';
    return [
      _Offer(
        unlocks: unlocks,
        price: seller.accessPriceFullString ?? seller.speakPriceFullString,
        owned: seller.alreadyBoughtRequiredTickets,
      ),
    ];
  }
}

class _Offer extends StatelessWidget {
  const _Offer({
    required this.unlocks,
    required this.price,
    required this.owned,
  });

  final String unlocks;
  final String? price;
  final bool owned;

  @override
  Widget build(BuildContext context) {
    final price = this.price;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AppPill(
          label: unlocks,
          icon: unlocks == 'Speak' ? Icons.mic_rounded : Icons.login_rounded,
          color: owned ? AppColors.success : AppColors.primary,
        ),
        if (owned)
          Text('You hold this ticket', style: AppText.caption)
        else if (price != null)
          Text(
            '1 ticket · $price',
            style: AppText.caption.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _BuyAction extends StatelessWidget {
  const _BuyAction({required this.controller, required this.seller});

  final CheckticketController controller;

  final TicketSeller seller;

  @override
  Widget build(BuildContext context) {
    if (seller.checking || seller.buying) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Center(child: LoadingWidget(size: 20)),
      );
    }
    if (seller.alreadyBoughtRequiredTickets) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.success.withAlpha(30),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check_rounded, color: AppColors.success, size: 20),
      );
    }
    return FilledButton(
      onPressed: () => controller.buyTicket(ticketSeller: seller),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.success,
        foregroundColor: AppColors.onColor(AppColors.success),
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      child: const Text('Buy'),
    );
  }
}

class _EnterButton extends StatelessWidget {
  const _EnterButton({required this.controller});

  final CheckticketController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      controller.allUsersToBuyTicketFrom.value;
      final access = controller.checkAccess();

      if (!access.canEnter) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Notice(
              icon: Icons.confirmation_number_outlined,
              color: AppColors.danger,
              text: 'Buy one ticket that unlocks Enter to join this Outpost.',
            ),
            const SizedBox(height: 10),
            const AppPrimaryButton(
              label: 'Enter',
              icon: Icons.lock_outline_rounded,
              onPressed: null,
            ),
          ],
        );
      }

      final listenerOnly = !access.canSpeak && controller.canStillBuySpeak;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (listenerOnly) ...[
            _Notice(
              icon: Icons.mic_off_rounded,
              color: AppColors.accent,
              text: "You'll join as a listener. "
                  'Buy one ticket that unlocks Speak to talk.',
            ),
            const SizedBox(height: 10),
          ],
          AppPrimaryButton(
            icon:
                access.canSpeak ? Icons.mic_rounded : Icons.headphones_rounded,
            label: access.canSpeak ? 'Enter and speak' : 'Enter as listener',
            onPressed: () => Navigator.pop(
              context,
              OutpostAccesses(canEnter: true, canSpeak: access.canSpeak),
            ),
          ),
        ],
      );
    });
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: color, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
