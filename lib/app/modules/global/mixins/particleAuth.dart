import 'package:particle_auth/particle_auth.dart';
import 'package:particle_auth/model/user_info.dart' as ParticleUser;

List<SupportAuthType> supportAuthType = <SupportAuthType>[
  SupportAuthType.email,
  SupportAuthType.twitter,
  SupportAuthType.google,
  SupportAuthType.facebook,
  SupportAuthType.github,
  SupportAuthType.linkedin,
  SupportAuthType.microsoft,
  SupportAuthType.twitch,
  SupportAuthType.discord,
  SupportAuthType.apple,
  SupportAuthType.phone,
];
mixin ParticleAuthUtils {
  Future<ParticleUser.UserInfo?> particleLogin(String email) async {
    try {
      final userInfo = await ParticleAuth.login(
        LoginType.email,
        email,
        supportAuthType,
      );
      return userInfo;
    } catch (e) {
      return null;
    }
  }
}
