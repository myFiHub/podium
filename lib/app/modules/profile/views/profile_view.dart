import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/getContract.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/modules/global/widgets/loading_widget.dart';
import 'package:podium/app/modules/outpostDetail/widgets/usersList.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/providers/api/podium/models/follow/follower.dart';
import 'package:podium/root.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/utils/truncate.dart';
import 'package:podium/widgets/button/button.dart';

import '../controllers/profile_controller.dart';

/// Shows a dialog with options for managing podium passes
void showPodiumPassOptionsDialog(
  int numberOfPasses,
  ProfileController controller,
) {
  Get.dialog(
    AlertDialog(
      backgroundColor: ColorName.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        'Podium Pass Options',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You already have $numberOfPasses podium pass${numberOfPasses > 1 ? 'es' : ''}.',
            style: const TextStyle(fontSize: 16),
          ),
          space16,
          const Text(
            'What would you like to do?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Button(
            onPressed: () {
              Get.close();
              controller.buyPodiumPass();
            },
            type: ButtonType.gradient,
            child: const Text(
              'Buy Another Pass',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            blockButton: true,
          ),
        ),
        space12, // Add spacing between buttons
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Button(
            onPressed: () {
              Get.close();
              controller.sellPodiumPass();
            },
            type: ButtonType.outline,
            borderSide: const BorderSide(color: Colors.red),
            textColor: Colors.red,
            child: const Text(
              'Sell 1 Pass',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            blockButton: true,
          ),
        ),
        space12, // Add spacing between buttons
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Button(
            onPressed: () => Get.close(),
            type: ButtonType.transparent,
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 16),
            ),
            blockButton: true,
          ),
        ),
        space8,
      ],
    ),
  );
}

class ProfileView extends GetView<ProfileController> {
  const ProfileView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      child: Scaffold(
        body: Container(
          padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
          width: double.infinity,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _ProfileHeader(),
              space5,
              _Statistics(),
              space5,
              _SocialStats(),
              space5,
            ],
          ),
        ),
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
        return const SizedBox(
          height: 150,
          width: double.infinity,
          child: Center(
            child: LoadingWidget(),
          ),
        );
      }

      String avatar = user.image ?? '';
      if (avatar == defaultAvatar) {
        avatar = avatarPlaceHolder(user.name ?? '');
      }

      // Get wallet address from user object
      final walletAddress = user.aptos_address!;
      final shortWalletAddress = truncate(walletAddress, length: 18);

      final followedByMe = user.followed_by_me ?? false;

      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Image
                Hero(
                  tag: '${_profileHeroTagPrefix}${user.uuid}',
                  child: Img(
                    src: avatar,
                    alt: user.name ?? '',
                    size: 90,
                  ),
                ),
                space16,
                // Profile info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        user.name ?? '',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      space5,
                      // Wallet address with copy button
                      Row(
                        children: [
                          Text(
                            shortWalletAddress,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.copy,
                                size: 16, color: Colors.grey),
                            onPressed: () {
                              // Copy wallet address
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            space16,
            // Action buttons
            Row(
              children: [
                // Buy Ticket Button
                Expanded(
                  flex: 2,
                  child: _TicketButton(),
                ),
                space8,
                // Follow Button
                Expanded(
                  flex: 1,
                  child: FollowButton(
                    uuid: user.uuid,
                    followed_by_me: followedByMe,
                    fullWidth: true,
                    onFollowStatusChanged: () {
                      controller.getUserInfo();
                      controller.getFollowers(silent: true);
                      controller.getFollowings(silent: true);
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

class _TicketButton extends GetWidget<ProfileController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isGettingPrice = controller.isGettingTicketPrice.value;
      final isBuyingPodiumPass = controller.isBuyingPodiumPass.value;
      final isSellingPodiumPass = controller.isSellingPodiumPass.value;
      final podiumPassPrice = controller.podiumPassPrice.value;
      final isGettingPodiumPassPrice = controller.loadingPodiumPassPrice.value;
      final numberOfBoughtTicketsByMe =
          controller.mySharesOfPodiumPassFromThisUser.value;

      return Button(
        loading: isGettingPrice || isBuyingPodiumPass || isSellingPodiumPass,
        onPressed: (isGettingPrice || isBuyingPodiumPass || isSellingPodiumPass)
            ? null
            : () {
                if (numberOfBoughtTicketsByMe > 0) {
                  // Show confirmation dialog when user already has a pass
                  showPodiumPassOptionsDialog(
                      numberOfBoughtTicketsByMe, controller);
                } else {
                  // Original functionality for users without a pass
                  controller.buyPodiumPass();
                }
              },
        type: ButtonType.gradient,
        blockButton: true,
        child: _TicketButtonContent(
          numberOfPasses: numberOfBoughtTicketsByMe,
          podiumPassPrice: podiumPassPrice,
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
    required this.podiumPassPrice,
    required this.isLoading,
  }) : super(key: key);

  final int numberOfPasses;
  final double podiumPassPrice;
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Img(
                src: chainInfoByChainId(movementAptosNetwork.chainId)
                        .chainIcon ??
                    Assets.images.movementLogo.path,
                size: 20),
            space8,
            Flexible(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
                        text: " ${podiumPassPrice.toString()} MOV",
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: LoadingWidget(),
              ),
          ],
        ),
        if (numberOfPasses > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.yellow,
                ),
                children: [
                  const TextSpan(text: "You own "),
                  TextSpan(
                    text: numberOfPasses.toString(),
                    style: const TextStyle(color: Colors.red),
                  ),
                  TextSpan(text: " pass${numberOfPasses > 1 ? 'es' : ''}"),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A component that displays the social statistics for a user profile
/// including followers and following counts in a tab layout
class _SocialStats extends GetWidget<ProfileController> {
  const _SocialStats();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.userInfo.value;
      if (user == null) {
        return const SizedBox(height: 80);
      }

      // Get the counts from the controller

      return Expanded(
        child: DefaultTabController(
          length: 2,
          initialIndex: 0, // Start with Followers tab
          child: Column(
            children: [
              TabBar(
                indicatorColor: Colors.cyan,
                indicatorWeight: 4,
                labelColor: Colors.cyan,
                unselectedLabelColor: Colors.white,
                tabs: [
                  Obx(() {
                    final followersCount = controller.followers.value.length;
                    final appendix =
                        followersCount > 0 ? ' ($followersCount)' : '';
                    return Tab(text: 'Followers$appendix');
                  }),
                  Obx(() {
                    final followingCount = controller.followings.value.length;
                    final appendix =
                        followingCount > 0 ? ' ($followingCount)' : '';
                    return Tab(text: 'Following$appendix');
                  }),
                ],
              ),
              const Expanded(
                child: TabBarView(
                  physics: NeverScrollableScrollPhysics(), // Prevent swiping
                  children: [
                    // Followers tab content
                    FollowersTab(),

                    // Following tab content
                    FollowingTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class FollowersTab extends GetWidget<ProfileController> {
  const FollowersTab();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isGettingFollowers.value) {
        return const Center(child: LoadingWidget());
      }

      final followers = controller.followers.value;
      if (followers.isEmpty) {
        return const Center(
          child: Text(
            'No followers yet',
            style: TextStyle(color: Colors.white70),
          ),
        );
      }

      return ListView.builder(
        itemCount: followers.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          return UserListItem(user: followers[index]);
        },
      );
    });
  }
}

class FollowingTab extends GetWidget<ProfileController> {
  const FollowingTab();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isGettingFollowings.value) {
        return const Center(child: LoadingWidget());
      }

      final followings = controller.followings.value;
      if (followings.isEmpty) {
        return const Center(
          child: Text(
            'Not following anyone yet',
            style: TextStyle(color: Colors.white70),
          ),
        );
      }

      return ListView.builder(
        itemCount: followings.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          return UserListItem(user: followings[index]);
        },
      );
    });
  }
}

/// A single user item for followers/following lists
class UserListItem extends StatelessWidget {
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // User avatar
          Img(
            src: avatar == defaultAvatar ? avatarPlaceHolder(name) : avatar,
            alt: name,
            size: 40,
          ),
          const SizedBox(width: 12),
          // User name
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Follow button
          if (uuid != myId)
            SizedBox(
              height: 32,
              child: FollowButton(
                uuid: uuid,
                followed_by_me: followedByMe,
                onFollowStatusChanged: () {
                  final profileController = Get.find<ProfileController>();
                  profileController.getFollowers(silent: true);
                  profileController.getFollowings(silent: true);
                },
              ),
            )
          else
            const SizedBox(
              height: 32,
              child: Text(
                'You',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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
      final loading = controller.isGettingPayments.value;
      if (loading) {
        return const SizedBox();
      }
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'Cheers received',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      payments.numberOfCheersReceived.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      'Boos received',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      payments.numberOfBoosReceived.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            space10,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'Cheers sent',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      payments.numberOfCheersSent.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      'Boos sent',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      payments.numberOfBoosSent.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _BuyArenaTicketButton extends GetWidget<ProfileController> {
  const _BuyArenaTicketButton();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.userInfo.value;
      final isGettingPrice = controller.isGettingTicketPrice.value;
      final isBuyingArenaTicket = controller.isBuyingArenaTicket.value;
      final arenaTicketPrice = controller.arenaTicketPrice.value;
      final isGettingArenaPrice = controller.loadingArenaPrice.value;
      final numberOfBoughtTicketsByMe =
          controller.mySharesOfArenaFromThisUser.value;
      if (user == null) {
        return Container();
      }
      return Button(
        loading: isGettingPrice || isBuyingArenaTicket,
        onPressed: (isGettingPrice || isBuyingArenaTicket)
            ? null
            : () {
                controller.buyArenaTicket();
              },
        type: ButtonType.gradient,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Text(
                  'Buy Arena ticket ${arenaTicketPrice.toString()} ${chainInfoByChainId(avalancheChainId).currency}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isGettingArenaPrice)
                  const SizedBox(
                    width: 10,
                    height: 10,
                    child: LoadingWidget(
                      size: 10,
                    ),
                  )
                else
                  const SizedBox(width: 10, height: 10),
              ],
            ),
            if (numberOfBoughtTicketsByMe > 0)
              RichText(
                text: TextSpan(
                  text: 'owned ',
                  style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(
                      text: '$numberOfBoughtTicketsByMe',
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    const TextSpan(
                      text: ' Arena tickets',
                      style: TextStyle(
                        color: Colors.yellow,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        blockButton: true,
        icon: Img(
            src: chainInfoByChainId(avalancheChainId).chainIcon ??
                Assets.images.movementLogo.path,
            size: 20),
      );
    });
  }
}

class _BuyFriendTechTicket extends GetWidget<ProfileController> {
  const _BuyFriendTechTicket({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.userInfo.value;
      final isFriendTechActive = controller.isFriendTechActive.value;
      final isGettingPrice = controller.isGettingTicketPrice.value;
      final friendTechPrice = controller.friendTechPrice.value;
      final isGettingFriendTechPrice = controller.loadingFriendTechPrice.value;
      final isBuyingFriendTechTicket =
          controller.isBuyingFriendTechTicket.value;
      final numberOfBoughtTicketsByMe =
          controller.mySharesOfFriendTechFromThisUser.value;
      if (user == null) {
        return Container();
      }
      return Button(
        blockButton: true,
        icon: Img(
          src: chainInfoByChainId(baseChainId).chainIcon ??
              Assets.images.movementLogo.path,
          size: 20,
        ),
        loading: isGettingPrice || isBuyingFriendTechTicket,
        onPressed:
            (!isFriendTechActive || isGettingPrice || isBuyingFriendTechTicket)
                ? null
                : () {
                    controller.buyFriendTechTicket();
                  },
        type: ButtonType.gradient,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            !isFriendTechActive
                ? const Text(
                    'Friendtech address is not active',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.red,
                    ),
                  )
                : Row(
                    children: [
                      Text(
                        'Buy Friendtech share ${friendTechPrice.toString()} ${chainInfoByChainId(baseChainId).currency}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (isGettingFriendTechPrice)
                        const SizedBox(
                          width: 10,
                          height: 10,
                          child: LoadingWidget(
                            size: 10,
                          ),
                        )
                      else
                        const SizedBox(width: 10, height: 10),
                    ],
                  ),
            if (numberOfBoughtTicketsByMe > 0)
              RichText(
                text: TextSpan(
                  text: 'owned ',
                  style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(
                      text: '$numberOfBoughtTicketsByMe',
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    const TextSpan(
                      text: ' Friendtech share',
                      style: TextStyle(
                        color: Colors.yellow,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }
}
