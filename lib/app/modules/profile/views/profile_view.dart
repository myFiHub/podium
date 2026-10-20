import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/modules/global/widgets/loading_widget.dart';
import 'package:podium/app/modules/global/widgets/outpostsList.dart';
import 'package:podium/app/modules/outpostDetail/widgets/usersList.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/providers/api/podium/models/follow/follower.dart';
import 'package:podium/root.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/format_amount.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/utils/truncate.dart';
import 'package:podium/widgets/ui/app_ui.dart';
import 'package:shimmer/shimmer.dart';

import '../controllers/profile_controller.dart';

const _passCurrency = 'MOV';

/// Shows a sheet with options for managing podium passes
void showPodiumPassOptionsDialog(
  int numberOfPasses,
  ProfileController controller,
) {
  final buyPrice = controller.podiumPassBuyPrice.value;
  final sellPrice = controller.podiumPassSellPrice.value;
  showAppSheet(
    AppSheet(
      title: 'Podium Pass',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(20),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.accent.withAlpha(60)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.confirmation_number_outlined,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You already have $numberOfPasses podium pass${numberOfPasses > 1 ? 'es' : ''}.',
                        style: AppText.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'What would you like to do?',
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppPrimaryButton(
            onPressed: () {
              Get.closeOverlay();
              controller.buyPodiumPass();
            },
            icon: Icons.add_rounded,
            label: buyPrice > 0
                ? 'Buy Another Pass: ${formatAmount(buyPrice, _passCurrency)}'
                : 'Buy Another Pass',
          ),
          const SizedBox(height: 10),
          AppSecondaryButton(
            onPressed: () {
              Get.closeOverlay();
              controller.sellPodiumPass();
            },
            color: AppColors.danger,
            icon: Icons.sell_outlined,
            label: sellPrice > 0
                ? 'Sell 1 Pass: ${formatAmount(sellPrice, _passCurrency)}'
                : 'Sell 1 Pass',
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Get.closeOverlay(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textMuted,
              minimumSize: const Size.fromHeight(46),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ),
  );
}

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});
  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      child: Scaffold(
        body: Column(
          children: [
            const AppPageHeader(
              title: 'Profile',
              showBack: true,
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            ),
            Expanded(
              child: DefaultTabController(
                length: 3,
                initialIndex: 0,
                child: RefreshIndicator(
                  onRefresh: controller.refreshAll,
                  // The lists sit inside the tab view and the nested scroll
                  // view, so their notifications arrive a few levels deep.
                  notificationPredicate: (notification) =>
                      notification.metrics.axis == Axis.vertical,
                  child: NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) => [
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _ProfileHeader(),
                              _LiveNowCard(),
                              SizedBox(height: 12),
                              _Statistics(),
                            ],
                          ),
                        ),
                      ),
                      SliverOverlapAbsorber(
                        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                          context,
                        ),
                        sliver: const SliverPersistentHeader(
                          pinned: true,
                          delegate: _TabBarDelegate(),
                        ),
                      ),
                    ],
                    body: const TabBarView(
                      children: [
                        PassHoldersTab(),
                        FollowersTab(),
                        FollowingTab(),
                      ],
                    ),
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

class _AvatarRing extends StatelessWidget {
  final Widget child;
  const _AvatarRing({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withAlpha(60)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(45),
            blurRadius: 22,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ColorName.cardBackground,
        ),
        child: child,
      ),
    );
  }
}

class _ProfileHeader extends GetWidget<ProfileController> {
  const _ProfileHeader();

  static const _profileHeroTagPrefix = 'profile_avatar_';

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.userInfo.value;
      if (user == null) return const SizedBox.shrink();

      String avatar = user.image ?? '';
      if (avatar == defaultAvatar) {
        avatar = avatarPlaceHolder(user.name ?? '');
      }

      final walletAddress = user.aptos_address ?? '';
      final followedByMe = user.followed_by_me ?? false;
      final followsMe = controller.followsMe;
      final hasPassWallet = controller.hasPassWallet;

      return AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _AvatarRing(
                  child: Hero(
                    tag: '$_profileHeroTagPrefix${user.uuid}',
                    child: Img(
                      src: avatar,
                      alt: user.name ?? '',
                      size: 72,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.title.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (followsMe) ...[
                        const SizedBox(height: 6),
                        AppPill(
                          label: 'Follows you',
                          icon: Icons.person_rounded,
                          color: AppColors.primary,
                        ),
                      ],
                      if (walletAddress.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _WalletChip(address: walletAddress),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _SocialCounts(),
            const _FollowedByLine(),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (hasPassWallet) ...[
                  const Expanded(
                    flex: 2,
                    child: _TicketButton(),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  flex: 1,
                  child: FollowButton(
                    uuid: user.uuid,
                    followed_by_me: followedByMe,
                    fullWidth: true,
                    onFollowStatusChanged: () {
                      controller.updateMyFollowState(user);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _WalletChip extends StatelessWidget {
  const _WalletChip({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fill,
      shape: StadiumBorder(
        side: BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Clipboard.setData(ClipboardData(text: address));
          Toast.info(message: 'Wallet address copied to clipboard');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 13,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  truncate(address, length: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.copy_rounded,
                size: 13,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialCounts extends GetWidget<ProfileController> {
  const _SocialCounts();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.userInfo.value;
      final holders = controller.isGettingPassBuyers.value
          ? null
          : controller.podiumPassBuyers.value.length;
      final followers = controller.isGettingFollowers.value
          ? user?.followers_count
          : controller.followers.value.length;
      final followings = controller.isGettingFollowings.value
          ? user?.followings_count
          : controller.followings.value.length;
      final divider = VerticalDivider(
        width: 1,
        thickness: 1,
        color: AppColors.border,
      );
      return Container(
        decoration: BoxDecoration(
          color: ColorName.white.withAlpha(8),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _CountCell(value: holders, label: 'Holders', tab: 0),
              ),
              divider,
              Expanded(
                child: _CountCell(value: followers, label: 'Followers', tab: 1),
              ),
              divider,
              Expanded(
                child: _CountCell(
                  value: followings,
                  label: 'Following',
                  tab: 2,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// A count that jumps to its tab when tapped; null while it's loading.
class _CountCell extends StatelessWidget {
  final int? value;
  final String label;
  final int tab;
  const _CountCell({
    required this.value,
    required this.label,
    required this.tab,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => DefaultTabController.of(context).animateTo(tab),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value?.toString() ?? '–',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ColorName.white,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption,
            ),
          ],
        ),
      ),
    );
  }
}

/// "Followed by A, B and 3 others you follow", linking to the Followers tab.
class _FollowedByLine extends GetWidget<ProfileController> {
  const _FollowedByLine();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final mutual = controller.followersIFollow;
      if (mutual.isEmpty) return const SizedBox.shrink();
      final names = [for (final f in mutual.take(2)) f.name];
      final others = mutual.length - names.length;
      final text = StringBuffer('Followed by ${names.join(', ')}');
      if (others > 0) text.write(' and $others other${others > 1 ? 's' : ''}');
      text.write(' you follow');
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => DefaultTabController.of(context).animateTo(1),
          child: Row(
            children: [
              _AvatarStack(people: mutual.take(3).toList()),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text.toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.people});

  final List<FollowerModel> people;

  static const _size = 22.0;
  static const _overlap = 14.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size + _overlap * (people.length - 1),
      height: _size,
      child: Stack(
        children: [
          for (final (i, p) in people.indexed)
            Positioned(
              left: _overlap * i,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
                child: Img(
                  src: p.image == defaultAvatar
                      ? avatarPlaceHolder(p.name)
                      : p.image,
                  alt: p.name,
                  size: _size - 3,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Shown while the user is hosting a live outpost.
class _LiveNowCard extends GetWidget<ProfileController> {
  const _LiveNowCard();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final outpost = controller.liveOutpost.value;
      if (outpost == null) return const SizedBox.shrink();
      final live = AppColors.live;
      final listening = outpost.online_users_count ?? 0;
      return AppCard(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        borderGradient: LinearGradient(
          colors: [live.withAlpha(140), AppColors.magenta.withAlpha(60)],
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [live.withAlpha(26), AppColors.surfaceGlass],
        ),
        onTap: () => openOutpost(outpost),
        child: Row(
          children: [
            Img(
              src: Uri.parse(outpost.image).isAbsolute ? outpost.image : '',
              alt: outpost.name,
              ifEmpty: Assets.images.logo.path,
              size: 52,
              borderRadius: const BorderRadius.all(
                Radius.circular(AppRadius.sm),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppPill(
                    label: listening > 0
                        ? 'Live now · $listening listening'
                        : 'Live now',
                    icon: Icons.podcasts_rounded,
                    color: live,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    outpost.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.cardTitle.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      );
    });
  }
}

class _TicketButton extends GetWidget<ProfileController> {
  const _TicketButton();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isGettingPrice = controller.isGettingTicketPrice.value;
      final isBuyingPodiumPass = controller.isBuyingPodiumPass.value;
      final isSellingPodiumPass = controller.isSellingPodiumPass.value;
      final podiumPassBuyPrice = controller.podiumPassBuyPrice.value;
      final isGettingPodiumPassPrice = controller.loadingPodiumPassPrice.value;
      final numberOfBoughtTicketsByMe =
          controller.mySharesOfPodiumPassFromThisUser.value;
      final busy = isGettingPrice || isBuyingPodiumPass || isSellingPodiumPass;

      return FilledButton(
        onPressed: busy
            ? null
            : () {
                if (numberOfBoughtTicketsByMe > 0) {
                  showPodiumPassOptionsDialog(
                      numberOfBoughtTicketsByMe, controller);
                } else {
                  controller.buyPodiumPass();
                }
              },
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.primary.withAlpha(150),
          disabledForegroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: busy
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.onPrimary,
                ),
              )
            : _TicketButtonContent(
                numberOfPasses: numberOfBoughtTicketsByMe,
                podiumPassBuyPrice: podiumPassBuyPrice,
                isLoading: isGettingPodiumPassPrice,
              ),
      );
    });
  }
}

class _TicketButtonContent extends StatelessWidget {
  const _TicketButtonContent({
    required this.numberOfPasses,
    required this.podiumPassBuyPrice,
    required this.isLoading,
  });

  final int numberOfPasses;
  final double podiumPassBuyPrice;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Img(
              src: Assets.images.movementIcon.path,
              size: 18,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                  ),
                  children: [
                    TextSpan(
                      text: numberOfPasses > 0
                          ? "Manage Podium Pass"
                          : "Buy Pass",
                    ),
                    if (numberOfPasses == 0 && podiumPassBuyPrice > 0)
                      TextSpan(
                        text:
                            " · ${formatAmount(podiumPassBuyPrice, _passCurrency)}",
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            if (isLoading)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: LoadingWidget(
                  size: 12,
                  color: AppColors.onPrimary,
                ),
              ),
          ],
        ),
        if (numberOfPasses > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              "You own $numberOfPasses pass${numberOfPasses > 1 ? 'es' : ''}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onPrimary.withAlpha(200),
              ),
            ),
          ),
      ],
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate();

  static const double _height = 64;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final overContent = shrinkOffset > 0 || overlapsContent;
    // Near-opaque instead of a backdrop blur, which would re-blur everything
    // underneath on every scroll frame.
    return Container(
      color: ColorName.pageBackground.withAlpha(overContent ? 240 : 0),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surfaceGlass,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: const TabBar(
          labelPadding: EdgeInsets.zero,
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStatePropertyAll(Colors.transparent),
          tabs: [
            Tab(text: 'Pass Holders', height: 36),
            Tab(text: 'Followers', height: 36),
            Tab(text: 'Following', height: 36),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

class _TabScroll extends StatelessWidget {
  final String storageKey;
  final Widget sliver;
  const _TabScroll({required this.storageKey, required this.sliver});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: PageStorageKey<String>(storageKey),
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        sliver,
      ],
    );
  }
}

class _TabMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  const _TabMessage({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: AppEmptyState(icon: icon, title: title, compact: true),
      ),
    );
  }
}

class _TabLoading extends StatelessWidget {
  const _TabLoading();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: _listPadding,
      sliver: SliverList.list(
        children: [
          for (var i = 0; i < 5; i++) const _PersonSkeleton(),
        ],
      ),
    );
  }
}

class _PersonSkeleton extends StatelessWidget {
  const _PersonSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      radius: AppRadius.md,
      child: Shimmer.fromColors(
        baseColor: ColorName.white.withAlpha(16),
        highlightColor: ColorName.white.withAlpha(40),
        child: const Row(
          children: [
            _Bone(width: 42, height: 42, radius: 21),
            SizedBox(width: 12),
            _Bone(width: 120, height: 12),
            Spacer(),
            _Bone(width: 84, height: 32, radius: 16),
          ],
        ),
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({required this.width, required this.height, this.radius = 6});

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ColorName.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

const _listPadding = EdgeInsets.fromLTRB(16, 4, 16, 24);

class PassHoldersTab extends GetWidget<ProfileController> {
  const PassHoldersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final passHolders = controller.podiumPassBuyers.value;
      final isLoading = controller.isGettingPassBuyers.value;
      return _TabScroll(
        storageKey: 'profile_pass_holders',
        sliver: isLoading
            ? const _TabLoading()
            : passHolders.isEmpty
                ? const _TabMessage(
                    icon: Icons.confirmation_number_outlined,
                    title: 'No pass holders yet',
                  )
                : SliverPadding(
                    padding: _listPadding,
                    sliver: SliverList.builder(
                      itemCount: passHolders.length,
                      itemBuilder: (context, index) {
                        final holder = passHolders[index];
                        return _PersonTile(
                          uuid: holder.uuid,
                          name: holder.name,
                          avatar: holder.image,
                          followedByMe: holder.followed_by_me,
                        );
                      },
                    ),
                  ),
      );
    });
  }
}

class FollowersTab extends GetWidget<ProfileController> {
  const FollowersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.isGettingFollowers.value;
      final followers = controller.followers.value;
      return _TabScroll(
        storageKey: 'profile_followers',
        sliver: loading
            ? const _TabLoading()
            : followers.isEmpty
                ? const _TabMessage(
                    icon: Icons.people_outline_rounded,
                    title: 'No followers yet',
                  )
                : SliverPadding(
                    padding: _listPadding,
                    sliver: SliverList.builder(
                      itemCount: followers.length,
                      itemBuilder: (context, index) =>
                          _PersonTile.follower(followers[index]),
                    ),
                  ),
      );
    });
  }
}

class FollowingTab extends GetWidget<ProfileController> {
  const FollowingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.isGettingFollowings.value;
      final followings = controller.followings.value;
      return _TabScroll(
        storageKey: 'profile_followings',
        sliver: loading
            ? const _TabLoading()
            : followings.isEmpty
                ? const _TabMessage(
                    icon: Icons.person_search_outlined,
                    title: 'Not following anyone yet',
                  )
                : SliverPadding(
                    padding: _listPadding,
                    sliver: SliverList.builder(
                      itemCount: followings.length,
                      itemBuilder: (context, index) =>
                          _PersonTile.follower(followings[index]),
                    ),
                  ),
      );
    });
  }
}

/// A person in any of the tabs: opens their profile and has a follow button.
class _PersonTile extends GetView<ProfileController> {
  const _PersonTile({
    required this.uuid,
    required this.name,
    required this.avatar,
    required this.followedByMe,
  });

  _PersonTile.follower(FollowerModel user)
      : uuid = user.uuid,
        name = user.name,
        avatar = user.image,
        followedByMe = user.followed_by_me;

  final String uuid;
  final String name;
  final String avatar;
  final bool followedByMe;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      radius: AppRadius.md,
      onTap: () => controller.openUserProfilePage(uuid: uuid),
      child: Row(
        children: [
          Img(
            src: avatar == defaultAvatar ? avatarPlaceHolder(name) : avatar,
            alt: name,
            size: 42,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.cardTitle.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          if (uuid == myId)
            AppPill(label: 'You', color: AppColors.success)
          else
            Obx(() {
              if (controller.loadingUserID.value == uuid) {
                return const SizedBox(
                  height: 32,
                  child: LoadingWidget(size: 16),
                );
              }
              return SizedBox(
                height: 32,
                child: FollowButton(
                  uuid: uuid,
                  followed_by_me: followedByMe,
                  onFollowStatusChanged: () =>
                      controller.setFollowedByMe(uuid, !followedByMe),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _Statistics extends GetWidget<ProfileController> {
  const _Statistics();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final payments = controller.payments.value;
      return AppCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _ActivityGroup(
                  title: 'Received',
                  cheers: payments.numberOfCheersReceived,
                  boos: payments.numberOfBoosReceived,
                ),
              ),
              VerticalDivider(
                width: 24,
                thickness: 1,
                color: AppColors.border,
              ),
              Expanded(
                child: _ActivityGroup(
                  title: 'Sent',
                  cheers: payments.numberOfCheersSent,
                  boos: payments.numberOfBoosSent,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _ActivityGroup extends StatelessWidget {
  final String title;
  final int cheers;
  final int boos;
  const _ActivityGroup({
    required this.title,
    required this.cheers,
    required this.boos,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, textAlign: TextAlign.center, style: AppText.label),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActivityCell(
                icon: Icons.celebration_rounded,
                color: AppColors.accent,
                value: cheers,
                label: 'Cheers',
              ),
            ),
            Expanded(
              child: _ActivityCell(
                icon: Icons.thumb_down_alt_rounded,
                color: AppColors.danger,
                value: boos,
                label: 'Boos',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActivityCell extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;
  final String label;
  const _ActivityCell({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withAlpha(28),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: ColorName.white,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.caption.copyWith(height: 1.2),
        ),
      ],
    );
  }
}
