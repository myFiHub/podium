import 'package:get_storage/get_storage.dart';
import 'package:podium/utils/storage.dart';

class LoginType {
  static const String email = 'email';
  static const String x = 'x';
  static const String google = 'google';
  static const String facebook = 'facebook';
  static const String linkedin = 'linkedin';
  static const String apple = 'apple';
  static const String github = 'github';
}

class LoginTypeDisplayName {
  static const String x = 'X (Twitter)';
  static const String apple = 'Apple';
  static const String google = 'Google';
  static const String email = 'Email';
  static const String facebook = 'Facebook';
  static const String linkedin = 'LinkedIn';
  static const String github = 'GitHub';
}

String loginTypeToDisplayName(String loginType) {
  switch (loginType) {
    case LoginType.x:
      return LoginTypeDisplayName.x;
    case LoginType.apple:
      return LoginTypeDisplayName.apple;
    case LoginType.google:
      return LoginTypeDisplayName.google;
    case LoginType.email:
      return LoginTypeDisplayName.email;
    case LoginType.facebook:
      return LoginTypeDisplayName.facebook;
    case LoginType.linkedin:
      return LoginTypeDisplayName.linkedin;
    case LoginType.github:
      return LoginTypeDisplayName.github;
    default:
      return loginType;
  }
}

class LoginTypeService {
  static final _storage = GetStorage();
  static setLoginType(String loginType) {
    _storage.write(StorageKeys.loginType, loginType);
  }

  static String? getLoginType() {
    final savedLoginType = _storage.read<String>(StorageKeys.loginType);
    if (savedLoginType == null || savedLoginType == '') {
      return null;
    }
    return savedLoginType;
  }
}
