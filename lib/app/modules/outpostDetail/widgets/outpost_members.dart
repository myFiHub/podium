import '../controllers/outpost_detail_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/widgets/img.dart';
import 'package:podium/app/modules/global/widgets/loading_widget.dart';
import 'package:podium/app/modules/outpostDetail/widgets/usersList.dart';
import 'package:podium/providers/api/podium/models/outposts/liveData.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/ui/app_ui.dart';

class MembersList extends GetView<OutpostDetailController> {
  const MembersList({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // A local copy: mutating the observable list while building would
      // notify listeners mid-frame.
      final members = [...controller.membersList.value];
      if (!members.any((element) => element.uuid == myId)) {
        members.insert(
          0,
          LiveMember(
              address: myUser.address,
              can_speak: true,
              image: myUser.image!,
              name: myUser.name!,
              uuid: myUser.uuid,
              aptos_address: myUser.aptos_address!),
        );
      }

      if (members.isEmpty) {
        return const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: LoadingWidget()),
          ),
        );
      }

      return SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: AppSectionHeader(
              title: 'Members',
              count: members.length,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.builder(
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                return UserListTile(
                  key: Key(member.uuid),
                  uuid: member.uuid,
                  name: member.name,
                  image: member.image,
                  followed_by_me: member.followed_by_me,
                  onRequestUpdate: () {
                    controller.updatedFollowDataForMember(member.uuid);
                  },
                );
              },
            ),
          ),
        ],
      );
    });
  }
}

class UserInvitationBottomSheetContent
    extends GetView<OutpostDetailController> {
  final bool canInviteToSpeak;
  const UserInvitationBottomSheetContent({
    super.key,
    required this.canInviteToSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.65,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Invite users', style: AppText.title),
                        const SizedBox(height: 2),
                        Text(
                          'Find people and invite them in',
                          style: AppText.caption,
                        ),
                      ],
                    ),
                  ),
                  AppIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Close',
                    size: 36,
                    onTap: () {
                      Get.close();
                      controller.listOfSearchedUsersToInvite.value = [];
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                autofocus: true,
                onChanged: (value) {
                  controller.searchUsers(value);
                },
                decoration: const InputDecoration(
                  hintText: 'Enter User\'s Name',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                final users = controller.listOfSearchedUsersToInvite.value;
                final loadingInviteId = controller.loadingInviteId.value;
                final liveInvitedMembers = controller.liveInvitedMembers.value;
                if (users.isEmpty) {
                  return const SingleChildScrollView(
                    child: AppEmptyState(
                      icon: Icons.person_search_rounded,
                      title: 'Search for people',
                      message: 'Type a name to find users to invite',
                      compact: true,
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final userInInvitedList = liveInvitedMembers[user.uuid];
                    final invitedToSpeak = userInInvitedList?.can_speak;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.fill,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Img(
                            src: user.image ?? '',
                            size: 36,
                            alt: user.name,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(18)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              user.name ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: invitedToSpeak == null
                                    ? ColorName.white
                                    : ColorName.greyText,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (invitedToSpeak != null)
                            AppPill(
                              label:
                                  'Invited ${invitedToSpeak ? 'to speak' : 'to listen'}',
                              color: invitedToSpeak
                                  ? AppColors.success
                                  : AppColors.primary,
                              icon: Icons.check_rounded,
                            )
                          else ...[
                            if (canInviteToSpeak) ...[
                              _InviteChipButton(
                                label: 'Speak',
                                tooltip: 'Invite to speak',
                                icon: Icons.mic_rounded,
                                color: AppColors.success,
                                loading: loadingInviteId == '${user.uuid}true',
                                onPressed: () {
                                  controller.inviteUserToJoinThisOutpost(
                                    userId: user.uuid,
                                    inviteToSpeak: true,
                                  );
                                },
                              ),
                              const SizedBox(width: 6),
                            ],
                            _InviteChipButton(
                              label: 'Listen',
                              tooltip: 'Invite to listen',
                              icon: Icons.headphones_rounded,
                              color: AppColors.primary,
                              loading: loadingInviteId == '${user.uuid}false',
                              onPressed: () {
                                controller.inviteUserToJoinThisOutpost(
                                  userId: user.uuid,
                                  inviteToSpeak: false,
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteChipButton extends StatelessWidget {
  final String label;
  final String tooltip;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onPressed;
  const _InviteChipButton({
    required this.label,
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          minimumSize: const Size(0, 34),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          foregroundColor: color,
          backgroundColor: color.withAlpha(24),
          side: BorderSide(color: color.withAlpha(90)),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        child: loading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14),
                  const SizedBox(width: 4),
                  Text(label),
                ],
              ),
      ),
    );
  }
}
