import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/services/blocked_users_service.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/utils/truncate.dart';
import 'package:podium/widgets/ui/app_ui.dart';

class BlockedUsersSetting extends StatelessWidget {
  const BlockedUsersSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final blocks = Get.find<BlockedUsersService>()..ensureLoaded();
    return Obx(() {
      final count = blocks.blocked.length;
      return AppSettingsRow(
        icon: Icons.block_rounded,
        title: 'Blocked people',
        subtitle: !blocks.available.value
            ? 'Not available on this server yet'
            : count == 0
                ? "People you block can't message you in outposts"
                : count == 1
                    ? '1 person'
                    : '$count people',
        dimmed: !blocks.available.value,
        onTap: () {
          blocks.refresh();
          showAppSheet(const BlockedUsersSheet());
        },
      );
    });
  }
}

class BlockedUsersSheet extends StatelessWidget {
  const BlockedUsersSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final blocks = Get.find<BlockedUsersService>();
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: AppSheet.maxHeight(context, 0.75)),
      child: AppSheet(
        title: 'Blocked people',
        subtitle: "They can't message you, and their room chat is hidden",
        icon: Icons.block_rounded,
        iconColor: AppColors.danger,
        child: Obx(() {
          final users = blocks.blocked.values.toList()
            ..sort((a, b) => (b.blockedAt ?? DateTime(0))
                .compareTo(a.blockedAt ?? DateTime(0)));
          if (users.isEmpty) {
            return const AppEmptyState(
              compact: true,
              icon: Icons.verified_user_outlined,
              title: 'Nobody blocked',
              message: 'Block someone from their card in an outpost.',
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            itemCount: users.length,
            separatorBuilder: (_, __) => const AppRowDivider(indent: 56),
            itemBuilder: (context, index) {
              final user = users[index];
              final name = user.name?.isNotEmpty == true
                  ? user.name!
                  : truncate(user.address ?? user.uuid, length: 12);
              return ListTile(
                key: ValueKey(user.uuid),
                contentPadding: EdgeInsets.zero,
                leading: Img(
                  src: user.image ?? '',
                  alt: name,
                  size: 40,
                  borderRadius: BorderRadius.circular(40),
                ),
                title: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: TextButton(
                  onPressed: () => blocks.unblock(user.uuid),
                  child: const Text('Unblock'),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
