import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/getContract.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/modules/global/widgets/loading_widget.dart';
import 'package:podium/app/modules/outpostDetail/widgets/usersList.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/providers/api/podium/models/follow/follower.dart';
import 'package:podium/root.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/truncate.dart';
import 'package:podium/widgets/ui/app_ui.dart';

import '../controllers/profile_controller.dart';

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
                const Icon(
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
                      const Text(
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
            label: 'Buy Another Pass: ${buyPrice.toString()} MOV',
          ),
          const SizedBox(height: 10),
          AppSecondaryButton(
            onPressed: () {
              Get.closeOverlay();
              controller.sellPodiumPass();
            },
            color: AppColors.danger,
            icon: Icons.sell_outlined,
            label: 'Sell 1 Pass: ${sellPrice.toString()} MOV',
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
  const ProfileView({Key? key}) : super(key: key);
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
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ProfileHeader(),
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
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      PassHoldersTab(),
                      FollowersTab(),
                      FollowingTab(),
                    ],
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
        decoration: const BoxDecoration(
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
      if (user == null) {
        return const AppCard(
          child: SizedBox(
            height: 150,
            width: double.infinity,
            child: Center(
              child: LoadingWidget(),
            ),
          ),
        );
      }

      String avatar = user.image ?? '';
      if (avatar == defaultAvatar) {
        avatar = avatarPlaceHolder(user.name ?? '');
      }

      final walletAddress = user.aptos_address!;
      final shortWalletAddress = truncate(walletAddress, length: 18);

      final followedByMe = user.followed_by_me ?? false;

      return AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _AvatarRing(
                  child: Hero(
                    tag: '${_profileHeroTagPrefix}${user.uuid}',
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
                      const SizedBox(height: 8),
                      Material(
                        color: AppColors.fill,
                        shape: const StadiumBorder(
                          side: BorderSide(color: AppColors.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: walletAddress));
                            Toast.info(
                              message: 'Wallet address copied to clipboard',
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 13,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    shortWalletAddress,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.caption,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.copy_rounded,
                                  size: 13,
                                  color: AppColors.textMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _SocialCounts(),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 2,
                  child: _TicketButton(),
                ),
                const SizedBox(width: 10),
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

class _SocialCounts extends GetWidget<ProfileController> {
  const _SocialCounts();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final holders = controller.podiumPassBuyers.value.length;
      final followers = controller.followers.value.length;
      final followings = controller.followings.value.length;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(child: _CountCell(value: holders, label: 'Holders')),
              const VerticalDivider(
                width: 1,
                thickness: 1,
                color: AppColors.border,
              ),
              Expanded(child: _CountCell(value: followers, label: 'Followers')),
              const VerticalDivider(
                width: 1,
                thickness: 1,
                color: AppColors.border,
              ),
              Expanded(
                child: _CountCell(value: followings, label: 'Following'),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _CountCell extends StatelessWidget {
  final int value;
  final String label;
  const _CountCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontFeatures: [FontFeature.tabularFigures()],
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
    );
  }
}

class _TicketButton extends GetWidget<ProfileController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isGettingPrice = controller.isGettingTicketPrice.value;
      final isBuyingPodiumPass = controller.isBuyingPodiumPass.value;
      final isSellingPodiumPass = controller.isSellingPodiumPass.value;
      final podiumPassBuyPrice = controller.podiumPassBuyPrice.value;
      final podiumPassSellPrice = controller.podiumPassSellPrice.value;
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
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withAlpha(150),
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : _TicketButtonContent(
                numberOfPasses: numberOfBoughtTicketsByMe,
                podiumPassBuyPrice: podiumPassBuyPrice,
                podiumPassSellPrice: podiumPassSellPrice,
                isLoading: isGettingPodiumPassPrice,
              ),
      );
    });
  }
}

class _TicketButtonContent extends StatelessWidget {
  const _TicketButtonContent({
    Key? key,
    required this.numberOfPasses,
    required this.podiumPassBuyPrice,
    required this.podiumPassSellPrice,
    required this.isLoading,
  }) : super(key: key);

  final int numberOfPasses;
  final double podiumPassBuyPrice;
  final double podiumPassSellPrice;
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
              src: chainInfoByChainId(movementAptosNetwork.chainId).chainIcon ??
                  Assets.images.movementLogo.path,
              size: 18,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  children: [
                    TextSpan(
                      text: numberOfPasses > 0
                          ? "Manage Podium Pass"
                          : "Buy Pass",
                    ),
                    if (numberOfPasses == 0)
                      TextSpan(
                        text: " ${podiumPassBuyPrice.toString()} MOV",
                        style: const TextStyle(color: AppColors.accent),
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: LoadingWidget(
                  size: 12,
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
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.accent.withAlpha(230),
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
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          color: ColorName.pageBackground.withAlpha(
            shrinkOffset > 0 || overlapsContent ? 170 : 0,
          ),
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
              tabs: [
                Tab(text: 'Pass Holders', height: 36),
                Tab(text: 'Followers', height: 36),
                Tab(text: 'Following', height: 36),
              ],
            ),
          ),
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
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: EdgeInsets.only(top: 32),
        child: Align(
          alignment: Alignment.topCenter,
          child: LoadingWidget(),
        ),
      ),
    );
  }
}

const _listPadding = EdgeInsets.fromLTRB(16, 4, 16, 24);

class FollowersTab extends GetWidget<ProfileController> {
  const FollowersTab();

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
                      itemBuilder: (context, index) {
                        return UserListItem(user: followers[index]);
                      },
                    ),
                  ),
      );
    });
  }
}

class _PersonRow extends StatelessWidget {
  final String name;
  final String avatar;
  final Widget trailing;
  final VoidCallback? onTap;
  const _PersonRow({
    required this.name,
    required this.avatar,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      radius: AppRadius.md,
      onTap: onTap,
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
          trailing,
        ],
      ),
    );
  }
}

class _YouPill extends StatelessWidget {
  const _YouPill();

  @override
  Widget build(BuildContext context) {
    return const AppPill(label: 'You', color: AppColors.success);
  }
}

class PassHoldersTab extends GetWidget<ProfileController> {
  const PassHoldersTab();

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
                        return _PersonRow(
                          name: holder.name,
                          avatar: holder.image,
                          trailing: holder.uuid != myId
                              ? SizedBox(
                                  height: 32,
                                  child: FollowButton(
                                    uuid: holder.uuid,
                                    followed_by_me: holder.followed_by_me,
                                    onFollowStatusChanged: () {
                                      controller.getPassBuyers();
                                    },
                                  ),
                                )
                              : const _YouPill(),
                        );
                      },
                    ),
                  ),
      );
    });
  }
}

class FollowingTab extends GetWidget<ProfileController> {
  const FollowingTab();

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
                      itemBuilder: (context, index) {
                        return UserListItem(user: followings[index]);
                      },
                    ),
                  ),
      );
    });
  }
}

/// A single user item for followers/following lists
class UserListItem extends GetView<ProfileController> {
  const UserListItem({
    Key? key,
    required this.user,
  }) : super(key: key);

  final FollowerModel user;

  @override
  Widget build(BuildContext context) {
    final String name = user.name;
    final String avatar = user.image;
    final String uuid = user.uuid;
    final bool followedByMe = user.followed_by_me;

    return _PersonRow(
      name: name,
      avatar: avatar,
      onTap: () {
        controller.openUserProfilePage(uuid: uuid);
      },
      trailing: uuid != myId
          ? Obx(
              () {
                final lodinguserId = controller.loadingUserID.value;
                if (lodinguserId == uuid) {
                  return const SizedBox(
                    height: 32,
                    child: LoadingWidget(
                      size: 16,
                    ),
                  );
                }
                return SizedBox(
                  height: 32,
                  child: FollowButton(
                    uuid: uuid,
                    followed_by_me: followedByMe,
                    onFollowStatusChanged: () {
                      controller.updateFollowState(user);
                    },
                  ),
                );
              },
            )
          : const _YouPill(),
    );
  }
}

class _Statistics extends GetWidget<ProfileController> {
  const _Statistics();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final payments = controller.payments.value;
      final loading = controller.isGettingPayments.value;
      if (loading) {
        return const SizedBox();
      }
      return AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: _ActivityCell(
                icon: Icons.celebration_rounded,
                color: AppColors.accent,
                value: payments.numberOfCheersReceived,
                label: 'Cheers received',
              ),
            ),
            Expanded(
              child: _ActivityCell(
                icon: Icons.thumb_down_alt_rounded,
                color: AppColors.danger,
                value: payments.numberOfBoosReceived,
                label: 'Boos received',
              ),
            ),
            Expanded(
              child: _ActivityCell(
                icon: Icons.celebration_outlined,
                color: AppColors.accent,
                value: payments.numberOfCheersSent,
                label: 'Cheers sent',
              ),
            ),
            Expanded(
              child: _ActivityCell(
                icon: Icons.thumb_down_alt_outlined,
                color: AppColors.danger,
                value: payments.numberOfBoosSent,
                label: 'Boos sent',
              ),
            ),
          ],
        ),
      );
    });
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
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.caption.copyWith(fontSize: 10, height: 1.2),
        ),
      ],
    );
  }
}
