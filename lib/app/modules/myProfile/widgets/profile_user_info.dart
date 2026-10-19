import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/loginType.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/utils/storage.dart';
import 'package:podium/widgets/ui/app_ui.dart';

class _AvatarRing extends StatelessWidget {
  final Widget child;
  const _AvatarRing({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withAlpha(60)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(50),
            blurRadius: 28,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ColorName.cardBackground,
        ),
        child: child,
      ),
    );
  }
}

class UserInfo extends GetView<GlobalController> {
  const UserInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final myUser = controller.myUserInfo.value;
      if (myUser == null) {
        return const SizedBox.shrink();
      }
      String identifier = myUser.login_type_identifier ?? '';
      final loginType = GetStorage().read(StorageKeys.loginType);

      final loginTypes = {
        LoginType.x: 'Logged in with X platform',
        LoginType.facebook: 'Logged in with Facebook',
        LoginType.linkedin: 'Logged in with LinkedIn',
        LoginType.apple: 'Logged in with Apple',
        LoginType.github: 'Logged in with Github'
      };

      if (loginTypes.containsKey(loginType)) {
        identifier = loginTypes[loginType]!;
      }

      String avatar = myUser.image ?? '';
      if (avatar == defaultAvatar) {
        avatar = avatarPlaceHolder(myUser.name);
      }

      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          children: [
            _AvatarRing(
              child: Hero(
                tag: 'profile_avatar_${myUser.uuid}',
                child: Img(
                  src: avatar,
                  size: 96,
                  alt: myUser.name,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              myUser.name ?? '',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.pageTitle.copyWith(fontSize: 24),
            ),
            if (identifier.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                identifier,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.muted,
              ),
            ],
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Material(
                color: AppColors.fill,
                shape: StadiumBorder(
                  side: BorderSide(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: myUser.uuid));
                    Toast.neutral(
                      title: 'Copied',
                      message: 'ID copied to clipboard',
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('ID', style: AppText.label),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            myUser.uuid,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.caption,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.copy_rounded,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
