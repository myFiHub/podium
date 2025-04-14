import 'package:podium/utils/loginType.dart';
import 'package:web3auth_flutter/enums.dart';

String web3AuthProviderToLoginTypeString(Provider provider) {
  switch (provider) {
    case Provider.email_passwordless:
      return LoginType.email;
    case Provider.google:
      return LoginType.google;
    case Provider.apple:
      return LoginType.apple;
    case Provider.github:
      return LoginType.github;
    case Provider.twitter:
      return LoginType.x;
    case Provider.facebook:
      return LoginType.facebook;
    case Provider.linkedin:
      return LoginType.linkedin;
    default:
      return LoginType.x;
  }
}

Provider loginTypeStringToWeb3AuthProvider(String loginType) {
  switch (loginType) {
    case LoginType.google:
      return Provider.google;
    case LoginType.apple:
      return Provider.apple;
    case LoginType.github:
      return Provider.github;
    case LoginType.x:
      return Provider.twitter;
    case LoginType.facebook:
      return Provider.facebook;
    case LoginType.linkedin:
      return Provider.linkedin;
    case LoginType.email:
      return Provider.email_passwordless;
    case 'email_passwordless':
      return Provider.email_passwordless;
    case 'twitter':
      return Provider.twitter;
    default:
      return Provider.google;
  }
}
