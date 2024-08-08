import 'package:particle_auth_core/particle_auth_core.dart';
import 'package:particle_base/model/user_info.dart' as ParticleUser;
import 'package:particle_base/model/login_info.dart' as LoginInfo;

List<LoginInfo.SupportAuthType> _supportAuthType = <LoginInfo.SupportAuthType>[
  LoginInfo.SupportAuthType.email,
  LoginInfo.SupportAuthType.twitter,
  LoginInfo.SupportAuthType.google,
  LoginInfo.SupportAuthType.facebook,
  LoginInfo.SupportAuthType.github,
  LoginInfo.SupportAuthType.linkedin,
  LoginInfo.SupportAuthType.microsoft,
  LoginInfo.SupportAuthType.twitch,
  LoginInfo.SupportAuthType.discord,
  LoginInfo.SupportAuthType.apple,
  LoginInfo.SupportAuthType.phone,
];
mixin ParticleAuthUtils {
  Future<ParticleUser.UserInfo?> particleLogin(String email) async {
    try {
      final userInfo = await ParticleAuthCore.connect(
        LoginInfo.LoginType.email,
        account: email,
      );
      return userInfo;
    } catch (e) {
      return null;
    }
  }

  Future<ParticleUser.UserInfo?> particleLoginWithX() async {
    try {
      final userInfo = await ParticleAuthCore.connect(
        LoginInfo.LoginType.twitter,
      );
      return userInfo;
    } catch (e) {
      return null;
    }
  }
}
