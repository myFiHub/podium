import 'package:particle_auth_core/particle_auth_core.dart';
import 'package:particle_base/model/user_info.dart' as ParticleUser;
import 'package:particle_base/model/login_info.dart' as PLoginInfo;

List<PLoginInfo.SupportAuthType> _supportAuthType =
    <PLoginInfo.SupportAuthType>[
  PLoginInfo.SupportAuthType.email,
  PLoginInfo.SupportAuthType.twitter,
  PLoginInfo.SupportAuthType.google,
  PLoginInfo.SupportAuthType.facebook,
  PLoginInfo.SupportAuthType.github,
  PLoginInfo.SupportAuthType.linkedin,
  PLoginInfo.SupportAuthType.microsoft,
  PLoginInfo.SupportAuthType.twitch,
  PLoginInfo.SupportAuthType.discord,
  PLoginInfo.SupportAuthType.apple,
  PLoginInfo.SupportAuthType.phone,
];
mixin ParticleAuthUtils {
  Future<ParticleUser.UserInfo?> particleLogin(String email) async {
    try {
      final userInfo = await ParticleAuthCore.connect(
        PLoginInfo.LoginType.email,
        account: email,
      );
      return userInfo;
    } catch (e) {
      return null;
    }
  }

  Future<ParticleUser.UserInfo?> particleSocialLogin(
      {required PLoginInfo.LoginType type, String? email}) async {
    try {
      final isAlreadyLoggedIn = await ParticleAuthCore.isConnected();
      if (isAlreadyLoggedIn) {
        return await ParticleAuthCore.getUserInfo();
      }
      final userInfo = await ParticleAuthCore.connect(
        type,
        account: email,
      );
      return userInfo;
    } catch (e) {
      return null;
    }
  }
}
