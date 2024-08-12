import 'package:get_storage/get_storage.dart';
import 'package:podium/utils/storage.dart';

class LoginType {
  static const String emailAndPassword = 'emailAndPassword';
  static const String x = 'x';
  static const String google = 'google';
  static const String facebook = 'facebook';
  static const String linkedin = 'linkedin';
  static const String apple = 'apple';
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
